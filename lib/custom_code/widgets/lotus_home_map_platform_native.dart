import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'event_pin_diff.dart';

const _mapboxAccessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
bool get isLotusHomeMapSupported => Platform.isAndroid || Platform.isIOS;

Widget buildLotusHomeMap({
  required List<Event> events,
  required ValueChanged<String> onEventTap,
  required GeoCoordinates? userCoordinates,
  required int centerOnUserRequest,
}) {
  if (!isLotusHomeMapSupported) {
    return const _UnsupportedMapView();
  }

  if (!_mapboxAccessToken.startsWith('pk.')) {
    return const _MissingTokenView();
  }

  return _NativeLotusHomeMap(
    events: events,
    onEventTap: onEventTap,
    userCoordinates: userCoordinates,
    centerOnUserRequest: centerOnUserRequest,
  );
}

class _NativeLotusHomeMap extends StatefulWidget {
  const _NativeLotusHomeMap({
    required this.events,
    required this.onEventTap,
    required this.userCoordinates,
    required this.centerOnUserRequest,
  });

  final List<Event> events;
  final ValueChanged<String> onEventTap;
  final GeoCoordinates? userCoordinates;
  final int centerOnUserRequest;

  @override
  State<_NativeLotusHomeMap> createState() => _NativeLotusHomeMapState();
}

class _NativeLotusHomeMapState extends State<_NativeLotusHomeMap>
    with WidgetsBindingObserver {
  static final Point _portoCenter = Point(
    coordinates: Position(-8.61099, 41.14961),
  );

  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pinManager;
  Cancelable? _pinTapEvents;
  final Map<String, PointAnnotation> _annotationsByEventId = {};
  Map<String, EventPin> _renderedPins = const {};
  Future<Uint8List>? _regularPinImage;
  Future<Uint8List>? _featuredPinImage;
  bool _isForeground = true;
  bool _isSyncingPins = false;
  int _pinSyncVersion = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Resource options must be configured before the native map is created.
    MapboxOptions.setAccessToken(_mapboxAccessToken);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (_isForeground) {
      _applyDarkStyle();
    }
  }

  @override
  void didUpdateWidget(_NativeLotusHomeMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.events, widget.events)) {
      _requestPinSync();
    }
    if (oldWidget.userCoordinates != widget.userCoordinates) {
      _updateUserLocationSettings();
    }
    if (oldWidget.centerOnUserRequest != widget.centerOnUserRequest) {
      _centerOnUser();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinTapEvents?.cancel();
    _pinTapEvents = null;
    _pinManager = null;
    _annotationsByEventId.clear();
    _renderedPins = const {};
    // MapWidget owns and disposes the native MapboxMap controller.
    _mapboxMap = null;
    super.dispose();
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _applyDarkStyle();
    await _updateUserLocationSettings();
    if (widget.centerOnUserRequest > 0) {
      await _centerOnUser();
    }

    final manager = await mapboxMap.annotations.createPointAnnotationManager(
      id: 'lotus-event-pins',
    );
    if (!mounted || _mapboxMap != mapboxMap) {
      return;
    }

    _pinManager = manager;
    _pinTapEvents = manager.tapEvents(onTap: _onPinTap);
    _requestPinSync();
  }

  void _onPinTap(PointAnnotation annotation) {
    final eventId = annotation.customData?['eventId'];
    if (eventId is String) {
      widget.onEventTap(eventId);
    }
  }

  void _requestPinSync() {
    _pinSyncVersion += 1;
    if (!_isSyncingPins && _pinManager != null) {
      _drainPinSyncQueue();
    }
  }

  Future<void> _drainPinSyncQueue() async {
    _isSyncingPins = true;
    try {
      while (mounted && _pinManager != null) {
        final version = _pinSyncVersion;
        await _syncPins();
        if (version == _pinSyncVersion) {
          break;
        }
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'lotus event map',
          context: ErrorDescription('while synchronizing event pins'),
        ),
      );
    } finally {
      _isSyncingPins = false;
    }
  }

  Future<void> _syncPins() async {
    final manager = _pinManager;
    if (manager == null) {
      return;
    }

    final changes = diffEventPins(
      previous: _renderedPins,
      events: widget.events,
    );

    final annotationsToRemove = changes.removedEventIds
        .map(_annotationsByEventId.remove)
        .whereType<PointAnnotation>()
        .toList(growable: false);
    if (annotationsToRemove.isNotEmpty) {
      await manager.deleteMulti(annotationsToRemove);
    }

    await Future.wait(
      changes.updated.map((pin) async {
        final annotation = _annotationsByEventId[pin.eventId];
        if (annotation == null) {
          return;
        }
        annotation
          ..geometry = _pointFor(pin)
          ..image = await _pinImage(pin.isFeatured)
          ..iconSize = pin.isFeatured ? 0.62 : 0.55
          ..symbolSortKey = pin.isFeatured ? 0 : 1;
        await manager.update(annotation);
      }),
    );

    if (changes.added.isNotEmpty) {
      final options = await Future.wait(changes.added.map(_optionsForPin));
      final annotations = await manager.createMulti(options);
      for (var index = 0; index < changes.added.length; index += 1) {
        final annotation = annotations[index];
        if (annotation != null) {
          _annotationsByEventId[changes.added[index].eventId] = annotation;
        }
      }
    }

    _renderedPins = changes.current;
  }

  Future<PointAnnotationOptions> _optionsForPin(EventPin pin) async {
    return PointAnnotationOptions(
      geometry: _pointFor(pin),
      image: await _pinImage(pin.isFeatured),
      iconAnchor: IconAnchor.BOTTOM,
      iconSize: pin.isFeatured ? 0.62 : 0.55,
      symbolSortKey: pin.isFeatured ? 0 : 1,
      customData: {'eventId': pin.eventId},
    );
  }

  Point _pointFor(EventPin pin) =>
      Point(coordinates: Position(pin.longitude, pin.latitude));

  Future<Uint8List> _pinImage(bool isFeatured) {
    if (isFeatured) {
      return _featuredPinImage ??= _renderPinImage(isFeatured: true);
    }
    return _regularPinImage ??= _renderPinImage(isFeatured: false);
  }

  Future<void> _applyDarkStyle() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null || !_isForeground) {
      return;
    }

    await mapboxMap.style.setStyleImportConfigProperty(
      'basemap',
      'lightPreset',
      'night',
    );
  }

  Future<void> _updateUserLocationSettings() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }
    final enabled = widget.userCoordinates != null;
    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: enabled,
        pulsingEnabled: enabled,
        pulsingColor: 0xFFB7F34A,
        showAccuracyRing: enabled,
        puckBearingEnabled: enabled,
        puckBearing: PuckBearing.HEADING,
      ),
    );
  }

  Future<void> _centerOnUser() async {
    final mapboxMap = _mapboxMap;
    final coordinates = widget.userCoordinates;
    if (mapboxMap == null || coordinates == null) {
      return;
    }
    await mapboxMap.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(coordinates.longitude, coordinates.latitude),
        ),
        zoom: 15.5,
        bearing: 0,
        pitch: 0,
      ),
      MapAnimationOptions(duration: 900, startDelay: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey('lotus-home-map'),
      styleUri: MapboxStyles.STANDARD,
      viewport: CameraViewportState(
        center: _portoCenter,
        zoom: 12.5,
        bearing: 0,
        pitch: 0,
      ),
      textureView: true,
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: (_) => _applyDarkStyle(),
    );
  }
}

Future<Uint8List> _renderPinImage({required bool isFeatured}) async {
  const width = 88.0;
  const height = 104.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final path = Path()
    ..moveTo(width / 2, height - 6)
    ..cubicTo(34, 82, 14, 62, 14, 38)
    ..cubicTo(14, 18, 27, 6, width / 2, 6)
    ..cubicTo(61, 6, 74, 18, 74, 38)
    ..cubicTo(74, 62, 54, 82, width / 2, height - 6)
    ..close();

  canvas.drawShadow(path, const Color(0xAA000000), 8, true);
  canvas.drawPath(
    path,
    Paint()
      ..color = isFeatured ? const Color(0xFFFF6B5E) : const Color(0xFFB7F34A),
  );
  canvas.drawCircle(
    const Offset(width / 2, 38),
    15,
    Paint()..color = const Color(0xFF11161D),
  );
  canvas.drawCircle(
    const Offset(width / 2, 38),
    6,
    Paint()..color = const Color(0xFFFFFFFF),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), height.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  if (bytes == null) {
    throw StateError('Could not render the event pin image.');
  }
  return bytes.buffer.asUint8List();
}

class _MissingTokenView extends StatelessWidget {
  const _MissingTokenView();

  @override
  Widget build(BuildContext context) {
    return const _MapMessageView(
      icon: Icons.key_off_outlined,
      title: 'Mapbox por configurar',
      message: 'Inicia a aplicação com MAPBOX_ACCESS_TOKEN definido.',
    );
  }
}

class _UnsupportedMapView extends StatelessWidget {
  const _UnsupportedMapView();

  @override
  Widget build(BuildContext context) {
    return const _MapMessageView(
      icon: Icons.phone_android_outlined,
      title: 'Mapa disponível em mobile',
      message: 'A Home Mapbox é suportada em iOS e Android.',
    );
  }
}

class _MapMessageView extends StatelessWidget {
  const _MapMessageView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF080B10),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF76869A), size: 36),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB6C2D1)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
