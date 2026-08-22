import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

const _mapboxAccessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
const _eventSourceId = 'lotus-events';
const _clusterLayerId = 'lotus-event-clusters';
const _clusterCountLayerId = 'lotus-event-cluster-count';
const _eventLayerId = 'lotus-event-posters';
const _pixelWidth = 112;
const _pixelHeight = 148;
const _initialZoom = 14.0;
const _explorationPitch = 44.0;
const _eventPreviewCameraPadding = 300.0;

final Map<String, Uint8List> _posterImageCache = {};
final Map<String, ui.Image> _decodedImageCache = {};

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
  ValueChanged<List<String>>? onStackedEventsTap,
  ValueChanged<GeoCoordinates>? onClusterTapArea,
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
    onStackedEventsTap: onStackedEventsTap,
    onClusterTapArea: onClusterTapArea,
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
    this.onStackedEventsTap,
    this.onClusterTapArea,
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
  final ValueChanged<List<String>>? onStackedEventsTap;
  final ValueChanged<GeoCoordinates>? onClusterTapArea;

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
  late final CameraViewportState _initialViewport;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MapboxOptions.setAccessToken(_mapboxAccessToken);
    _initialViewport = CameraViewportState(
      center: Point(
        coordinates: Position(
          widget.initialCenter.longitude,
          widget.initialCenter.latitude,
        ),
      ),
      zoom: _initialZoom,
      bearing: 0,
      pitch: _explorationPitch,
    );
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
    _mapboxMap = null;
    super.dispose();
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await mapboxMap.setBounds(
      CameraBoundsOptions(
        minZoom: 1.0,
        maxZoom: 22.0,
        minPitch: 0.0,
        maxPitch: 70.0,
      ),
    );
    await mapboxMap.gestures.updateSettings(
      GesturesSettings(
        pinchToZoomEnabled: true,
        doubleTapToZoomInEnabled: true,
        doubleTouchToZoomOutEnabled: true,
        quickZoomEnabled: true,
        pitchEnabled: true,
        rotateEnabled: true,
        scrollEnabled: true,
        pinchToZoomDecelerationEnabled: true,
        increasePinchToZoomThresholdWhenRotating: false,
      ),
    );
    await _applyDarkStyle();
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
          library: 'lotus poster map',
          context: ErrorDescription('while synchronizing poster markers'),
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

    final groups = groupLotusEventsByProximity(widget.events);

    // Pre-cache and add poster images to map style
    for (final group in groups) {
      final events = group.events;
      final isSelected = events.any((e) => e.id == widget.selectedEventId);
      final isFeatured = events.any((e) => e.isFeatured);
      final primaryEvent = isSelected
          ? events.firstWhere((e) => e.id == widget.selectedEventId)
          : (events.firstWhere((e) => e.isFeatured, orElse: () => events.first));

      final imageId = buildLotusPosterImageId(
        primaryEvent,
        selected: isSelected,
        featured: isFeatured,
        stackedCount: events.length,
      );

      if (!await mapboxMap.style.hasStyleImage(imageId)) {
        var bytes = _posterImageCache[imageId];
        if (bytes == null) {
          final decodedImage =
              await _loadAndCacheEventImage(primaryEvent.imageUri);
          bytes = await _renderPosterMarkerImage(
            image: decodedImage,
            selected: isSelected,
            featured: isFeatured,
            stackedCount: events.length,
            category: _pinCategory(primaryEvent),
          );
          _posterImageCache[imageId] = bytes;
        }
        await mapboxMap.style.addStyleImage(
          imageId,
          2.0,
          MbxImage(width: _pixelWidth, height: _pixelHeight, data: bytes),
          false,
          const [],
          const [],
          null,
        );
      }
    }

    final source = await mapboxMap.style.getSource(_eventSourceId);
    if (source is GeoJsonSource) {
      await source.updateGeoJSON(
        buildLotusEventGroupFeatureCollection(groups, widget.selectedEventId),
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

    if (!await mapboxMap.style.styleSourceExists(_eventSourceId)) {
      final groups = groupLotusEventsByProximity(widget.events);
      await mapboxMap.style.addSource(
        GeoJsonSource(
          id: _eventSourceId,
          data: buildLotusEventGroupFeatureCollection(
            groups,
            widget.selectedEventId,
          ),
          cluster: true,
          clusterRadius: 48,
          clusterMaxZoom: 15,
          clusterMinPoints: 4,
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

    // Cluster tap
    if (result.layers.contains(_clusterLayerId)) {
      widget.onMapTapEmpty();
      final camera = await mapboxMap.getCameraState();
      if (camera.zoom < 14.8) {
        await mapboxMap.easeTo(
          CameraOptions(
            center: context.point,
            zoom: (camera.zoom + 2.5).clamp(0, 20).toDouble(),
            bearing: camera.bearing,
            pitch: camera.pitch,
            padding: camera.padding,
          ),
          MapAnimationOptions(duration: 500, startDelay: 0),
        );
        await Future<void>.delayed(const Duration(milliseconds: 520));
        await _reportViewport();
      } else {
        // At high zoom, cluster cannot be expanded further: open area sheet
        final coords = GeoCoordinates(
          latitude: context.point.coordinates.lat.toDouble(),
          longitude: context.point.coordinates.lng.toDouble(),
        );
        widget.onClusterTapArea?.call(coords);
      }
      return;
    }

    // Poster marker tap
    final properties = result.queriedFeature.feature['properties'];
    if (properties is Map) {
      final isStacked = properties['isStacked'] == true;
      final count = properties['count'] as int? ?? 1;

      if (isStacked && count > 1) {
        final rawIds = properties['eventIds'];
        List<String> ids = [];
        if (rawIds is String) {
          try {
            ids = List<String>.from(jsonDecode(rawIds));
          } catch (_) {}
        } else if (rawIds is List) {
          ids = rawIds.cast<String>();
        }
        if (ids.length > 1) {
          widget.onStackedEventsTap?.call(ids);
          return;
        }
      }

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
        zoom: 15.0,
        bearing: camera.bearing,
        pitch: camera.pitch,
        padding: MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
      ),
      MapAnimationOptions(duration: 800, startDelay: 0),
    );
    await Future<void>.delayed(const Duration(milliseconds: 820));
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
    final targetZoom = (camera.zoom < 15.5 ? 15.5 : camera.zoom)
        .clamp(1.0, 20.0)
        .toDouble();
    await mapboxMap.easeTo(
      CameraOptions(
        center: Point(
          coordinates: Position(coordinates.longitude, coordinates.latitude),
        ),
        zoom: targetZoom,
        bearing: camera.bearing,
        pitch: camera.pitch,
        padding: MbxEdgeInsets(
          top: 0,
          left: 0,
          bottom: _eventPreviewCameraPadding,
          right: 0,
        ),
      ),
      MapAnimationOptions(duration: 600, startDelay: 0),
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
      viewport: _initialViewport,
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: (_) => _onStyleLoaded(),
      onMapIdleListener: (_) => _reportViewport(),
      onScrollListener: _onUserCameraGesture,
      onZoomListener: _onUserCameraGesture,
      // ignore: deprecated_member_use
      onTapListener: _onMapTap,
    );
  }
}

class LotusLocationGroup {
  LotusLocationGroup({required this.coordinates, required this.events});
  final GeoCoordinates coordinates;
  final List<Event> events;
}

List<LotusLocationGroup> groupLotusEventsByProximity(List<Event> events) {
  final groups = <LotusLocationGroup>[];
  const threshold = 0.00018; // ~18 meters proximity

  for (final event in events) {
    final coords = event.location.coordinates;
    if (coords == null) continue;

    LotusLocationGroup? matchingGroup;
    for (final group in groups) {
      final dLat = (group.coordinates.latitude - coords.latitude).abs();
      final dLng = (group.coordinates.longitude - coords.longitude).abs();
      if (dLat < threshold && dLng < threshold) {
        matchingGroup = group;
        break;
      }
    }

    if (matchingGroup != null) {
      matchingGroup.events.add(event);
    } else {
      groups.add(LotusLocationGroup(coordinates: coords, events: [event]));
    }
  }

  return groups;
}

String buildLotusEventGroupFeatureCollection(
  List<LotusLocationGroup> groups,
  String? selectedEventId,
) {
  return jsonEncode({
    'type': 'FeatureCollection',
    'features': [
      for (final group in groups)
        () {
          final events = group.events;
          final isSelected = events.any((e) => e.id == selectedEventId);
          final isFeatured = events.any((e) => e.isFeatured);
          final primaryEvent = isSelected
              ? events.firstWhere((e) => e.id == selectedEventId)
              : (events.firstWhere((e) => e.isFeatured, orElse: () => events.first));

          final imageId = buildLotusPosterImageId(
            primaryEvent,
            selected: isSelected,
            featured: isFeatured,
            stackedCount: events.length,
          );

          return {
            'type': 'Feature',
            'properties': {
              'eventId': primaryEvent.id,
              'eventIds': events.map((e) => e.id).toList(),
              'isStacked': events.length > 1,
              'count': events.length,
              'selected': isSelected,
              'featured': isFeatured,
              'posterImageId': imageId,
              'sortKey': isSelected ? 3 : (isFeatured ? 2 : 1),
            },
            'geometry': {
              'type': 'Point',
              'coordinates': [
                group.coordinates.longitude,
                group.coordinates.latitude,
              ],
            },
          };
        }(),
    ],
  });
}

Map<String, Object> _clusterLayer() => {
  'id': _clusterLayerId,
  'type': 'circle',
  'source': _eventSourceId,
  'filter': ['has', 'point_count'],
  'paint': {
    'circle-color': '#151B23',
    'circle-radius': [
      'step',
      ['get', 'point_count'],
      18,
      10,
      22,
      30,
      26,
    ],
    'circle-stroke-width': 3.5,
    'circle-stroke-color': '#B7F34A',
  },
};

Map<String, Object> _clusterCountLayer() => {
  'id': _clusterCountLayerId,
  'type': 'symbol',
  'source': _eventSourceId,
  'filter': ['has', 'point_count'],
  'layout': {
    'text-field': ['get', 'point_count_abbreviated'],
    'text-size': 13,
  },
  'paint': {'text-color': '#B7F34A'},
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
    'icon-image': ['get', 'posterImageId'],
    'icon-anchor': 'bottom',
    'icon-size': [
      'interpolate',
      ['linear'],
      ['zoom'],
      10,
      0.70,
      14,
      0.85,
      17,
      1.05,
    ],
    'icon-allow-overlap': true,
    'symbol-sort-key': ['get', 'sortKey'],
  },
};

String buildLotusPosterImageId(
  Event event, {
  required bool selected,
  required bool featured,
  required int stackedCount,
}) {
  final countSuffix = stackedCount > 1 ? '-stack$stackedCount' : '';
  final stateSuffix = selected ? '-selected' : (featured ? '-featured' : '');
  final imageKey = (event.imageUri?.toString() ?? 'noimg').hashCode;
  return 'lotus-poster-$imageKey$stateSuffix$countSuffix';
}

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

IconData _pinIcon(_LotusPinCategory category) => switch (category) {
  _LotusPinCategory.music => Icons.music_note_rounded,
  _LotusPinCategory.theatre => Icons.theater_comedy_rounded,
  _LotusPinCategory.party => Icons.bolt_rounded,
  _LotusPinCategory.sport => Icons.sports_soccer_rounded,
  _LotusPinCategory.culture => Icons.palette_rounded,
  _LotusPinCategory.food => Icons.restaurant_rounded,
  _LotusPinCategory.workshop => Icons.lightbulb_rounded,
  _LotusPinCategory.comedy => Icons.sentiment_very_satisfied_rounded,
  _LotusPinCategory.other => Icons.local_activity_rounded,
};

Future<ui.Image?> _loadAndCacheEventImage(Uri? uri) async {
  if (uri == null) return null;
  final url = uri.toString();
  if (_decodedImageCache.containsKey(url)) {
    return _decodedImageCache[url];
  }
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    final request = await client.getUrl(uri);
    final response = await request.close().timeout(const Duration(seconds: 3));
    if (response.statusCode == 200) {
      final bytes = await consolidateHttpClientResponseBytes(response);
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 96,
        targetHeight: 128,
      );
      final frame = await codec.getNextFrame();
      _decodedImageCache[url] = frame.image;
      return frame.image;
    }
  } catch (_) {}
  return null;
}

Future<Uint8List> _renderPosterMarkerImage({
  required ui.Image? image,
  required bool selected,
  required bool featured,
  required int stackedCount,
  required _LotusPinCategory category,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Scaled 2x for Retina sharp rendering
  canvas.scale(2.0, 2.0);

  final mainCardRect = Rect.fromLTWH(6, 4, 44, 58);
  final mainCardRRect = RRect.fromRectAndRadius(
    mainCardRect,
    const Radius.circular(7),
  );

  // 1. Stacked Deck Effect (behind main card)
  if (stackedCount >= 2) {
    if (stackedCount >= 3) {
      final thirdCardRect = Rect.fromLTWH(11, 0, 42, 56);
      canvas.drawRRect(
        RRect.fromRectAndRadius(thirdCardRect, const Radius.circular(7)),
        Paint()..color = const Color(0xFF0A0E13),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(thirdCardRect, const Radius.circular(7)),
        Paint()
          ..color = const Color(0xFF293342)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
    final secondCardRect = Rect.fromLTWH(9, 2, 43, 57);
    canvas.drawRRect(
      RRect.fromRectAndRadius(secondCardRect, const Radius.circular(7)),
      Paint()..color = const Color(0xFF0F141B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(secondCardRect, const Radius.circular(7)),
      Paint()
        ..color = const Color(0xFF293342)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  // 2. Drop Shadow for main card
  canvas.drawRRect(
    mainCardRRect.shift(const Offset(0, 3)),
    Paint()
      ..color = const Color(0x99000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
  );

  // 3. Bottom Pointer / Needle connecting to exact coordinate
  final pointerPath = Path()
    ..moveTo(28 - 5, 61)
    ..lineTo(28 + 5, 61)
    ..lineTo(28, 71)
    ..close();

  // Pointer Shadow
  canvas.drawPath(
    pointerPath.shift(const Offset(0, 1.5)),
    Paint()
      ..color = const Color(0x80000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
  );

  // Pointer Body
  final pointerColor = selected
      ? const Color(0xFFB7F34A)
      : (featured ? const Color(0xFFB7F34A) : const Color(0xFF151B23));
  canvas.drawPath(pointerPath, Paint()..color = pointerColor);

  // Pointer Dot at exact anchor point (28, 70.5)
  canvas.drawCircle(
    const Offset(28, 70.5),
    2.5,
    Paint()
      ..color = selected || featured
          ? const Color(0xFFB7F34A)
          : const Color(0xFFFFFFFF),
  );

  // 4. Poster Base Background
  canvas.drawRRect(
    mainCardRRect,
    Paint()..color = const Color(0xFF151B23),
  );

  // 5. Draw Image Content or Fallback
  canvas.save();
  canvas.clipRRect(mainCardRRect);

  if (image != null) {
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(image, srcRect, mainCardRect, Paint());
  } else {
    // Elegant Lotus Fallback Card
    final gradient = ui.Gradient.linear(
      mainCardRect.topLeft,
      mainCardRect.bottomRight,
      const [Color(0xFF1B232C), Color(0xFF0A0E13)],
    );
    canvas.drawRect(mainCardRect, Paint()..shader = gradient);

    final icon = _pinIcon(category);
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: const Color(0xFFB7F34A),
          fontSize: 20,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(
        mainCardRect.center.dx - iconPainter.width / 2,
        mainCardRect.center.dy - iconPainter.height / 2,
      ),
    );
  }
  canvas.restore();

  // 6. Outer Border and High-Contrast Outline
  if (selected) {
    // Glowing outer halo
    canvas.drawRRect(
      mainCardRRect,
      Paint()
        ..color = const Color(0x66B7F34A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    // Sharp Neon Green Border
    canvas.drawRRect(
      mainCardRRect,
      Paint()
        ..color = const Color(0xFFB7F34A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  } else if (featured) {
    // Featured Neon Green Border
    canvas.drawRRect(
      mainCardRRect,
      Paint()
        ..color = const Color(0xFFB7F34A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Featured Star Badge at Top-Left
    final starRect = Rect.fromLTWH(4, 2, 14, 14);
    canvas.drawCircle(
      starRect.center,
      7,
      Paint()..color = const Color(0xFF080B10),
    );
    canvas.drawCircle(
      starRect.center,
      6,
      Paint()..color = const Color(0xFFB7F34A),
    );
    final starPainter = TextPainter(
      text: const TextSpan(
        text: '★',
        style: TextStyle(
          color: Color(0xFF080B10),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    starPainter.paint(
      canvas,
      Offset(
        starRect.center.dx - starPainter.width / 2,
        starRect.center.dy - starPainter.height / 2,
      ),
    );
  } else {
    // Normal Marker Border
    canvas.drawRRect(
      mainCardRRect,
      Paint()
        ..color = const Color(0xFF080B10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawRRect(
      mainCardRRect,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  // 7. Stacked Count Pill Badge (Top-Right)
  if (stackedCount > 1) {
    final badgeRect = Rect.fromLTWH(36, 1, 17, 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(7)),
      Paint()..color = const Color(0xFF080B10),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(7)),
      Paint()
        ..color = const Color(0xFFB7F34A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$stackedCount',
        style: const TextStyle(
          color: Color(0xFFB7F34A),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        badgeRect.center.dx - textPainter.width / 2,
        badgeRect.center.dy - textPainter.height / 2,
      ),
    );
  }

  final picture = recorder.endRecording();
  final renderedImage = await picture.toImage(_pixelWidth, _pixelHeight);
  final bytes = await renderedImage.toByteData(format: ui.ImageByteFormat.png);
  renderedImage.dispose();
  picture.dispose();

  if (bytes == null) {
    throw StateError('Could not render the poster marker image.');
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
