import '/backend/backend.dart';
import 'package:lotus_core/lotus_core.dart';

final class FirestorePromoterFollowRepository implements PromoterFollowRepository {
  FirestorePromoterFollowRepository({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  @override
  Stream<bool> watchIsFollowing({
    required String userId,
    required String organizerId,
  }) {
    final normalizedUserId = _validateUserId(userId);
    final normalizedOrganizerId = _validateOrganizerId(organizerId);

    return _firestore
        .collection('users')
        .doc(normalizedUserId)
        .collection('following_organizers')
        .doc(normalizedOrganizerId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  @override
  Stream<Set<String>> watchFollowedOrganizerIds(String userId) {
    final normalizedUserId = _validateUserId(userId);

    return _firestore
        .collection('users')
        .doc(normalizedUserId)
        .collection('following_organizers')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  @override
  Stream<int> watchFollowerCount(String organizerId) {
    final normalizedOrganizerId = _validateOrganizerId(organizerId);

    return _firestore
        .collection('organizers')
        .doc(normalizedOrganizerId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  @override
  Future<void> setFollowing({
    required String userId,
    required String organizerId,
    required bool isFollowing,
  }) async {
    final normalizedUserId = _validateUserId(userId);
    final normalizedOrganizerId = _validateOrganizerId(organizerId);

    final userDoc = _firestore.collection('users').doc(normalizedUserId);
    final organizerDoc =
        _firestore.collection('organizers').doc(normalizedOrganizerId);

    final userFollowingDoc =
        userDoc.collection('following_organizers').doc(normalizedOrganizerId);
    final organizerFollowerDoc =
        organizerDoc.collection('followers').doc(normalizedUserId);

    final batch = _firestore.batch();

    if (isFollowing) {
      batch.set(userFollowingDoc, {
        'organizer_ref': organizerDoc,
        'organizer_id': normalizedOrganizerId,
        'created_at': FieldValue.serverTimestamp(),
      });
      batch.set(organizerFollowerDoc, {
        'user_ref': userDoc,
        'user_id': normalizedUserId,
        'created_at': FieldValue.serverTimestamp(),
      });
    } else {
      batch.delete(userFollowingDoc);
      batch.delete(organizerFollowerDoc);
    }

    await batch.commit();
  }

  static String _validateUserId(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty || normalized.contains('/')) {
      throw ArgumentError.value(userId, 'userId', 'Must be a valid document ID.');
    }
    return normalized;
  }

  static String _validateOrganizerId(String organizerId) {
    final normalized = organizerId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(organizerId, 'organizerId', 'Must not be empty.');
    }
    final segments = normalized.split('/');
    final documentId = segments.length == 1
        ? segments.single
        : (segments.length == 2 &&
                (segments.first == 'organizers' || segments.first == 'users'))
            ? segments.last
            : null;
    if (documentId == null || documentId.isEmpty) {
      throw ArgumentError.value(
        organizerId,
        'organizerId',
        'Must be an organizer document ID or organizers/<id> path.',
      );
    }
    return documentId;
  }
}
