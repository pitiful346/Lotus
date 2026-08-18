import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/widgets/event_pin_diff.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  test('pin diff only returns added, changed, and removed events', () {
    final first = _event('first', latitude: 41.1, longitude: -8.6);
    final moved = _event('moved', latitude: 41.2, longitude: -8.7);
    final removed = _event('removed', latitude: 41.3, longitude: -8.8);

    final initial = diffEventPins(
      previous: const {},
      events: [first, moved, removed],
    );
    final changes = diffEventPins(
      previous: initial.current,
      events: [
        first,
        _event('moved', latitude: 41.25, longitude: -8.7),
        _event('added', latitude: 41.4, longitude: -8.9, isFeatured: true),
      ],
    );

    expect(changes.added.map((pin) => pin.eventId), ['added']);
    expect(changes.updated.map((pin) => pin.eventId), ['moved']);
    expect(changes.removedEventIds, ['removed']);
  });

  test('pin diff ignores changes that do not affect marker rendering', () {
    final event = _event('event', latitude: 41.1, longitude: -8.6);
    final initial = diffEventPins(previous: const {}, events: [event]);
    final renamed = Event(
      id: event.id,
      title: 'Updated title',
      description: event.description,
      categories: event.categories,
      location: event.location,
      startsAt: event.startsAt,
    );

    final changes = diffEventPins(previous: initial.current, events: [renamed]);

    expect(changes.added, isEmpty);
    expect(changes.updated, isEmpty);
    expect(changes.removedEventIds, isEmpty);
  });
}

Event _event(
  String id, {
  required double latitude,
  required double longitude,
  bool isFeatured = false,
}) {
  return Event(
    id: id,
    title: 'Event $id',
    description: 'Description',
    categories: [EventCategory(id: 'music', label: 'Music')],
    location: EventLocation(
      displayName: 'Porto',
      coordinates: GeoCoordinates(latitude: latitude, longitude: longitude),
    ),
    startsAt: DateTime.utc(2026, 9, 10),
    isFeatured: isFeatured,
  );
}
