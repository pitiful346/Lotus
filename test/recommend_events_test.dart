import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  final now = DateTime.utc(2026, 8, 18, 12);

  test('explicit interests rank matching events first', () {
    final recommendations = const RecommendEvents()(
      candidates: [
        _event('culture', 'Cultura', now.add(const Duration(days: 1))),
        _event('music', 'Música', now.add(const Duration(days: 3))),
      ],
      interestCategoryIds: {'music'},
      interactions: const [],
      now: now,
    );

    expect(recommendations.first.event.id, 'events/music');
    expect(recommendations.first.reason, 'Corresponde aos teus interesses');
  });

  test('recent high-value interactions create category affinity', () {
    final interactions = [
      EventInteractionSummary(
        eventId: 'events/old-music',
        categoryIds: const ['music'],
        lastType: EventInteractionType.ticketOpened,
        firstInteractedAt: now.subtract(const Duration(days: 2)),
        lastInteractedAt: now.subtract(const Duration(days: 1)),
        viewCount: 1,
        ticketCount: 1,
      ),
    ];

    final recommendations = const RecommendEvents()(
      candidates: [
        _event('sport', 'Desporto', now.add(const Duration(days: 1))),
        _event('music', 'Música', now.add(const Duration(days: 2))),
      ],
      interestCategoryIds: const {},
      interactions: interactions,
      now: now,
    );

    expect(recommendations.first.event.id, 'events/music');
    expect(recommendations.first.reason, 'Baseado no que guardaste e viste');
  });

  test('saved and past events are excluded from discovery', () {
    final recommendations = const RecommendEvents()(
      candidates: [
        _event('saved', 'Música', now.add(const Duration(days: 1))),
        _event('past', 'Música', now.subtract(const Duration(hours: 1))),
        _event('future', 'Música', now.add(const Duration(days: 2))),
      ],
      interestCategoryIds: const {'music'},
      interactions: const [],
      favoriteEventIds: const {'events/saved'},
      now: now,
    );

    expect(recommendations.map((recommendation) => recommendation.event.id), [
      'events/future',
    ]);
  });

  test('legacy favorites contribute affinity without being recommended', () {
    final recommendations = const RecommendEvents()(
      candidates: [
        _eventWithCategory(
          'saved-music',
          'music',
          now.add(const Duration(days: 1)),
        ),
        _eventWithCategory(
          'new-sport',
          'sport',
          now.add(const Duration(hours: 2)),
        ),
        _eventWithCategory(
          'new-music',
          'music',
          now.add(const Duration(days: 2)),
        ),
      ],
      interestCategoryIds: const {},
      interactions: const [],
      favoriteEventIds: const {'events/saved-music'},
      now: now,
    );

    expect(recommendations.first.event.id, 'events/new-music');
    expect(recommendations.first.reason, 'Baseado no que guardaste e viste');
  });

  test('interaction summaries reject negative counters', () {
    expect(
      () => EventInteractionSummary(
        eventId: 'events/music',
        categoryIds: const ['music'],
        lastType: EventInteractionType.viewed,
        firstInteractedAt: now,
        lastInteractedAt: now,
        viewCount: -1,
      ),
      throwsArgumentError,
    );
  });
}

Event _event(String id, String category, DateTime startsAt) => Event(
  id: 'events/$id',
  title: id,
  description: 'Description',
  categories: [
    EventCategory(id: id == 'sport' ? 'sport' : id, label: category),
  ],
  location: EventLocation(displayName: 'Porto'),
  startsAt: startsAt,
  status: EventStatus.published,
);

Event _eventWithCategory(String id, String categoryId, DateTime startsAt) =>
    Event(
      id: 'events/$id',
      title: id,
      description: 'Description',
      categories: [EventCategory(id: categoryId, label: categoryId)],
      location: EventLocation(displayName: 'Porto'),
      startsAt: startsAt,
      status: EventStatus.published,
    );
