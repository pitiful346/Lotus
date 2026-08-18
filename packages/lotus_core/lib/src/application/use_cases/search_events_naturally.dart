import '../../domain/models/event.dart';
import '../../domain/models/event_filters.dart';
import '../../domain/models/natural_event_query.dart';

final class SearchEventsNaturally {
  const SearchEventsNaturally();

  List<Event> call(
    Iterable<Event> events,
    NaturalEventQuery query, {
    int limit = 50,
  }) {
    if (limit < 1 || limit > 200) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 200.');
    }
    final matches = events.where((event) => _matches(event, query)).toList()
      ..sort((left, right) => left.startsAt.compareTo(right.startsAt));
    return List.unmodifiable(matches.take(limit));
  }
}

bool _matches(Event event, NaturalEventQuery query) {
  final localStart = event.startsAt.toLocal();
  if (query.dateStart != null &&
      (localStart.isBefore(query.dateStart!) ||
          !localStart.isBefore(query.dateEndExclusive!))) {
    return false;
  }
  if (query.dayPeriod != null &&
      !_matchesPeriod(localStart, query.dayPeriod!)) {
    return false;
  }
  if (query.freeOnly && !event.isFree) {
    return false;
  }
  final maximumPrice = query.maximumPriceMinorUnits;
  final minimumPrice = event.price.minimumMinorUnits;
  if (maximumPrice != null &&
      (minimumPrice == null || minimumPrice > maximumPrice)) {
    return false;
  }

  final categories = {
    for (final category in event.categories) canonicalFilterValue(category.id),
    for (final category in event.categories)
      canonicalFilterValue(category.label),
  };
  if (query.categoryIds.isNotEmpty &&
      !query.categoryIds.any(categories.contains) &&
      !query.keywordTokens.any(categories.contains)) {
    return false;
  }

  final location = canonicalFilterValue(
    [
      event.location.displayName,
      if (event.location.venueName case final venue?) venue,
      if (event.location.city case final city?) city,
    ].join(' '),
  );
  if (query.locationTerms.any((term) => !location.contains(term))) {
    return false;
  }

  final searchable = canonicalFilterValue(
    [
      event.title,
      event.description,
      ...event.categories.map((category) => category.label),
      if (event.organizer case final organizer?) organizer.name,
      location,
    ].join(' '),
  );
  return query.keywordTokens.every(searchable.contains);
}

bool _matchesPeriod(DateTime startsAt, EventDayPeriod period) {
  final hour = startsAt.hour;
  return switch (period) {
    EventDayPeriod.earlyMorning => hour < 6,
    EventDayPeriod.morning => hour >= 6 && hour < 12,
    EventDayPeriod.afternoon => hour >= 12 && hour < 18,
    EventDayPeriod.night => hour >= 18,
  };
}
