import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

const _mapboxAccessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
const _eventSourceId = 'lotus-events';
const _clusterLayerId = 'lotus-event-clusters';
const _clusterCountLayerId = 'lotus-event-cluster-count';
const _eventLayerId = 'lotus-event-pins';
const _regularPinImageId = 'lotus-event-pin';
const _featuredPinImageId = 'lotus-featured-event-pin';
const _pinWidth = 88;
const _pinHeight = 104;
bool get isLotusHomeMapSupported => Platform.isAndroid || Platform.isIOS;

Widget buildLotusHomeMap({
  required List<Event> events,
  required ValueChanged<String> onEventTap,
  required ValueChanged<MapViewportBounds> onViewportChanged,
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
    onViewportChanged: onViewportChanged,
    userCoordinates: userCoordinates,
    centerOnUserRequest: centerOnUserRequest,
  );
}

class _NativeLotusHomeMap extends StatefulWidget {
  const _NativeLotusHomeMap({
    required this.events,
    required this.onEventTap,
    required this.onViewportChanged,
    required this.userCoordinates,
    required this.centerOnUserRequest,
  });

  final List<Event> events;
  final ValueChanged<String> onEventTap;
  final ValueChanged<MapViewportBounds> onViewportChanged;
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
  bool _isForeground = true;
  bool _isStyleReady = false;
  bool _isSyncingEvents = false;
  bool _isReportingViewport = false;
  int _eventSyncVersion = 0;

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
      _requestEventSync();
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
  }

  void _requestEventSync() {
    _eventSyncVersion += 1;
    if (!_isSyncingEvents && _isStyleReady) {
      _drainEventSyncQueue();
    }
  }

  Future<void> _drainEventSyncQueue() async {
    _isSyncingEvents = true;
    try {
      while (mounted && _isStyleReady) {
        final version = _eventSyncVersion;
        await _syncEventSource();
        if (version == _eventSyncVersion) {
          break;
        }
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'lotus event map',
          context: ErrorDescription('while synchronizing clustered events'),
        ),
      );
    } finally {
      _isSyncingEvents = false;
    }
  }

  Future<void> _syncEventSource() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null || !_isStyleReady) {
      return;
    }
    final source = await mapboxMap.style.getSource(_eventSourceId);
    if (source is GeoJsonSource) {
      await source.updateGeoJSON(_eventFeatureCollection(widget.events));
    }
  }

  Future<void> _onStyleLoaded() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }
    _isStyleReady = false;
    await _applyDarkStyle();

    await _addPinImage(mapboxMap, id: _regularPinImageId, isFeatured: false);
    await _addPinImage(mapboxMap, id: _featuredPinImageId, isFeatured: true);

    if (!await mapboxMap.style.styleSourceExists(_eventSourceId)) {
      await mapboxMap.style.addSource(
        GeoJsonSource(
          id: _eventSourceId,
          data: _eventFeatureCollection(widget.events),
          cluster: true,
          clusterRadius: 52,
          clusterMaxZoom: 14,
          clusterMinPoints: 3,
        ),
      );
    }
    await _addLayerIfMissing(mapboxMap, _clusterLayer());
    await _addLayerIfMissing(mapboxMap, _clusterCountLayer());
    await _addLayerIfMissing(mapboxMap, _unclusteredEventLayer());

    if (!mounted || _mapboxMap != mapboxMap) {
      return;
    }
    _isStyleReady = true;
    _requestEventSync();
  }

  Future<void> _addPinImage(
    MapboxMap mapboxMap, {
    required String id,
    required bool isFeatured,
  }) async {
    if (await mapboxMap.style.hasStyleImage(id)) {
      return;
    }
    await mapboxMap.style.addStyleImage(
      id,
      1,
      MbxImage(
        width: _pinWidth,
        height: _pinHeight,
        data: await _renderPinImage(isFeatured: isFeatured),
      ),
      false,
      const [],
      const [],
      null,
    );
  }

  Future<void> _addLayerIfMissing(
    MapboxMap mapboxMap,
    Map<String, Object> layer,
  ) async {
    final id = layer['id']! as String;
    if (!await mapboxMap.style.styleLayerExists(id)) {
      await mapboxMap.style.addStyleLayer(jsonEncode(layer), null);
    }
  }

  Future<void> _onMapTap(MapContentGestureContext context) async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null || !_isStyleReady) {
      return;
    }
    final features = await mapboxMap.queryRenderedFeatures(
      RenderedQueryGeometry.fromScreenCoordinate(context.touchPosition),
      RenderedQueryOptions(
        layerIds: const [_clusterLayerId, _eventLayerId],
        filter: null,
      ),
    );
    QueriedRenderedFeature? result;
    for (final feature in features) {
      if (feature != null) {
        result = feature;
        break;
      }
    }
    if (result == null) {
      return;
    }

    if (result.layers.contains(_clusterLayerId)) {
      final camera = await mapboxMap.getCameraState();
      await mapboxMap.easeTo(
        CameraOptions(
          center: context.point,
          zoom: (camera.zoom + 2).clamp(0, 16).toDouble(),
        ),
        MapAnimationOptions(duration: 500, startDelay: 0),
      );
      return;
    }

    final properties = result.queriedFeature.feature['properties'];
    if (properties is Map) {
      final eventId = properties['eventId'];
      if (eventId is String) {
        widget.onEventTap(eventId);
      }
    }
  }

  Future<void> _reportViewport() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null || _isReportingViewport) {
      return;
    }
    _isReportingViewport = true;
    try {
      final camera = await mapboxMap.getCameraState();
      final bounds = await mapboxMap.coordinateBoundsForCamera(
        CameraOptions(
          center: camera.center,
          padding: camera.padding,
          zoom: camera.zoom,
          bearing: camera.bearing,
          pitch: camera.pitch,
        ),
      );
      if (!mounted || bounds.infiniteBounds) {
        return;
      }
      widget.onViewportChanged(
        MapViewportBounds(
          south: bounds.southwest.coordinates.lat.toDouble(),
          west: bounds.southwest.coordinates.lng.toDouble(),
          north: bounds.northeast.coordinates.lat.toDouble(),
          east: bounds.northeast.coordinates.lng.toDouble(),
        ),
      );
    } finally {
      _isReportingViewport = false;
    }
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
      onStyleLoadedListener: (_) => _onStyleLoaded(),
      onMapIdleListener: (_) => _reportViewport(),
      // The SDK keeps this callback for compatibility while typed layer
      // interactions mature; querying only Lotus layers keeps the hit test
      // narrow and deterministic.
      // ignore: deprecated_member_use
      onTapListener: _onMapTap,
    );
  }
}

String _eventFeatureCollection(List<Event> events) {
  return jsonEncode({
    'type': 'FeatureCollection',
    'features': [
      for (final event in events)
        if (event.location.coordinates case final coordinates?)
          {
            'type': 'Feature',
            'properties': {'eventId': event.id, 'featured': event.isFeatured},
            'geometry': {
              'type': 'Point',
              'coordinates': [coordinates.longitude, coordinates.latitude],
            },
          },
    ],
  });
}

Map<String, Object> _clusterLayer() => {
  'id': _clusterLayerId,
  'type': 'circle',
  'source': _eventSourceId,
  'filter': ['has', 'point_count'],
  'paint': {
    'circle-color': '#B7F34A',
    'circle-radius': [
      'step',
      ['get', 'point_count'],
      19,
      10,
      24,
      40,
      30,
    ],
    'circle-stroke-width': 3,
    'circle-stroke-color': '#11161D',
  },
};

Map<String, Object> _clusterCountLayer() => {
  'id': _clusterCountLayerId,
  'type': 'symbol',
  'source': _eventSourceId,
  'filter': ['has', 'point_count'],
  'layout': {
    'text-field': ['get', 'point_count_abbreviated'],
    'text-size': 12,
  },
  'paint': {'text-color': '#11161D'},
};

Map<String, Object> _unclusteredEventLayer() => {
  'id': _eventLayerId,
  'type': 'symbol',
  'source': _eventSourceId,
  'filter': [
    '!',
    ['has', 'point_count'],
  ],
  'layout': {
    'icon-image': [
      'case',
      [
        '==',
        ['get', 'featured'],
        true,
      ],
      _featuredPinImageId,
      _regularPinImageId,
    ],
    'icon-anchor': 'bottom',
    'icon-size': [
      'case',
      [
        '==',
        ['get', 'featured'],
        true,
      ],
      0.62,
      0.55,
    ],
    'icon-allow-overlap': true,
  },
};

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
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
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
