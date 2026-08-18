import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  final filterEvents = FilterEvents();
  final now = DateTime.utc(2026, 8, 18, 12); // Tuesday.

  test('filters today, tomorrow, and the upcoming weekend', () {
    final events = [
      _event('today', startsAt: DateTime.utc(2026, 8, 18, 20)),
      _event('tomorrow', startsAt: DateTime.utc(2026, 8, 19, 20)),
      _event('saturday', startsAt: DateTime.utc(2026, 8, 22, 20)),
      _event('monday', startsAt: DateTime.utc(2026, 8, 24, 20)),
    ];

    expect(
      filterEvents(
        events,
        filters: EventFilters(date: EventDateFilter.today),
        now: now,
      ).map((event) => event.id),
      ['today'],
    );
    expect(
      filterEvents(
        events,
        filters: EventFilters(date: EventDateFilter.tomorrow),
        now: now,
      ).map((event) => event.id),
      ['tomorrow'],
    );
    expect(
      filterEvents(
        events,
        filters: EventFilters(date: EventDateFilter.thisWeekend),
        now: now,
      ).map((event) => event.id),
      ['saturday'],
    );
  });

  test('matches category aliases without accents or casing', () {
    final events = [
      _event(
        'music',
        categories: [EventCategory(id: 'Música', label: 'Música ao vivo')],
      ),
      _event(
        'sport',
        categories: [EventCategory(id: 'desporto', label: 'Desporto')],
      ),
    ];

    final result = filterEvents(
      events,
      filters: EventFilters(categoryIds: const ['musica']),
      now: now,
    );

    expect(result.map((event) => event.id), ['music']);
  });

  test('combines free, maximum price, and distance filters', () {
    final origin = GeoCoordinates(latitude: 41.14961, longitude: -8.61099);
    final events = [
      _event('free-near', price: EventPrice.free()),
      _event(
        'paid-near',
        price: EventPrice(currencyCode: 'EUR', minimumMinorUnits: 1000),
      ),
      _event('free-far', longitude: -8.0, price: EventPrice.free()),
    ];

    final freeNearby = filterEvents(
      events,
      filters: EventFilters(freeOnly: true, maximumDistanceMeters: 5000),
      now: now,
      userCoordinates: origin,
    );
    final underFifteenEuros = filterEvents(
      events,
      filters: EventFilters(maximumPriceMinorUnits: 1500),
      now: now,
      userCoordinates: origin,
    );

    expect(freeNearby.map((event) => event.id), ['free-near']);
    expect(underFifteenEuros.map((event) => event.id), [
      'free-near',
      'paid-near',
      'free-far',
    ]);
  });

  test('requires a user position when distance is active', () {
    final result = filterEvents(
      [_event('event')],
      filters: EventFilters(maximumDistanceMeters: 1000),
      now: now,
    );

    expect(result, isEmpty);
  });
}

Event _event(
  String id, {
  DateTime? startsAt,
  List<EventCategory>? categories,
  double longitude = -8.61099,
  EventPrice? price,
}) {
  return Event(
    id: id,
    title: id,
    description: 'Evento de teste',
    categories: categories ?? [EventCategory(id: 'outros', label: 'Outros')],
    location: EventLocation(
      displayName: 'Porto',
      coordinates: GeoCoordinates(latitude: 41.14961, longitude: longitude),
    ),
    startsAt: startsAt ?? DateTime.utc(2026, 8, 18, 20),
    price: price,
  );
}
