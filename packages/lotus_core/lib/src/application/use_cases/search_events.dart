import '../../domain/models/event.dart';
import '../../domain/models/event_filters.dart';
import '../../domain/models/event_search_result.dart';

/// Accent-insensitive, token-based search for the bounded event corpus.
final class SearchEvents {
  List<EventSearchResult> call(
    Iterable<Event> events,
    String query, {
    int maximumPerType = 8,
  }) {
    if (maximumPerType < 1) {
      throw ArgumentError.value(
        maximumPerType,
        'maximumPerType',
        'Must be positive.',
      );
    }
    final tokens = canonicalFilterValue(
      query,
    ).split('-').where((token) => token.isNotEmpty).toList(growable: false);
    if (tokens.isEmpty) {
      return const [];
    }

    final corpus = events.toList(growable: false);
    return List.unmodifiable([
      ..._eventResults(corpus, tokens).take(maximumPerType),
      ..._facetResults(
        corpus,
        tokens,
        type: EventSearchResultType.venue,
        valuesFor: (event) => {
          event.location.displayName,
          if (event.location.venueName case final venue?) venue,
          if (event.location.city case final city?) city,
        },
      ).take(maximumPerType),
      ..._facetResults(
        corpus,
        tokens,
        type: EventSearchResultType.artist,
        valuesFor: (event) => {
          if (event.organizer case final organizer?) organizer.name,
        },
      ).take(maximumPerType),
      ..._facetResults(
        corpus,
        tokens,
        type: EventSearchResultType.category,
        valuesFor: (event) => {
          for (final category in event.categories) category.label,
        },
      ).take(maximumPerType),
    ]);
  }
}

Iterable<EventSearchResult> _eventResults(
  List<Event> events,
  List<String> tokens,
) {
  final matches =
      events
          .where((event) {
            return _matches('${event.title} ${event.description}', tokens);
          })
          .toList(growable: false)
        ..sort((left, right) {
          final scoreComparison = _score(
            left.title,
            tokens,
          ).compareTo(_score(right.title, tokens));
          return scoreComparison != 0
              ? scoreComparison
              : left.startsAt.compareTo(right.startsAt);
        });
  return matches.map(
    (event) => EventSearchResult(
      type: EventSearchResultType.event,
      key: event.id,
      title: event.title,
      events: [event],
    ),
  );
}

Iterable<EventSearchResult> _facetResults(
  List<Event> events,
  List<String> tokens, {
  required EventSearchResultType type,
  required Set<String> Function(Event event) valuesFor,
}) {
  final labels = <String, String>{};
  final eventsByKey = <String, List<Event>>{};
  for (final event in events) {
    for (final value in valuesFor(event)) {
      final key = canonicalFilterValue(value);
      if (key.isEmpty || !_matches(value, tokens)) {
        continue;
      }
      labels.putIfAbsent(key, () => value.trim());
      final matchingEvents = eventsByKey.putIfAbsent(key, () => []);
      if (!matchingEvents.any((candidate) => candidate.id == event.id)) {
        matchingEvents.add(event);
      }
    }
  }
  final keys = labels.keys.toList(growable: false)
    ..sort((left, right) {
      final scoreComparison = _score(
        labels[left]!,
        tokens,
      ).compareTo(_score(labels[right]!, tokens));
      return scoreComparison != 0
          ? scoreComparison
          : labels[left]!.compareTo(labels[right]!);
    });
  return keys.map(
    (key) => EventSearchResult(
      type: type,
      key: key,
      title: labels[key]!,
      events: eventsByKey[key]!,
    ),
  );
}

bool _matches(String value, List<String> tokens) {
  final normalized = canonicalFilterValue(value);
  return tokens.every(normalized.contains);
}

int _score(String value, List<String> tokens) {
  final normalized = canonicalFilterValue(value);
  final query = tokens.join('-');
  if (normalized == query) {
    return 0;
  }
  if (normalized.startsWith(query)) {
    return 1;
  }
  return 2;
}
