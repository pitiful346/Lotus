import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  final search = SearchEvents();
  final events = [
    _event(
      'lotus-night',
      title: 'Lotus Night',
      venue: 'Hard Club',
      organizer: 'DJ Maré',
      category: 'Música',
    ),
    _event(
      'jazz-river',
      title: 'Jazz no Rio',
      venue: 'Hard Club',
      organizer: 'Porto Sounds',
      category: 'Cultura',
    ),
  ];

  test('finds event titles without accents or case sensitivity', () {
    final results = search(events, 'LOTUS');

    expect(results.map((result) => result.title), contains('Lotus Night'));
    expect(
      results.firstWhere((result) => result.title == 'Lotus Night').type,
      EventSearchResultType.event,
    );
  });

  test('groups venues and exposes their matching events', () {
    final result = search(events, 'hard').single;

    expect(result.type, EventSearchResultType.venue);
    expect(result.title, 'Hard Club');
    expect(result.events.map((event) => event.id), [
      'events/lotus-night',
      'events/jazz-river',
    ]);
  });

  test('finds artists and categories', () {
    final artistResults = search(events, 'dj mare');
    final categoryResults = search(events, 'musica');

    expect(artistResults.single.type, EventSearchResultType.artist);
    expect(artistResults.single.title, 'DJ Maré');
    expect(categoryResults.single.type, EventSearchResultType.category);
    expect(categoryResults.single.title, 'Música');
  });

  test('requires every query token and returns nothing for blank text', () {
    expect(search(events, 'lotus jazz'), isEmpty);
    expect(search(events, '  '), isEmpty);
  });
}

Event _event(
  String id, {
  required String title,
  required String venue,
  required String organizer,
  required String category,
}) {
  return Event(
    id: 'events/$id',
    title: title,
    description: 'Evento no Porto',
    categories: [EventCategory(id: category, label: category)],
    location: EventLocation(displayName: venue, venueName: venue),
    startsAt: DateTime.utc(2026, 9, 1),
    organizer: EventOrganizer(id: organizer, name: organizer),
  );
}
