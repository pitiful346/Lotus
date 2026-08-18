import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  test('calculates the distance between Porto coordinates', () {
    final distance = calculateDistanceMeters(
      GeoCoordinates(latitude: 41.14961, longitude: -8.61099),
      GeoCoordinates(latitude: 41.1588, longitude: -8.6308),
    );

    expect(distance, inInclusiveRange(1800, 2000));
  });

  test('distance to an event is unavailable without coordinates', () {
    final event = Event(
      id: 'events/online',
      title: 'Online event',
      description: 'Remote.',
      categories: [EventCategory(id: 'other', label: 'Other')],
      location: EventLocation(displayName: 'Online'),
      startsAt: DateTime.utc(2026, 9, 10),
    );

    expect(
      calculateDistanceToEvent(
        GeoCoordinates(latitude: 41.15, longitude: -8.61),
        event,
      ),
      isNull,
    );
  });
}
