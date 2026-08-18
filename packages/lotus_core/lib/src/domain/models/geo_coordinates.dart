/// Geographic coordinates independent from Mapbox, Flutter, or Firestore.
final class GeoCoordinates {
  GeoCoordinates({required this.latitude, required this.longitude}) {
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        'Must be between -90 and 90.',
      );
    }
    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'Must be between -180 and 180.',
      );
    }
  }

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoCoordinates &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
