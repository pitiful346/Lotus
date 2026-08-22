/// Lifecycle status of an in-app user notification.
enum AppNotificationStatus {
  unread,
  read;

  static AppNotificationStatus fromString(String? value) =>
      switch (value?.trim().toUpperCase()) {
        'READ' => AppNotificationStatus.read,
        _ => AppNotificationStatus.unread,
      };

  String get wireName => switch (this) {
    AppNotificationStatus.read => 'READ',
    AppNotificationStatus.unread => 'UNREAD',
  };
}

/// An in-app notification delivered to a user in the Lotus ecosystem.
final class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.status = AppNotificationStatus.unread,
    this.deepLink,
    this.targetId,
    this.targetType,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final AppNotificationStatus status;
  final String? deepLink;
  final String? targetId;
  final String? targetType;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => status == AppNotificationStatus.read;
  bool get isUnread => status == AppNotificationStatus.unread;

  AppNotification copyWith({
    AppNotificationStatus? status,
    DateTime? readAt,
  }) => AppNotification(
    id: id,
    title: title,
    body: body,
    type: type,
    status: status ?? this.status,
    deepLink: deepLink,
    targetId: targetId,
    targetType: targetType,
    createdAt: createdAt,
    readAt: readAt ?? this.readAt,
  );
}
