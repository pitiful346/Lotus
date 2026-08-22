import '../models/app_notification.dart';

/// Contract for fetching and updating a user's in-app notifications.
abstract interface class NotificationRepository {
  /// Emits real-time list of in-app notifications for [userId] ordered by creation date descending.
  Stream<List<AppNotification>> watchNotifications(String userId);

  /// Emits the count of unread notifications for [userId].
  Stream<int> watchUnreadCount(String userId);

  /// Marks a specific notification as read.
  Future<void> markAsRead({
    required String userId,
    required String notificationId,
  });

  /// Marks all unread notifications as read for [userId].
  Future<void> markAllAsRead(String userId);
}
