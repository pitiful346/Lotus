import '/backend/backend.dart';
import 'package:lotus_core/lotus_core.dart';
import 'events_record_to_event.dart';

/// Reads public organizer profiles while retaining legacy user references.
Stream<EventOrganizer?> watchEventOrganizer(DocumentReference reference) {
  return reference.snapshots().map(eventOrganizerFromSnapshot);
}

/// Resolves an organizer reference from either a path ('organizers/id', 'users/id') or a bare ID.
DocumentReference resolveOrganizerReference(String pathOrId) {
  final clean = pathOrId.trim();
  if (clean.contains('/')) {
    return FirebaseFirestore.instance.doc(clean);
  }
  return FirebaseFirestore.instance.collection('organizers').doc(clean);
}

EventOrganizer? eventOrganizerFromSnapshot(DocumentSnapshot snapshot) {
  final rawData = snapshot.data();
  if (!snapshot.exists || rawData is! Map<String, dynamic>) {
    return null;
  }

  final name = _firstText([
    rawData['display_name'],
    rawData['name'],
    rawData['legal_name'],
  ]);
  if (name == null) {
    return null;
  }

  return EventOrganizer(
    id: snapshot.reference.path,
    name: name,
    description: _firstText([rawData['bio'], rawData['description']]),
    legalName: _firstText([rawData['legal_name']]),
    imageUri: _absoluteUri(rawData['photo_url'] ?? rawData['logo_url']),
    bannerUri: _absoluteUri(rawData['banner_url'] ?? rawData['cover_url']),
    websiteUri: _absoluteUri(rawData['website_url'] ?? rawData['website']),
    instagramUri: _absoluteUri(rawData['instagram_url'] ?? rawData['instagram']),
    isVerified: rawData['is_verified'] == true,
  );
}

/// Streams all published events belonging to [organizerReference].
Stream<List<Event>> watchOrganizerEvents(
  DocumentReference organizerReference, {
  EventOrganizer? organizer,
}) {
  return FirebaseFirestore.instance
      .collection('events')
      .where('organizer_id', isEqualTo: organizerReference)
      .snapshots()
      .map((snapshot) {
        final events = <Event>[];
        for (final doc in snapshot.docs) {
          final record = EventsRecord.fromSnapshot(doc);
          final event = eventFromRecord(record, organizer: organizer);
          if (event != null) {
            events.add(event);
          }
        }
        events.sort((left, right) => left.startsAt.compareTo(right.startsAt));
        return List.unmodifiable(events);
      });
}

String? _firstText(Iterable<Object?> values) {
  for (final value in values.whereType<String>()) {
    final normalized = value.trim();
    if (normalized.isNotEmpty) {
      return normalized;
    }
  }
  return null;
}

Uri? _absoluteUri(Object? value) {
  if (value is! String) {
    return null;
  }
  final uri = Uri.tryParse(value.trim());
  return uri != null && uri.isAbsolute ? uri : null;
}
