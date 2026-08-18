import '/backend/backend.dart';
import 'package:lotus_core/lotus_core.dart';
import 'package:rxdart/rxdart.dart';

/// Firestore favorites with temporary compatibility for FlutterFlow widgets.
///
/// The subcollection is the canonical scalable representation. The legacy
/// `users.favoritos` array remains synchronized until the generated saved and
/// card widgets have been migrated.
final class FirestoreFavoriteRepository implements FavoriteRepository {
  FirestoreFavoriteRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<bool> watchIsFavorite({
    required String userId,
    required String eventId,
  }) {
    final user = _userReference(userId);
    final event = _eventReference(eventId);
    final favorite = user.collection('favorites').doc(event.id);

    return Rx.combineLatest2(favorite.snapshots(), user.snapshots(), (
      favoriteSnapshot,
      userSnapshot,
    ) {
      if (favoriteSnapshot.exists) {
        return true;
      }
      final data = userSnapshot.data();
      final legacy = data?['favoritos'];
      return legacy is Iterable &&
          legacy.whereType<DocumentReference>().any(
            (reference) => reference.path == event.path,
          );
    }).distinct();
  }

  @override
  Future<void> setFavorite({
    required String userId,
    required String eventId,
    required bool isFavorite,
  }) async {
    final user = _userReference(userId);
    final event = _eventReference(eventId);
    final favorite = user.collection('favorites').doc(event.id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(favorite);
      if (isFavorite && !snapshot.exists) {
        transaction.set(favorite, {
          'event_ref': event,
          'event_id': event.id,
          'created_at': FieldValue.serverTimestamp(),
        });
      } else if (!isFavorite && snapshot.exists) {
        transaction.delete(favorite);
      }

      transaction.update(user, {
        'favoritos': isFavorite
            ? FieldValue.arrayUnion([event])
            : FieldValue.arrayRemove([event]),
      });
    });
  }

  DocumentReference<Map<String, dynamic>> _userReference(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty || normalized.contains('/')) {
      throw ArgumentError.value(userId, 'userId', 'Must be a document ID.');
    }
    return _firestore.collection('users').doc(normalized);
  }

  DocumentReference<Map<String, dynamic>> _eventReference(String eventId) {
    final normalized = eventId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(eventId, 'eventId', 'Must not be empty.');
    }
    final segments = normalized.split('/');
    final documentId = segments.length == 1
        ? segments.single
        : segments.length == 2 && segments.first == 'events'
        ? segments.last
        : null;
    if (documentId == null || documentId.isEmpty) {
      throw ArgumentError.value(
        eventId,
        'eventId',
        'Must be an event document ID or events/<id> path.',
      );
    }
    return _firestore.collection('events').doc(documentId);
  }
}
