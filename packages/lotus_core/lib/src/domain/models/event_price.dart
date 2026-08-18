/// Price range stored in minor currency units to avoid floating-point errors.
final class EventPrice {
  EventPrice({
    required String currencyCode,
    this.minimumMinorUnits,
    this.maximumMinorUnits,
  }) : currencyCode = _normalizeCurrency(currencyCode) {
    final minimum = minimumMinorUnits;
    final maximum = maximumMinorUnits;

    if (minimum != null && minimum < 0) {
      throw ArgumentError.value(
        minimum,
        'minimumMinorUnits',
        'Must be non-negative.',
      );
    }
    if (maximum != null && maximum < 0) {
      throw ArgumentError.value(
        maximum,
        'maximumMinorUnits',
        'Must be non-negative.',
      );
    }
    if (minimum == null && maximum != null) {
      throw ArgumentError('A maximum price requires a minimum price.');
    }
    if (minimum != null && maximum != null && maximum < minimum) {
      throw ArgumentError(
        'The maximum price must not be lower than the minimum.',
      );
    }
  }

  factory EventPrice.free({String currencyCode = 'EUR'}) => EventPrice(
    currencyCode: currencyCode,
    minimumMinorUnits: 0,
    maximumMinorUnits: 0,
  );

  factory EventPrice.unknown({String currencyCode = 'EUR'}) =>
      EventPrice(currencyCode: currencyCode);

  final String currencyCode;
  final int? minimumMinorUnits;
  final int? maximumMinorUnits;

  bool get isKnown => minimumMinorUnits != null;
  bool get isFree => minimumMinorUnits == 0 && (maximumMinorUnits ?? 0) == 0;
}

String _normalizeCurrency(String value) {
  final normalized = value.trim().toUpperCase();
  if (normalized.length != 3) {
    throw ArgumentError.value(value, 'currencyCode', 'Use an ISO 4217 code.');
  }
  return normalized;
}
