import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/widgets/lotus_event_search.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  testWidgets('search UI finds and opens an event', (tester) async {
    final repository = _FakeSearchRepository(_events());
    Event? openedEvent;
    await tester.pumpWidget(
      MaterialApp(
        home: LotusEventSearch(
          repository: repository,
          debounceDuration: Duration.zero,
          onOpenEvent: (event) => openedEvent = event,
        ),
      ),
    );

    expect(
      find.text('Pesquisa por evento, local, artista ou categoria.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('event-search-field')),
      'lotus',
    );
    await tester.pumpAndSettle();

    expect(find.text('Eventos'), findsOneWidget);
    expect(find.text('Lotus Night'), findsOneWidget);
    await tester.tap(find.text('Lotus Night'));
    await tester.pump();
    expect(openedEvent?.id, 'events/lotus-night');
  });

  testWidgets('search UI groups venues, artists, and categories', (
    tester,
  ) async {
    final repository = _FakeSearchRepository(_events());
    await tester.pumpWidget(
      MaterialApp(
        home: LotusEventSearch(
          repository: repository,
          debounceDuration: Duration.zero,
          onOpenEvent: (_) {},
        ),
      ),
    );
    final field = find.byKey(const Key('event-search-field'));

    await tester.enterText(field, 'hard');
    await tester.pumpAndSettle();
    expect(find.text('Locais'), findsOneWidget);
    expect(find.text('Hard Club'), findsOneWidget);

    await tester.enterText(field, 'dj mare');
    await tester.pumpAndSettle();
    expect(find.text('Artistas'), findsOneWidget);
    expect(find.text('DJ Maré'), findsOneWidget);

    await tester.enterText(field, 'musica');
    await tester.pumpAndSettle();
    expect(find.text('Categorias'), findsOneWidget);
    expect(find.text('Música'), findsOneWidget);
    expect(repository.loadCalls, 1);
  });
}

final class _FakeSearchRepository implements EventSearchRepository {
  _FakeSearchRepository(this.events);

  final List<Event> events;
  int loadCalls = 0;

  @override
  Future<List<Event>> loadCorpus({required int limit}) async {
    loadCalls += 1;
    return events;
  }
}

List<Event> _events() => [
  _event(
    'lotus-night',
    title: 'Lotus Night',
    organizer: 'DJ Maré',
    category: 'Música',
  ),
  _event(
    'jazz-river',
    title: 'Jazz no Rio',
    organizer: 'Porto Sounds',
    category: 'Cultura',
  ),
];

Event _event(
  String id, {
  required String title,
  required String organizer,
  required String category,
}) {
  return Event(
    id: 'events/$id',
    title: title,
    description: 'Evento no Porto',
    categories: [EventCategory(id: category, label: category)],
    location: EventLocation(displayName: 'Hard Club', venueName: 'Hard Club'),
    startsAt: DateTime.utc(2026, 9, 1, 20),
    organizer: EventOrganizer(id: organizer, name: organizer),
  );
}
