import '/backend/backend.dart';
import 'package:lotus_core/lotus_core.dart';

/// Reads public organizer profiles while retaining legacy user references.
Stream<EventOrganizer?> watchEventOrganizer(DocumentReference reference) {
  return reference.snapshots().map(eventOrganizerFromSnapshot);
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
    imageUri: _absoluteUri(rawData['photo_url']),
    websiteUri: _absoluteUri(rawData['website_url']),
  );
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
