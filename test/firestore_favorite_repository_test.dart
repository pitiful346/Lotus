import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/event_mapping/favorite_events_loader.dart';
import 'package:lotus/custom_code/event_mapping/firestore_favorite_repository.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  group('FirestoreFavoriteRepository argument validation', () {
    test('rejects invalid or empty userId', () {
      final repository = FirestoreFavoriteRepository();

      expect(
        () => repository.watchFavoriteEventIds(''),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => repository.watchFavoriteEventIds('users/invalid/nested'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects invalid or empty eventId', () {
      final repository = FirestoreFavoriteRepository();

      expect(
        () => repository.watchIsFavorite(userId: 'uid-123', eventId: ''),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => repository.watchIsFavorite(
          userId: 'uid-123',
          eventId: 'invalid/path/with/too/many/segments',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('FavoriteEventsResult', () {
    test('calculates correct missing count', () {
      final event = Event(
        id: 'events/1',
        title: 'Evento',
        description: 'Desc',
        categories: [EventCategory(id: 'c1', label: 'Cat 1')],
        location: EventLocation(displayName: 'Local'),
        startsAt: DateTime.utc(2026, 8, 20),
      );

      const result = FavoriteEventsResult(
        events: [],
        missingCount: 2,
      );

      expect(result.events, isEmpty);
      expect(result.missingCount, 2);

      final resultWithEvent = FavoriteEventsResult(
        events: [event],
        missingCount: 0,
      );
      expect(resultWithEvent.events.length, 1);
      expect(resultWithEvent.missingCount, 0);
    });
  });
}
