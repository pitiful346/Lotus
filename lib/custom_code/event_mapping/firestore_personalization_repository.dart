import '/backend/backend.dart';
import 'package:lotus_core/lotus_core.dart';

final class FirestorePersonalizationRepository
    implements PersonalizationRepository {
  FirestorePersonalizationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<Set<String>> watchInterestCategoryIds(String userId) {
    return _preferences(userId).snapshots().map((snapshot) {
      final values = snapshot.data()?['interest_ids'];
      return Set.unmodifiable(
        values is Iterable
            ? values
                  .whereType<String>()
                  .map(_normalize)
                  .where((value) => value.isNotEmpty)
            : const <String>[],
      );
    });
  }

  @override
  Future<void> setInterestCategoryIds({
    required String userId,
    required Set<String> categoryIds,
  }) async {
    final normalized = categoryIds
        .map(_normalize)
        .where((value) => value.isNotEmpty)
        .toSet();
    if (normalized.length > 30) {
      throw ArgumentError.value(categoryIds, 'categoryIds', 'Maximum is 30.');
    }
    await _preferences(userId).set({
      'interest_ids': normalized.toList()..sort(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<EventInteractionSummary>> watchInteractionHistory(
    String userId, {
    int limit = 100,
  }) {
    if (limit < 1 || limit > 200) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 200.');
    }
    return _user(userId)
        .collection('interactions')
        .orderBy('last_interacted_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => List.unmodifiable(
            snapshot.docs.map(_interactionFromDocument).whereType(),
          ),
        );
  }

  @override
  Future<void> recordInteraction({
    required String userId,
    required String eventId,
    required Set<String> categoryIds,
    required EventInteractionType type,
  }) async {
    final event = _event(eventId);
    final interaction = _user(userId).collection('interactions').doc(event.id);
    final categories =
        categoryIds
            .map(_normalize)
            .where((value) => value.isNotEmpty)
            .take(20)
            .toList()
          ..sort();
    final counter = _counterField(type);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(interaction);
      if (!snapshot.exists) {
        transaction.set(interaction, {
          'event_ref': event,
          'event_id': event.id,
          'category_ids': categories,
          'first_interacted_at': FieldValue.serverTimestamp(),
          'last_interacted_at': FieldValue.serverTimestamp(),
          'last_interaction_type': type.name,
          'view_count': type == EventInteractionType.viewed ? 1 : 0,
          'save_count': type == EventInteractionType.saved ? 1 : 0,
          'share_count': type == EventInteractionType.shared ? 1 : 0,
          'directions_count': type == EventInteractionType.directionsOpened
              ? 1
              : 0,
          'ticket_count': type == EventInteractionType.ticketOpened ? 1 : 0,
        });
        return;
      }
      transaction.update(interaction, {
        'category_ids': categories,
        'last_interacted_at': FieldValue.serverTimestamp(),
        'last_interaction_type': type.name,
        counter: FieldValue.increment(1),
      });
    });
  }

  DocumentReference<Map<String, dynamic>> _user(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty || normalized.contains('/')) {
      throw ArgumentError.value(userId, 'userId', 'Must be a document ID.');
    }
    return _firestore.collection('users').doc(normalized);
  }

  DocumentReference<Map<String, dynamic>> _preferences(String userId) =>
      _user(userId).collection('preferences').doc('personalization');

  DocumentReference<Map<String, dynamic>> _event(String eventId) {
    final parts = eventId.trim().split('/');
    final id = parts.length == 1
        ? parts.single
        : parts.length == 2 && parts.first == 'events'
        ? parts.last
        : '';
    if (id.isEmpty) {
      throw ArgumentError.value(eventId, 'eventId', 'Invalid event path.');
    }
    return _firestore.collection('events').doc(id);
  }
}

EventInteractionSummary? _interactionFromDocument(
  QueryDocumentSnapshot<Map<String, dynamic>> document,
) {
  final data = document.data();
  final first = data['first_interacted_at'];
  final last = data['last_interacted_at'];
  final type = EventInteractionType.values.where(
    (value) => value.name == data['last_interaction_type'],
  );
  if (first is! Timestamp || last is! Timestamp || type.isEmpty) {
    return null;
  }
  try {
    return EventInteractionSummary(
      eventId: 'events/${document.id}',
      categoryIds:
          (data['category_ids'] as Iterable?)?.whereType<String>() ?? const [],
      lastType: type.first,
      firstInteractedAt: first.toDate(),
      lastInteractedAt: last.toDate(),
      viewCount: _count(data['view_count']),
      saveCount: _count(data['save_count']),
      shareCount: _count(data['share_count']),
      directionsCount: _count(data['directions_count']),
      ticketCount: _count(data['ticket_count']),
    );
  } on ArgumentError {
    return null;
  }
}

int _count(Object? value) => value is int && value >= 0 ? value : 0;

String _counterField(EventInteractionType type) => switch (type) {
  EventInteractionType.viewed => 'view_count',
  EventInteractionType.saved => 'save_count',
  EventInteractionType.shared => 'share_count',
  EventInteractionType.directionsOpened => 'directions_count',
  EventInteractionType.ticketOpened => 'ticket_count',
};

String _normalize(String value) => value.trim().toLowerCase();
