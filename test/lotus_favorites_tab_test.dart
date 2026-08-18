import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/widgets/lotus_favorites_tab.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  testWidgets('favorites has a useful empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LotusFavoritesTab(
          userId: 'user-1',
          favoriteRepository: _FavoritesRepository({}),
          eventsLoader: const _FavoriteLoader([]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ainda não guardaste eventos'), findsOneWidget);
  });

  testWidgets('favorites separates upcoming events and can remove one', (
    tester,
  ) async {
    final repository = _FavoritesRepository({'events/upcoming'});
    final event = Event(
      id: 'events/upcoming',
      title: 'Próximo evento',
      description: 'Descrição',
      categories: [EventCategory(id: 'cultura', label: 'Cultura')],
      location: EventLocation(displayName: 'Porto'),
      startsAt: DateTime.utc(2026, 8, 20),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LotusFavoritesTab(
          userId: 'user-1',
          favoriteRepository: repository,
          eventsLoader: _FavoriteLoader([event]),
          now: () => DateTime.utc(2026, 8, 18),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Próximos'), findsOneWidget);
    expect(find.text('Próximo evento'), findsOneWidget);
    await tester.tap(find.byTooltip('Remover dos favoritos'));
    await tester.pumpAndSettle();
    expect(repository.removedEventId, 'events/upcoming');
  });
}

final class _FavoritesRepository implements FavoriteRepository {
  _FavoritesRepository(this.ids);

  final Set<String> ids;
  String? _lastRemoved;

  String? get removedEventId => _lastRemoved;

  @override
  Future<void> setFavorite({
    required String userId,
    required String eventId,
    required bool isFavorite,
  }) async {
    if (!isFavorite) _lastRemoved = eventId;
  }

  @override
  Stream<Set<String>> watchFavoriteEventIds(String userId) => Stream.value(ids);

  @override
  Stream<bool> watchIsFavorite({
    required String userId,
    required String eventId,
  }) => Stream.value(ids.contains(eventId));
}

final class _FavoriteLoader implements FavoriteEventsLoader {
  const _FavoriteLoader(this.events);

  final List<Event> events;

  @override
  Future<FavoriteEventsResult> load(Set<String> eventIds) async =>
      FavoriteEventsResult(events: events, missingCount: 0);
}
