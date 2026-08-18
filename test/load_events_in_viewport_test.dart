import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  test('filters repository candidates to the exact viewport', () async {
    final repository = _FakeMapEventRepository([
      _event('inside', latitude: 41.15, longitude: -8.61),
      _event('outside', latitude: 41.15, longitude: -9.1),
    ]);
    final load = LoadEventsInViewport(repository: repository);
    final bounds = MapViewportBounds(
      south: 41,
      west: -8.8,
      north: 41.3,
      east: -8.4,
    );

    final events = await load(bounds, limit: 25);

    expect(events.map((event) => event.id), ['inside']);
    expect(repository.lastLimit, 25);
  });

  test('enforces a finite query limit', () async {
    final load = LoadEventsInViewport(repository: _FakeMapEventRepository([]));
    final bounds = MapViewportBounds(south: 41, west: -9, north: 42, east: -8);

    expect(() => load(bounds, limit: 501), throwsArgumentError);
  });
}

final class _FakeMapEventRepository implements MapEventRepository {
  _FakeMapEventRepository(this.events);

  final List<Event> events;
  int? lastLimit;

  @override
  Future<List<Event>> findWithin(
    MapViewportBounds bounds, {
    required int limit,
  }) async {
    lastLimit = limit;
    return events;
  }
}

Event _event(String id, {required double latitude, required double longitude}) {
  return Event(
    id: id,
    title: id,
    description: 'Evento de teste',
    categories: [EventCategory(id: 'music', label: 'Música')],
    location: EventLocation(
      displayName: 'Porto',
      coordinates: GeoCoordinates(latitude: latitude, longitude: longitude),
    ),
    startsAt: DateTime.utc(2026, 8, 20),
  );
}
