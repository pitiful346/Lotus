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
    : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  @override
  Stream<Set<String>> watchFavoriteEventIds(String userId) {
    final normalizedUserId = _validateUserId(userId);
    final user = _firestore.collection('users').doc(normalizedUserId);
    return Rx.combineLatest2(
      user.collection('favorites').snapshots(),
      user.snapshots(),
      (favoriteSnapshot, userSnapshot) {
        final eventPaths = <String>{};
        for (final document in favoriteSnapshot.docs) {
          final reference = document.data()['event_ref'];
          eventPaths.add(
            reference is DocumentReference
                ? reference.path
                : 'events/${document.id}',
          );
        }
        final legacy = userSnapshot.data()?['favoritos'];
        if (legacy is Iterable) {
          eventPaths.addAll(
            legacy.whereType<DocumentReference>().map(
              (reference) => reference.path,
            ),
          );
        }
        return Set.unmodifiable(eventPaths);
      },
    ).distinct(_sameSet);
  }

  @override
  Stream<bool> watchIsFavorite({
    required String userId,
    required String eventId,
  }) {
    final normalizedUserId = _validateUserId(userId);
    final normalizedEventId = _validateEventId(eventId);
    final user = _firestore.collection('users').doc(normalizedUserId);
    final event = _firestore.collection('events').doc(normalizedEventId);
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
    final normalizedUserId = _validateUserId(userId);
    final normalizedEventId = _validateEventId(eventId);
    final user = _firestore.collection('users').doc(normalizedUserId);
    final event = _firestore.collection('events').doc(normalizedEventId);
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

  static String _validateUserId(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty || normalized.contains('/')) {
      throw ArgumentError.value(userId, 'userId', 'Must be a document ID.');
    }
    return normalized;
  }

  static String _validateEventId(String eventId) {
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
    return documentId;
  }
}

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);
