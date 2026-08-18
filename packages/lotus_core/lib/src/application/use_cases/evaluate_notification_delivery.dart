import '../../domain/models/notification_preferences.dart';

enum NotificationSuppressionReason {
  disabled,
  duplicate,
  quietHours,
  dailyLimit,
}

final class NotificationDeliveryDecision {
  const NotificationDeliveryDecision._({required this.suppressionReason});

  const NotificationDeliveryDecision.send() : this._(suppressionReason: null);

  const NotificationDeliveryDecision.suppress(
    NotificationSuppressionReason reason,
  ) : this._(suppressionReason: reason);

  final NotificationSuppressionReason? suppressionReason;
  bool get shouldSend => suppressionReason == null;
}

/// Pure policy shared by UI tests and mirrored by the trusted backend.
final class EvaluateNotificationDelivery {
  const EvaluateNotificationDelivery();

  NotificationDeliveryDecision call({
    required NotificationPreferences preferences,
    required EventNotificationKind kind,
    required DateTime localNow,
    required int deliveredToday,
    required bool alreadyDelivered,
  }) {
    if (!preferences.allows(kind)) {
      return const NotificationDeliveryDecision.suppress(
        NotificationSuppressionReason.disabled,
      );
    }
    if (alreadyDelivered) {
      return const NotificationDeliveryDecision.suppress(
        NotificationSuppressionReason.duplicate,
      );
    }
    if (_isQuietHour(
      localNow.hour,
      preferences.quietHoursStart,
      preferences.quietHoursEnd,
    )) {
      return const NotificationDeliveryDecision.suppress(
        NotificationSuppressionReason.quietHours,
      );
    }
    if (deliveredToday >= preferences.maxPerDay) {
      return const NotificationDeliveryDecision.suppress(
        NotificationSuppressionReason.dailyLimit,
      );
    }
    return const NotificationDeliveryDecision.send();
  }
}

bool _isQuietHour(int hour, int start, int end) {
  if (start == end) return false;
  if (start < end) return hour >= start && hour < end;
  return hour >= start || hour < end;
}
