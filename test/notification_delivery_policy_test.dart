import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  const policy = EvaluateNotificationDelivery();
  const optedIn = NotificationPreferences(
    favoriteEventUpdates: true,
    upcomingFavoriteEvents: true,
    recommendations: true,
  );

  test('notifications are opt-in by default', () {
    const preferences = NotificationPreferences();

    expect(preferences.hasAnySubscription, isFalse);
    expect(
      policy(
        preferences: preferences,
        kind: EventNotificationKind.favoriteChanged,
        localNow: DateTime(2026, 8, 18, 12),
        deliveredToday: 0,
        alreadyDelivered: false,
      ).suppressionReason,
      NotificationSuppressionReason.disabled,
    );
  });

  test('allows an opted-in, unique notification during the day', () {
    final decision = policy(
      preferences: optedIn,
      kind: EventNotificationKind.favoriteStartingSoon,
      localNow: DateTime(2026, 8, 18, 12),
      deliveredToday: 2,
      alreadyDelivered: false,
    );

    expect(decision.shouldSend, isTrue);
  });

  test('suppresses duplicates before consuming the daily allowance', () {
    final decision = policy(
      preferences: optedIn,
      kind: EventNotificationKind.favoriteChanged,
      localNow: DateTime(2026, 8, 18, 12),
      deliveredToday: 0,
      alreadyDelivered: true,
    );

    expect(decision.suppressionReason, NotificationSuppressionReason.duplicate);
  });

  test('enforces overnight quiet hours at both ends of midnight', () {
    for (final hour in [22, 23, 0, 7]) {
      final decision = policy(
        preferences: optedIn,
        kind: EventNotificationKind.recommendationsDigest,
        localNow: DateTime(2026, 8, 18, hour),
        deliveredToday: 0,
        alreadyDelivered: false,
      );
      expect(
        decision.suppressionReason,
        NotificationSuppressionReason.quietHours,
        reason: 'hour $hour',
      );
    }
  });

  test('caps deliveries at three per local day', () {
    final decision = policy(
      preferences: optedIn,
      kind: EventNotificationKind.favoriteChanged,
      localNow: DateTime(2026, 8, 18, 12),
      deliveredToday: 3,
      alreadyDelivered: false,
    );

    expect(
      decision.suppressionReason,
      NotificationSuppressionReason.dailyLimit,
    );
  });
}
