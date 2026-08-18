import 'geo_coordinates.dart';

/// Human-readable and geographic information for an event location.
final class EventLocation {
  EventLocation({
    required String displayName,
    this.coordinates,
    String? venueName,
    String? address,
    String? city,
    String? region,
    String? postalCode,
    String? countryCode,
  }) : displayName = _requiredText(displayName, 'displayName'),
       venueName = _optionalText(venueName),
       address = _optionalText(address),
       city = _optionalText(city),
       region = _optionalText(region),
       postalCode = _optionalText(postalCode),
       countryCode = _normalizeCountryCode(countryCode);

  final String displayName;
  final String? venueName;
  final String? address;
  final String? city;
  final String? region;
  final String? postalCode;
  final String? countryCode;
  final GeoCoordinates? coordinates;

  double? get latitude => coordinates?.latitude;
  double? get longitude => coordinates?.longitude;
  bool get hasPhysicalCoordinates => coordinates != null;
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'Must not be empty.');
  }
  return normalized;
}

String? _optionalText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String? _normalizeCountryCode(String? value) {
  final normalized = _optionalText(value)?.toUpperCase();
  if (normalized != null && normalized.length != 2) {
    throw ArgumentError.value(
      value,
      'countryCode',
      'Use an ISO 3166-1 alpha-2 code.',
    );
  }
  return normalized;
}
