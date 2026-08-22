import '../../domain/models/event.dart';
import '../../domain/models/event_filters.dart';
import '../../domain/models/geo_coordinates.dart';
import 'calculate_event_distance.dart';

/// Applies interactive Home filters without coupling the rules to Flutter.
final class FilterEvents {
  List<Event> call(
    Iterable<Event> events, {
    required EventFilters filters,
    required DateTime now,
    GeoCoordinates? userCoordinates,
  }) {
    if (filters.isEmpty) {
      return List.unmodifiable(events);
    }
    final dateRange = _dateRange(filters.date, now);
    final filtered = events.where((event) {
      if (dateRange != null &&
          !event.occursBetween(dateRange.start, dateRange.endInclusive)) {
        return false;
      }
      if (filters.categoryIds.isNotEmpty &&
          !_matchesCategory(event, filters.categoryIds)) {
        return false;
      }
      if (filters.freeOnly && !event.isFree) {
        return false;
      }

      final maximumPrice = filters.maximumPriceMinorUnits;
      final minimumPrice = event.price.minimumMinorUnits;
      if (maximumPrice != null &&
          (minimumPrice == null || minimumPrice > maximumPrice)) {
        return false;
      }

      final maximumDistance = filters.maximumDistanceMeters;
      if (maximumDistance != null) {
        if (userCoordinates == null) {
          return false;
        }
        final distance = calculateDistanceToEvent(userCoordinates, event);
        if (distance == null || distance > maximumDistance) {
          return false;
        }
      }
      return true;
    }).toList();

    if (filters.sortBy != null) {
      switch (filters.sortBy!) {
        case EventSortBy.proximity:
          if (userCoordinates != null) {
            filtered.sort((left, right) {
              final d1 =
                  calculateDistanceToEvent(userCoordinates, left) ??
                  double.infinity;
              final d2 =
                  calculateDistanceToEvent(userCoordinates, right) ??
                  double.infinity;
              return d1.compareTo(d2);
            });
          }
        case EventSortBy.popularity:
          filtered.sort(
            (left, right) =>
                right.popularityScore.compareTo(left.popularityScore),
          );
        case EventSortBy.date:
          filtered.sort((left, right) => left.startsAt.compareTo(right.startsAt));
      }
    }

    return List.unmodifiable(filtered);
  }
}

bool _matchesCategory(Event event, Set<String> selectedCategories) {
  for (final category in event.categories) {
    if (selectedCategories.contains(canonicalFilterValue(category.id)) ||
        selectedCategories.contains(canonicalFilterValue(category.label))) {
      return true;
    }
  }
  return false;
}

({DateTime start, DateTime endInclusive})? _dateRange(
  EventDateFilter? filter,
  DateTime now,
) {
  if (filter == null) {
    return null;
  }
  final today = _startOfDay(now);
  final DateTime start;
  final DateTime endExclusive;
  switch (filter) {
    case EventDateFilter.today:
      start = today;
      endExclusive = _addDays(today, 1);
    case EventDateFilter.tomorrow:
      start = _addDays(today, 1);
      endExclusive = _addDays(today, 2);
    case EventDateFilter.thisWeekend:
      final daysUntilSaturday = now.weekday == DateTime.sunday
          ? -1
          : (DateTime.saturday - now.weekday + 7) % 7;
      start = _addDays(today, daysUntilSaturday);
      endExclusive = _addDays(start, 2);
  }
  return (
    start: start,
    endInclusive: endExclusive.subtract(const Duration(microseconds: 1)),
  );
}

DateTime _startOfDay(DateTime value) => value.isUtc
    ? DateTime.utc(value.year, value.month, value.day)
    : DateTime(value.year, value.month, value.day);

DateTime _addDays(DateTime value, int days) => value.isUtc
    ? DateTime.utc(value.year, value.month, value.day + days)
    : DateTime(value.year, value.month, value.day + days);
