import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lotus_core/lotus_core.dart';

/// Firestore implementation of [NotificationRepository].
final class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    final normalizedUserId = _validateUserId(userId);
    return _firestore
        .collection('users')
        .doc(normalizedUserId)
        .collection('notifications')
        .orderBy('created_at', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _fromSnapshot(doc.id, doc.data()))
            .toList());
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    final normalizedUserId = _validateUserId(userId);
    return _firestore
        .collection('users')
        .doc(normalizedUserId)
        .collection('notifications')
        .where('status', isEqualTo: 'UNREAD')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  @override
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  }) async {
    final normalizedUserId = _validateUserId(userId);
    final normalizedNotificationId = notificationId.trim();
    if (normalizedNotificationId.isEmpty) {
      throw ArgumentError.value(notificationId, 'notificationId', 'Cannot be empty');
    }

    final docRef = _firestore
        .collection('users')
        .doc(normalizedUserId)
        .collection('notifications')
        .doc(normalizedNotificationId);

    await docRef.update({
      'status': 'READ',
      'read_at': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final normalizedUserId = _validateUserId(userId);
    final query = await _firestore
        .collection('users')
        .doc(normalizedUserId)
        .collection('notifications')
        .where('status', isEqualTo: 'UNREAD')
        .limit(100)
        .get();

    if (query.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {
        'status': 'READ',
        'read_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  AppNotification _fromSnapshot(String id, Map<String, dynamic> data) {
    final createdAt = data['created_at'];
    final readAt = data['read_at'];
    final dataMap = data['data'] as Map<String, dynamic>? ?? {};

    DateTime parsedCreated;
    if (createdAt is Timestamp) {
      parsedCreated = createdAt.toDate();
    } else if (createdAt is String) {
      parsedCreated = DateTime.tryParse(createdAt) ?? DateTime.now();
    } else {
      parsedCreated = DateTime.now();
    }

    DateTime? parsedRead;
    if (readAt is Timestamp) {
      parsedRead = readAt.toDate();
    } else if (readAt is String) {
      parsedRead = DateTime.tryParse(readAt);
    }

    final rawType = (data['type'] as String? ?? 'general').toLowerCase();
    final rawStatus = data['status'] as String? ?? 'UNREAD';
    final deepLink = data['deep_link'] as String? ??
        dataMap['deep_link'] as String? ??
        (dataMap['eventId'] != null ? 'lotus://event/${dataMap['eventId']}' : null);

    return AppNotification(
      id: id,
      title: data['title'] as String? ?? 'Notificação Lotus',
      body: data['body'] as String? ?? '',
      type: rawType,
      status: AppNotificationStatus.fromString(rawStatus),
      deepLink: deepLink,
      targetId: dataMap['eventId'] as String? ??
          dataMap['promoterId'] as String? ??
          dataMap['teaserId'] as String?,
      targetType: dataMap['type'] as String?,
      createdAt: parsedCreated,
      readAt: parsedRead,
    );
  }

  String _validateUserId(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty || normalized.contains('/')) {
      throw ArgumentError.value(userId, 'userId', 'Must be a valid document ID');
    }
    return normalized;
  }
}
