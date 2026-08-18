import '/backend/backend.dart';
import 'package:lotus_core/lotus_core.dart';

import 'events_record_to_event.dart';

/// Bounded adapter for the first conventional search implementation.
///
/// The corpus is loaded once per search-page lifecycle. A dedicated indexed
/// search service can later implement the same domain contract without
/// changing the UI or matching rules.
final class FirestoreEventSearchRepository implements EventSearchRepository {
  Future<List<Event>>? _cachedCorpus;
  int? _cachedLimit;

  @override
  Future<List<Event>> loadCorpus({required int limit}) async {
    if (limit < 1 || limit > 500) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 500.');
    }
    if (_cachedCorpus == null || _cachedLimit != limit) {
      _cachedLimit = limit;
      _cachedCorpus = _load(limit);
    }
    final corpus = _cachedCorpus!;
    try {
      return await corpus;
    } catch (_) {
      if (identical(_cachedCorpus, corpus)) {
        _cachedCorpus = null;
        _cachedLimit = null;
      }
      rethrow;
    }
  }

  Future<List<Event>> _load(int limit) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final records = await queryEventsRecordOnce(
      queryBuilder: (query) => query
          .where('start_date', isGreaterThanOrEqualTo: startOfToday)
          .orderBy('start_date'),
      limit: limit,
    );
    final organizers = await _loadOrganizers(records);
    return List.unmodifiable(
      records
          .map(
            (record) => eventFromRecord(
              record,
              organizer: record.organizerId == null
                  ? null
                  : organizers[record.organizerId!.path],
            ),
          )
          .whereType<Event>(),
    );
  }

  Future<Map<String, EventOrganizer>> _loadOrganizers(
    List<EventsRecord> records,
  ) async {
    final references = <String, DocumentReference>{};
    for (final record in records) {
      final reference = record.organizerId;
      if (reference != null) {
        references[reference.path] = reference;
      }
    }

    final organizers = <String, EventOrganizer>{};
    final ids = references.values.map((reference) => reference.id).toList();
    for (var offset = 0; offset < ids.length; offset += 30) {
      final end = (offset + 30).clamp(0, ids.length);
      final chunk = ids.sublist(offset, end);
      try {
        final snapshot = await UsersRecord.collection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final document in snapshot.docs) {
          final record = UsersRecord.fromSnapshot(document);
          organizers[record.reference.path] = eventOrganizerFromRecord(record);
        }
      } catch (_) {
        // Search remains useful for events, venues, and categories if profile
        // reads are unavailable for the current user.
      }
    }
    return organizers;
  }
}
