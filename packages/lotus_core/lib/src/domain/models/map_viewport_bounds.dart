import 'geo_coordinates.dart';

/// Geographic bounds currently visible in the event map.
///
/// A west value greater than east represents a viewport crossing the
/// antimeridian.
final class MapViewportBounds {
  MapViewportBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  }) {
    if (!south.isFinite || south < -90 || south > 90) {
      throw ArgumentError.value(south, 'south', 'Must be between -90 and 90.');
    }
    if (!north.isFinite || north < -90 || north > 90) {
      throw ArgumentError.value(north, 'north', 'Must be between -90 and 90.');
    }
    if (south > north) {
      throw ArgumentError('south must not be greater than north.');
    }
    if (!west.isFinite || west < -180 || west > 180) {
      throw ArgumentError.value(west, 'west', 'Must be between -180 and 180.');
    }
    if (!east.isFinite || east < -180 || east > 180) {
      throw ArgumentError.value(east, 'east', 'Must be between -180 and 180.');
    }
  }

  final double south;
  final double west;
  final double north;
  final double east;

  bool get crossesAntimeridian => west > east;

  bool contains(GeoCoordinates coordinates) {
    final latitudeInside =
        coordinates.latitude >= south && coordinates.latitude <= north;
    final longitudeInside = crossesAntimeridian
        ? coordinates.longitude >= west || coordinates.longitude <= east
        : coordinates.longitude >= west && coordinates.longitude <= east;
    return latitudeInside && longitudeInside;
  }

  bool isApproximatelyEqualTo(
    MapViewportBounds other, {
    double tolerance = 0.0005,
  }) {
    return (south - other.south).abs() <= tolerance &&
        (west - other.west).abs() <= tolerance &&
        (north - other.north).abs() <= tolerance &&
        (east - other.east).abs() <= tolerance;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapViewportBounds &&
          south == other.south &&
          west == other.west &&
          north == other.north &&
          east == other.east;

  @override
  int get hashCode => Object.hash(south, west, north, east);
}
