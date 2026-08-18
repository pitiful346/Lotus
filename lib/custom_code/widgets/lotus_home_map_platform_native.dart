import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

const _mapboxAccessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

Widget buildLotusHomeMap() {
  if (!Platform.isAndroid && !Platform.isIOS) {
    return const _UnsupportedMapView();
  }

  if (!_mapboxAccessToken.startsWith('pk.')) {
    return const _MissingTokenView();
  }

  return const _NativeLotusHomeMap();
}

class _NativeLotusHomeMap extends StatefulWidget {
  const _NativeLotusHomeMap();

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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // MapWidget owns and disposes the native MapboxMap controller.
    _mapboxMap = null;
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _applyDarkStyle();
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
