import '/backend/backend.dart';
import 'package:lotus_core/lotus_core.dart';
import 'firestore_organizer_repository.dart';

final class FirestoreTeaserRepository implements TeaserRepository {
  FirestoreTeaserRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  final FirebaseFirestore? _customFirestore;
  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Teaser>> watchActiveTeasers({String? categoryId, String? city}) {
    return _firestore
        .collection('teasers')
        .snapshots()
        .map((snapshot) {
          final teasers = <Teaser>[];
          for (final doc in snapshot.docs) {
            final teaser = teaserFromSnapshot(doc);
            if (teaser == null) continue;

            // Only show published (active) or revealed teasers in Radar feed
            if (teaser.status != TeaserStatus.published &&
                teaser.status != TeaserStatus.revealed) {
              continue;
            }

            if (categoryId != null &&
                categoryId.isNotEmpty &&
                teaser.category?.id != categoryId) {
              continue;
            }

            if (city != null &&
                city.isNotEmpty &&
                teaser.city?.toLowerCase() != city.toLowerCase()) {
              continue;
            }

            teasers.add(teaser);
          }

          // Sort by revealAt: nearest reveal first
          teasers.sort((a, b) => a.revealAt.compareTo(b.revealAt));
          return List.unmodifiable(teasers);
        });
  }

  @override
  Stream<Teaser?> watchTeaser(String teaserId) {
    final normalizedId = _validateId(teaserId, 'teaserId');
    final docRef = normalizedId.contains('/')
        ? _firestore.doc(normalizedId)
        : _firestore.collection('teasers').doc(normalizedId);

    return docRef.snapshots().map((snapshot) => teaserFromSnapshot(snapshot));
  }

  @override
  Stream<List<Teaser>> watchPromoterTeasers(String organizerId) {
    final orgRef = resolveOrganizerReference(organizerId);

    return _firestore
        .collection('teasers')
        .where('organizer_id', isEqualTo: orgRef)
        .snapshots()
        .map((snapshot) {
          final teasers = <Teaser>[];
          for (final doc in snapshot.docs) {
            final teaser = teaserFromSnapshot(doc);
            if (teaser != null) teasers.add(teaser);
          }
          teasers.sort((a, b) => a.revealAt.compareTo(b.revealAt));
          return List.unmodifiable(teasers);
        });
  }

  @override
  Stream<Set<String>> watchTrackedTeaserIds(String userId) {
    final normalizedUserId = _validateId(userId, 'userId');

    return _firestore
        .collection('users')
        .doc(normalizedUserId)
        .collection('tracked_teasers')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  @override
  Stream<bool> watchIsTrackingTeaser({
    required String userId,
    required String teaserId,
  }) {
    final normalizedUserId = _validateId(userId, 'userId');
    final normalizedTeaserId = _cleanDocId(teaserId);

    return _firestore
        .collection('users')
        .doc(normalizedUserId)
        .collection('tracked_teasers')
        .doc(normalizedTeaserId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  @override
  Stream<int> watchTeaserTrackerCount(String teaserId) {
    final normalizedTeaserId = _cleanDocId(teaserId);

    return _firestore
        .collection('teasers')
        .doc(normalizedTeaserId)
        .collection('trackers')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  @override
  Future<void> setTrackingTeaser({
    required String userId,
    required String teaserId,
    required bool isTracking,
  }) async {
    final normalizedUserId = _validateId(userId, 'userId');
    final normalizedTeaserId = _cleanDocId(teaserId);

    final userDoc = _firestore.collection('users').doc(normalizedUserId);
    final teaserDoc = _firestore.collection('teasers').doc(normalizedTeaserId);

    final userTrackedDoc =
        userDoc.collection('tracked_teasers').doc(normalizedTeaserId);
    final teaserTrackerDoc =
        teaserDoc.collection('trackers').doc(normalizedUserId);

    final batch = _firestore.batch();

    if (isTracking) {
      batch.set(userTrackedDoc, {
        'teaser_ref': teaserDoc,
        'teaser_id': normalizedTeaserId,
        'created_at': FieldValue.serverTimestamp(),
      });
      batch.set(teaserTrackerDoc, {
        'user_ref': userDoc,
        'user_id': normalizedUserId,
        'created_at': FieldValue.serverTimestamp(),
      });
    } else {
      batch.delete(userTrackedDoc);
      batch.delete(teaserTrackerDoc);
    }

    await batch.commit();
  }

  static String _validateId(String id, String paramName) {
    final normalized = id.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(id, paramName, 'Cannot be empty.');
    }
    return normalized;
  }

  static String _cleanDocId(String pathOrId) {
    final normalized = pathOrId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(pathOrId, 'teaserId', 'Cannot be empty.');
    }
    return normalized.split('/').last;
  }
}

Teaser? teaserFromSnapshot(DocumentSnapshot snapshot, {EventOrganizer? organizer}) {
  final rawData = snapshot.data();
  if (!snapshot.exists || rawData is! Map<String, dynamic>) {
    return null;
  }

  final description = (rawData['description'] as String?)?.trim();
  final revealAtTimestamp = rawData['reveal_at'] as Timestamp?;

  if (description == null || description.isEmpty || revealAtTimestamp == null) {
    return null;
  }

  final title = (rawData['title'] as String?)?.trim();
  final statusStr = rawData['status'] as String?;
  final status = TeaserStatus.fromString(statusStr);

  EventCategory? category;
  final categoryRaw = rawData['categoria'];
  if (categoryRaw is List && categoryRaw.isNotEmpty) {
    final firstCat = categoryRaw.first.toString().trim();
    if (firstCat.isNotEmpty) {
      category = EventCategory(
        id: firstCat.toLowerCase().replaceAll(' ', '_'),
        label: firstCat,
      );
    }
  }

  EventOrganizer? resolvedOrganizer = organizer;
  if (resolvedOrganizer == null) {
    final orgField = rawData['organizer_id'];
    if (orgField is DocumentReference) {
      resolvedOrganizer = EventOrganizer(
        id: orgField.path,
        name: rawData['organizer_name'] as String? ?? 'Promoter Lotus',
      );
    } else if (orgField is String && orgField.isNotEmpty) {
      resolvedOrganizer = EventOrganizer(
        id: orgField,
        name: rawData['organizer_name'] as String? ?? 'Promoter Lotus',
      );
    }
  }

  return Teaser(
    id: snapshot.reference.path,
    title: title != null && title.isNotEmpty ? title : null,
    description: description,
    imageUri: _parseUri(rawData['image'] ?? rawData['image_url']),
    organizer: resolvedOrganizer,
    category: category,
    city: (rawData['city'] as String?)?.trim(),
    approximateDate: (rawData['approximate_date'] as String?)?.trim(),
    revealAt: revealAtTimestamp.toDate(),
    status: status,
    targetEventId: (rawData['target_event_id'] as String?)?.trim(),
    trackerCount: rawData['trackers_count'] as int? ?? 0,
    createdAt: (rawData['created_at'] as Timestamp?)?.toDate(),
  );
}

Uri? _parseUri(Object? value) {
  if (value is! String) return null;
  final uri = Uri.tryParse(value.trim());
  return uri != null && uri.isAbsolute ? uri : null;
}
