import 'dart:async';

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

  testWidgets('search UI explains and applies a natural query', (tester) async {
    final now = DateTime(2026, 8, 18, 12);
    final repository = _FakeSearchRepository([
      _naturalEvent(
        'techno-porto',
        title: 'Techno Garden',
        city: 'Porto',
        startsAt: DateTime(2026, 8, 19, 22),
      ),
      _naturalEvent(
        'techno-lisboa',
        title: 'Techno Lisboa',
        city: 'Lisboa',
        startsAt: DateTime(2026, 8, 19, 22),
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: LotusEventSearch(
          repository: repository,
          debounceDuration: Duration.zero,
          onOpenEvent: (_) {},
          now: () => now,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('event-search-field')),
      'quero techno amanhã à noite no Porto',
    );
    await tester.pumpAndSettle();

    expect(find.text('Amanhã'), findsOneWidget);
    expect(find.text('Noite'), findsOneWidget);
    expect(find.text('Porto'), findsOneWidget);
    expect(find.text('Música'), findsOneWidget);
    expect(find.text('Techno Garden'), findsOneWidget);
    expect(find.text('Techno Lisboa'), findsNothing);
  });

  testWidgets('search shows an accessible skeleton while loading', (
    tester,
  ) async {
    final completer = Completer<List<Event>>();
    await tester.pumpWidget(
      MaterialApp(
        home: LotusEventSearch(
          repository: _PendingSearchRepository(completer.future),
          debounceDuration: Duration.zero,
          onOpenEvent: (_) {},
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('event-search-field')),
      'porto',
    );
    await tester.pump();
    expect(find.byKey(const Key('lotus-skeleton-list')), findsOneWidget);

    completer.complete(_events());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lotus-skeleton-list')), findsNothing);
  });

  testWidgets('search distinguishes empty results from connection errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LotusEventSearch(
          repository: _FakeSearchRepository(const []),
          debounceDuration: Duration.zero,
          onOpenEvent: (_) {},
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('event-search-field')),
      'inexistente',
    );
    await tester.pumpAndSettle();
    expect(find.text('Sem resultados'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: LotusEventSearch(
          repository: const _FailingSearchRepository(),
          debounceDuration: Duration.zero,
          onOpenEvent: (_) {},
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('event-search-field')),
      'porto',
    );
    await tester.pumpAndSettle();
    expect(find.text('Pesquisa indisponível'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}

final class _PendingSearchRepository implements EventSearchRepository {
  const _PendingSearchRepository(this.result);

  final Future<List<Event>> result;

  @override
  Future<List<Event>> loadCorpus({required int limit}) => result;
}

final class _FailingSearchRepository implements EventSearchRepository {
  const _FailingSearchRepository();

  @override
  Future<List<Event>> loadCorpus({required int limit}) =>
      Future.error(StateError('offline'));
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

Event _naturalEvent(
  String id, {
  required String title,
  required String city,
  required DateTime startsAt,
}) => Event(
  id: 'events/$id',
  title: title,
  description: 'Techno',
  categories: [EventCategory(id: 'Música', label: 'Música')],
  location: EventLocation(displayName: city, city: city),
  startsAt: startsAt,
);
