import 'package:lotus_core/lotus_core.dart';

import '/backend/backend.dart';
import 'events_record_to_event.dart';

final class FavoriteEventsResult {
  const FavoriteEventsResult({
    required this.events,
    required this.missingCount,
  });

  final List<Event> events;
  final int missingCount;
}

abstract interface class FavoriteEventsLoader {
  Future<FavoriteEventsResult> load(Set<String> eventIds);
}

final class FirestoreFavoriteEventsLoader implements FavoriteEventsLoader {
  const FirestoreFavoriteEventsLoader();

  @override
  Future<FavoriteEventsResult> load(Set<String> eventIds) async {
    final ids = eventIds
        .map((path) => path.split('/'))
        .where((parts) => parts.length == 2 && parts.first == 'events')
        .map((parts) => parts.last)
        .where((id) => id.isNotEmpty)
        .take(120)
        .toList();
    final records = <EventsRecord>[];
    for (var offset = 0; offset < ids.length; offset += 30) {
      final end = (offset + 30).clamp(0, ids.length);
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where(FieldPath.documentId, whereIn: ids.sublist(offset, end))
          .get();
      records.addAll(snapshot.docs.map(EventsRecord.fromSnapshot));
    }
    final events = records.map(eventFromRecord).whereType<Event>().toList()
      ..sort((left, right) => left.startsAt.compareTo(right.startsAt));
    return FavoriteEventsResult(
      events: List.unmodifiable(events),
      missingCount: (eventIds.length - events.length).clamp(0, eventIds.length),
    );
  }
}
