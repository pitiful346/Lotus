import 'package:lotus_core/lotus_core.dart';

/// Render-relevant event data used to update Mapbox pins incrementally.
final class EventPin {
  const EventPin({
    required this.eventId,
    required this.latitude,
    required this.longitude,
    required this.isFeatured,
  });

  final String eventId;
  final double latitude;
  final double longitude;
  final bool isFeatured;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventPin &&
          eventId == other.eventId &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          isFeatured == other.isFeatured;

  @override
  int get hashCode => Object.hash(eventId, latitude, longitude, isFeatured);
}

final class EventPinChanges {
  const EventPinChanges({
    required this.current,
    required this.added,
    required this.updated,
    required this.removedEventIds,
  });

  final Map<String, EventPin> current;
  final List<EventPin> added;
  final List<EventPin> updated;
  final List<String> removedEventIds;
}

EventPinChanges diffEventPins({
  required Map<String, EventPin> previous,
  required Iterable<Event> events,
}) {
  final current = <String, EventPin>{};
  for (final event in events) {
    final coordinates = event.location.coordinates;
    if (coordinates == null || event.status == EventStatus.archived) {
      continue;
    }
    current[event.id] = EventPin(
      eventId: event.id,
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      isFeatured: event.isFeatured,
    );
  }

  final added = <EventPin>[];
  final updated = <EventPin>[];
  for (final entry in current.entries) {
    final oldPin = previous[entry.key];
    if (oldPin == null) {
      added.add(entry.value);
    } else if (oldPin != entry.value) {
      updated.add(entry.value);
    }
  }

  final removedEventIds = previous.keys
      .where((eventId) => !current.containsKey(eventId))
      .toList(growable: false);

  return EventPinChanges(
    current: Map.unmodifiable(current),
    added: List.unmodifiable(added),
    updated: List.unmodifiable(updated),
    removedEventIds: removedEventIds,
  );
}
