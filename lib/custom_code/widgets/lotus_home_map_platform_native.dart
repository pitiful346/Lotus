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
const _pinImagePrefix = 'lotus-event-pin';
const _pinCanvasSize = 64;
const _initialZoom = 14.0;
const _explorationPitch = 44.0;
const _eventPreviewCameraPadding = 300.0;
final Map<String, Uint8List> _pinImageCache = {};
bool get isLotusHomeMapSupported => Platform.isAndroid || Platform.isIOS;

Widget buildLotusHomeMap({
  required List<Event> events,
  required ValueChanged<String> onEventTap,
  required VoidCallback onMapTapEmpty,
  required ValueChanged<MapViewportBounds> onViewportChanged,
  required VoidCallback onUserMapGesture,
  required String? selectedEventId,
  required GeoCoordinates? userCoordinates,
  required int centerOnUserRequest,
  required GeoCoordinates initialCenter,
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
    onMapTapEmpty: onMapTapEmpty,
    onViewportChanged: onViewportChanged,
    onUserMapGesture: onUserMapGesture,
    selectedEventId: selectedEventId,
    userCoordinates: userCoordinates,
    centerOnUserRequest: centerOnUserRequest,
    initialCenter: initialCenter,
  );
}

class _NativeLotusHomeMap extends StatefulWidget {
  const _NativeLotusHomeMap({
    required this.events,
    required this.onEventTap,
    required this.onMapTapEmpty,
    required this.onViewportChanged,
    required this.onUserMapGesture,
    required this.selectedEventId,
    required this.userCoordinates,
    required this.centerOnUserRequest,
    required this.initialCenter,
  });

  final List<Event> events;
  final ValueChanged<String> onEventTap;
  final VoidCallback onMapTapEmpty;
  final ValueChanged<MapViewportBounds> onViewportChanged;
  final VoidCallback onUserMapGesture;
  final String? selectedEventId;
  final GeoCoordinates? userCoordinates;
  final int centerOnUserRequest;
  final GeoCoordinates initialCenter;

  @override
  State<_NativeLotusHomeMap> createState() => _NativeLotusHomeMapState();
}

class _NativeLotusHomeMapState extends State<_NativeLotusHomeMap>
    with WidgetsBindingObserver {
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
    if (oldWidget.selectedEventId != widget.selectedEventId) {
      _requestEventSync();
      if (widget.selectedEventId == null) {
        _clearEventPreviewPadding();
      } else {
        _focusSelectedEvent();
      }
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
      await source.updateGeoJSON(
        _eventFeatureCollection(widget.events, widget.selectedEventId),
      );
    }
  }

  Future<void> _onStyleLoaded() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) {
      return;
    }
    _isStyleReady = false;
    await _applyDarkStyle();

    await _addPinImages(mapboxMap);

    if (!await mapboxMap.style.styleSourceExists(_eventSourceId)) {
      await mapboxMap.style.addSource(
        GeoJsonSource(
          id: _eventSourceId,
          data: _eventFeatureCollection(widget.events, widget.selectedEventId),
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
    await _reportViewport();
  }

  Future<void> _addPinImages(MapboxMap mapboxMap) async {
    for (final category in _LotusPinCategory.values) {
      for (final selected in const [false, true]) {
        final id = _pinImageId(category, selected: selected);
        if (await mapboxMap.style.hasStyleImage(id)) {
          continue;
        }
        final bytes = _pinImageCache[id] ??= await _renderPinImage(
          category: category,
          selected: selected,
        );
        await mapboxMap.style.addStyleImage(
          id,
          1,
          MbxImage(width: _pinCanvasSize, height: _pinCanvasSize, data: bytes),
          false,
          const [],
          const [],
          null,
        );
      }
    }
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
      widget.onMapTapEmpty();
      return;
    }

    if (result.layers.contains(_clusterLayerId)) {
      widget.onMapTapEmpty();
      final camera = await mapboxMap.getCameraState();
      await mapboxMap.easeTo(
        CameraOptions(
          center: context.point,
          zoom: (camera.zoom + 2).clamp(0, 16).toDouble(),
          bearing: camera.bearing,
          pitch: camera.pitch,
          padding: camera.padding,
        ),
        MapAnimationOptions(duration: 500, startDelay: 0),
      );
      await Future<void>.delayed(const Duration(milliseconds: 520));
      await _reportViewport();
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

    await mapboxMap.style.setStyleImportConfigProperties('basemap', {
      'lightPreset': 'night',
      'show3dObjects': true,
      'show3dBuildings': true,
      'show3dLandmarks': true,
      'show3dTrees': true,
      'show3dFacades': true,
      'showPointOfInterestLabels': false,
    });
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
    final camera = await mapboxMap.getCameraState();
    await mapboxMap.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(coordinates.longitude, coordinates.latitude),
        ),
        zoom: 15.5,
        bearing: camera.bearing,
        pitch: camera.pitch,
        padding: MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
      ),
      MapAnimationOptions(duration: 900, startDelay: 0),
    );
    await Future<void>.delayed(const Duration(milliseconds: 920));
    if (!mounted || _mapboxMap != mapboxMap) return;
    await _reportViewport();
  }

  void _onUserCameraGesture(MapContentGestureContext context) {
    widget.onUserMapGesture();
    if (context.gestureState == GestureState.ended) {
      _reportViewport();
    }
  }

  Future<void> _focusSelectedEvent() async {
    final mapboxMap = _mapboxMap;
    final eventId = widget.selectedEventId;
    if (mapboxMap == null || eventId == null) return;
    Event? selectedEvent;
    for (final event in widget.events) {
      if (event.id == eventId) {
        selectedEvent = event;
        break;
      }
    }
    final coordinates = selectedEvent?.location.coordinates;
    if (coordinates == null) return;
    final camera = await mapboxMap.getCameraState();
    final targetZoom = camera.zoom < 14.25 ? 14.25 : camera.zoom;
    await mapboxMap.easeTo(
      CameraOptions(
        center: Point(
          coordinates: Position(coordinates.longitude, coordinates.latitude),
        ),
        zoom: targetZoom.clamp(0, 16).toDouble(),
        bearing: camera.bearing,
        pitch: camera.pitch,
        padding: MbxEdgeInsets(
          top: 0,
          left: 0,
          bottom: _eventPreviewCameraPadding,
          right: 0,
        ),
      ),
      MapAnimationOptions(duration: 550, startDelay: 0),
    );
  }

  Future<void> _clearEventPreviewPadding() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    final camera = await mapboxMap.getCameraState();
    await mapboxMap.easeTo(
      CameraOptions(
        center: camera.center,
        zoom: camera.zoom,
        bearing: camera.bearing,
        pitch: camera.pitch,
        padding: MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
      ),
      MapAnimationOptions(duration: 220, startDelay: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      key: const ValueKey('lotus-home-map'),
      styleUri: MapboxStyles.STANDARD,
      viewport: CameraViewportState(
        center: Point(
          coordinates: Position(
            widget.initialCenter.longitude,
            widget.initialCenter.latitude,
          ),
        ),
        zoom: _initialZoom,
        bearing: 0,
        pitch: _explorationPitch,
      ),
      textureView: true,
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: (_) => _onStyleLoaded(),
      onMapIdleListener: (_) => _reportViewport(),
      onScrollListener: _onUserCameraGesture,
      onZoomListener: _onUserCameraGesture,
      // The SDK keeps this callback for compatibility while typed layer
      // interactions mature; querying only Lotus layers keeps the hit test
      // narrow and deterministic.
      // ignore: deprecated_member_use
      onTapListener: _onMapTap,
    );
  }
}

String _eventFeatureCollection(List<Event> events, String? selectedEventId) {
  return jsonEncode({
    'type': 'FeatureCollection',
    'features': [
      for (final event in events)
        if (event.location.coordinates case final coordinates?)
          {
            'type': 'Feature',
            'properties': {
              'eventId': event.id,
              'selected': event.id == selectedEventId,
              'pinImage': _pinImageId(
                _pinCategory(event),
                selected: event.id == selectedEventId,
              ),
            },
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
    'icon-image': ['get', 'pinImage'],
    'icon-anchor': 'center',
    'icon-size': [
      'case',
      [
        '==',
        ['get', 'selected'],
        true,
      ],
      0.80,
      0.68,
    ],
    'icon-allow-overlap': true,
  },
};

enum _LotusPinCategory {
  music,
  theatre,
  party,
  sport,
  culture,
  food,
  workshop,
  comedy,
  other,
}

_LotusPinCategory _pinCategory(Event event) {
  for (final rawCategory in event.categoryIds) {
    final category = rawCategory.trim().toLowerCase();
    if (category.contains('music')) return _LotusPinCategory.music;
    if (category.contains('teatr')) return _LotusPinCategory.theatre;
    if (category.contains('fest') || category.contains('party')) {
      return _LotusPinCategory.party;
    }
    if (category.contains('desport') || category.contains('sport')) {
      return _LotusPinCategory.sport;
    }
    if (category.contains('cultur') || category.contains('cinema')) {
      return _LotusPinCategory.culture;
    }
    if (category.contains('gastr') || category.contains('food')) {
      return _LotusPinCategory.food;
    }
    if (category.contains('workshop') || category.contains('oficina')) {
      return _LotusPinCategory.workshop;
    }
    if (category.contains('comed')) return _LotusPinCategory.comedy;
  }
  return _LotusPinCategory.other;
}

String _pinImageId(_LotusPinCategory category, {required bool selected}) =>
    '$_pinImagePrefix-${category.name}${selected ? '-selected' : ''}';

IconData _pinIcon(_LotusPinCategory category) => switch (category) {
  _LotusPinCategory.music => Icons.music_note,
  _LotusPinCategory.theatre => Icons.theater_comedy,
  _LotusPinCategory.party => Icons.bolt,
  _LotusPinCategory.sport => Icons.sports_soccer,
  _LotusPinCategory.culture => Icons.account_balance,
  _LotusPinCategory.food => Icons.restaurant,
  _LotusPinCategory.workshop => Icons.build,
  _LotusPinCategory.comedy => Icons.sentiment_satisfied,
  _LotusPinCategory.other => Icons.local_activity,
};

Future<Uint8List> _renderPinImage({
  required _LotusPinCategory category,
  required bool selected,
}) async {
  const size = 64.0;
  const center = Offset(size / 2, size / 2);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (selected) {
    canvas.drawCircle(center, 27, Paint()..color = const Color(0x3DB7F34A));
  }
  canvas.drawCircle(
    center.translate(0, 2),
    21,
    Paint()
      ..color = const Color(0x73000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  canvas.drawCircle(
    center,
    selected ? 22.5 : 21,
    Paint()
      ..color = selected ? const Color(0xFFF7FAFC) : const Color(0xFF11161D),
  );
  canvas.drawCircle(
    center,
    selected ? 19.5 : 18,
    Paint()..color = const Color(0xFFB7F34A),
  );

  final icon = _pinIcon(category);
  final iconPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        color: const Color(0xFF11161D),
        fontSize: selected ? 20 : 18,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  iconPainter.paint(
    canvas,
    Offset(
      center.dx - iconPainter.width / 2,
      center.dy - iconPainter.height / 2,
    ),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(_pinCanvasSize, _pinCanvasSize);
  // The native Mapbox bridges decode this payload as an encoded platform
  // image (UIImage/Bitmap), so provide PNG bytes rather than Flutter's raw
  // pixel buffer.
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
