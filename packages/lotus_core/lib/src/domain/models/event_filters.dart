enum EventDateFilter { today, tomorrow, thisWeekend }

/// User-selected constraints applied to events already loaded for a viewport.
final class EventFilters {
  EventFilters({
    this.date,
    Iterable<String> categoryIds = const [],
    this.freeOnly = false,
    this.maximumDistanceMeters,
    this.maximumPriceMinorUnits,
  }) : categoryIds = Set.unmodifiable(
         categoryIds
             .map(canonicalFilterValue)
             .where((value) => value.isNotEmpty),
       ) {
    final distance = maximumDistanceMeters;
    if (distance != null && (!distance.isFinite || distance <= 0)) {
      throw ArgumentError.value(
        distance,
        'maximumDistanceMeters',
        'Must be a finite positive value.',
      );
    }
    final price = maximumPriceMinorUnits;
    if (price != null && price < 0) {
      throw ArgumentError.value(
        price,
        'maximumPriceMinorUnits',
        'Must not be negative.',
      );
    }
  }

  final EventDateFilter? date;
  final Set<String> categoryIds;
  final bool freeOnly;
  final double? maximumDistanceMeters;
  final int? maximumPriceMinorUnits;

  bool get isEmpty => activeCount == 0;

  int get activeCount =>
      (date == null ? 0 : 1) +
      categoryIds.length +
      (freeOnly ? 1 : 0) +
      (maximumDistanceMeters == null ? 0 : 1) +
      (maximumPriceMinorUnits == null ? 0 : 1);
}

/// Produces stable filter keys across accented labels and legacy category ids.
String canonicalFilterValue(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[áàãâä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[íìîï]'), 'i')
      .replaceAll(RegExp('[óòõôö]'), 'o')
      .replaceAll(RegExp('[úùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
}
