import 'event.dart';

enum EventSearchResultType { event, venue, artist, category }

/// A conventional text-search result, independent from its eventual backend.
final class EventSearchResult {
  EventSearchResult({
    required this.type,
    required String key,
    required String title,
    required Iterable<Event> events,
  }) : key = _requiredText(key, 'key'),
       title = _requiredText(title, 'title'),
       events = List.unmodifiable(events) {
    if (this.events.isEmpty) {
      throw ArgumentError.value(events, 'events', 'Must not be empty.');
    }
  }

  final EventSearchResultType type;
  final String key;
  final String title;
  final List<Event> events;

  Event? get event => type == EventSearchResultType.event ? events.first : null;
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'Must not be empty.');
  }
  return normalized;
}
