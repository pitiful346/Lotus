import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';

bool get isLotusHomeMapSupported => false;

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
}) => const _UnsupportedMapView();

class _UnsupportedMapView extends StatelessWidget {
  const _UnsupportedMapView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF080B10),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'O mapa da Home está disponível nas aplicações iOS e Android.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFB6C2D1)),
          ),
        ),
      ),
    );
  }
}
