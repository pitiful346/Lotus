import 'dart:math' as math;

import '../../domain/models/event.dart';
import '../../domain/models/geo_coordinates.dart';

const _earthRadiusMeters = 6371000.0;

/// Calculates the great-circle distance without coupling domain code to a
/// location SDK.
double calculateDistanceMeters(
  GeoCoordinates origin,
  GeoCoordinates destination,
) {
  final latitudeDelta = _radians(destination.latitude - origin.latitude);
  final longitudeDelta = _radians(destination.longitude - origin.longitude);
  final originLatitude = _radians(origin.latitude);
  final destinationLatitude = _radians(destination.latitude);

  final haversine =
      math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(originLatitude) *
          math.cos(destinationLatitude) *
          math.pow(math.sin(longitudeDelta / 2), 2);
  final normalizedHaversine = haversine.clamp(0, 1).toDouble();
  final angularDistance =
      2 *
      math.atan2(
        math.sqrt(normalizedHaversine),
        math.sqrt(1 - normalizedHaversine),
      );
  return _earthRadiusMeters * angularDistance;
}

double? calculateDistanceToEvent(GeoCoordinates origin, Event event) {
  final destination = event.location.coordinates;
  return destination == null
      ? null
      : calculateDistanceMeters(origin, destination);
}

double _radians(double degrees) => degrees * math.pi / 180;
