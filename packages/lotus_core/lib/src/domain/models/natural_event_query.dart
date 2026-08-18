import 'event_filters.dart';

enum EventDayPeriod { earlyMorning, morning, afternoon, night }

/// Structured and inspectable interpretation of a natural-language query.
final class NaturalEventQuery {
  NaturalEventQuery({
    required String originalText,
    Iterable<String> keywordTokens = const [],
    Iterable<String> categoryIds = const [],
    Iterable<String> locationTerms = const [],
    this.dateStart,
    this.dateEndExclusive,
    this.dayPeriod,
    this.freeOnly = false,
    this.maximumPriceMinorUnits,
  }) : originalText = originalText.trim(),
       keywordTokens = Set.unmodifiable(_normalize(keywordTokens)),
       categoryIds = Set.unmodifiable(_normalize(categoryIds)),
       locationTerms = Set.unmodifiable(_normalize(locationTerms)) {
    if (this.originalText.isEmpty) {
      throw ArgumentError.value(
        originalText,
        'originalText',
        'Must not be empty.',
      );
    }
    if ((dateStart == null) != (dateEndExclusive == null)) {
      throw ArgumentError('Both date bounds must be provided together.');
    }
    if (dateStart != null && !dateEndExclusive!.isAfter(dateStart!)) {
      throw ArgumentError('dateEndExclusive must be after dateStart.');
    }
    final maximumPrice = maximumPriceMinorUnits;
    if (maximumPrice != null && maximumPrice < 0) {
      throw ArgumentError.value(
        maximumPrice,
        'maximumPriceMinorUnits',
        'Must not be negative.',
      );
    }
  }

  final String originalText;
  final Set<String> keywordTokens;
  final Set<String> categoryIds;
  final Set<String> locationTerms;
  final DateTime? dateStart;
  final DateTime? dateEndExclusive;
  final EventDayPeriod? dayPeriod;
  final bool freeOnly;
  final int? maximumPriceMinorUnits;

  bool get hasStructuredFilters =>
      categoryIds.isNotEmpty ||
      locationTerms.isNotEmpty ||
      dateStart != null ||
      dayPeriod != null ||
      freeOnly ||
      maximumPriceMinorUnits != null;

  /// Whether conventional facet search is insufficient for this query.
  bool get requiresStructuredSearch =>
      locationTerms.isNotEmpty ||
      dateStart != null ||
      dayPeriod != null ||
      freeOnly ||
      maximumPriceMinorUnits != null;
}

Iterable<String> _normalize(Iterable<String> values) sync* {
  for (final value in values) {
    final normalized = canonicalFilterValue(value);
    if (normalized.isNotEmpty) {
      yield normalized;
    }
  }
}
