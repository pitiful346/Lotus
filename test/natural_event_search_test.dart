import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  const parser = ParseNaturalEventQuery();
  final now = DateTime(2026, 8, 18, 12);

  test('turns the Porto techno example into structured filters', () {
    final query = parser.interpret(
      'quero techno amanhã à noite no Porto',
      now: now,
    );

    expect(query.hasStructuredFilters, isTrue);
    expect(query.keywordTokens, {'techno'});
    expect(query.categoryIds, {'musica'});
    expect(query.locationTerms, {'porto'});
    expect(query.dayPeriod, EventDayPeriod.night);
    expect(query.dateStart, DateTime(2026, 8, 19));
    expect(query.dateEndExclusive, DateTime(2026, 8, 20));
  });

  test('understands free events, weekends, and a maximum price', () {
    final free = parser.interpret('eventos gratuitos hoje de manhã', now: now);
    final priced = parser.interpret(
      'música este fim de semana até 20 euros',
      now: now,
    );

    expect(free.freeOnly, isTrue);
    expect(free.dayPeriod, EventDayPeriod.morning);
    expect(free.dateStart, DateTime(2026, 8, 18));
    expect(priced.categoryIds, {'musica'});
    expect(priced.maximumPriceMinorUnits, 2000);
    expect(priced.dateStart, DateTime(2026, 8, 22));
    expect(priced.dateEndExclusive, DateTime(2026, 8, 24));
  });

  test('natural search applies all structured filters', () {
    final query = parser.interpret(
      'quero techno amanhã à noite no Porto',
      now: now,
    );
    final results = const SearchEventsNaturally()([
      _event(
        'matching',
        title: 'Techno Garden',
        location: 'Porto',
        startsAt: DateTime(2026, 8, 19, 22),
      ),
      _event(
        'wrong-city',
        title: 'Techno Lisboa',
        location: 'Lisboa',
        startsAt: DateTime(2026, 8, 19, 22),
      ),
      _event(
        'wrong-time',
        title: 'Techno Brunch',
        location: 'Porto',
        startsAt: DateTime(2026, 8, 19, 11),
      ),
    ], query);

    expect(results.map((event) => event.id), ['events/matching']);
  });

  test('plain text remains available to conventional search', () {
    final query = parser.interpret('Lotus', now: now);

    expect(query.hasStructuredFilters, isFalse);
    expect(query.keywordTokens, {'lotus'});
  });
}

Event _event(
  String id, {
  required String title,
  required String location,
  required DateTime startsAt,
}) => Event(
  id: 'events/$id',
  title: title,
  description: 'Evento de música eletrónica',
  categories: [EventCategory(id: 'Música', label: 'Música')],
  location: EventLocation(displayName: location, city: location),
  startsAt: startsAt,
  status: EventStatus.published,
);
