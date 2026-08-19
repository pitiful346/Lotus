import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/event_mapping/development_event_seed.dart';
import 'package:lotus/custom_code/event_mapping/development_map_event_repository.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  test('development events are opt-in', () {
    expect(useDevelopmentEventSeed, isFalse);
  });

  test('development seed contains 18 complete Porto and Gaia events', () {
    final events = buildDevelopmentEventSeed(anchor: DateTime(2026, 8, 19));

    expect(events, hasLength(18));
    expect(events.map((event) => event.id).toSet(), hasLength(18));
    expect(events.every((event) => isDevelopmentEvent(event.id)), isTrue);
    expect(
      events.every(
        (event) =>
            event.status == EventStatus.published &&
            event.location.coordinates != null &&
            event.location.address != null &&
            event.location.venueName != null &&
            event.organizer != null &&
            event.imageUri != null &&
            event.startsAt.isAfter(DateTime.utc(2026, 8, 19)),
      ),
      isTrue,
    );
    expect(events.map((event) => event.categories.first.label).toSet(), {
      'Música',
      'Festas',
      'Cultura',
      'Teatro',
      'Desporto',
      'Comédia',
      'Gastronomia',
      'Workshops',
    });
    expect(
      events.any((event) => event.location.city == 'Vila Nova de Gaia'),
      isTrue,
    );
  });

  test('development repository returns only events in the viewport', () async {
    final repository = DevelopmentMapEventRepository(
      now: () => DateTime(2026, 8, 19),
      loadingDelay: Duration.zero,
    );
    final centralPorto = MapViewportBounds(
      south: 41.12,
      west: -8.665,
      north: 41.165,
      east: -8.585,
    );

    final events = await repository.findWithin(centralPorto, limit: 250);

    expect(events.length, greaterThanOrEqualTo(15));
    expect(
      events.every(
        (event) => centralPorto.contains(event.location.coordinates!),
      ),
      isTrue,
    );
    expect(repository.allEvents, same(repository.allEvents));
  });
}
