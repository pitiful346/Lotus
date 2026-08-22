import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  group('NotificationPreferences tests', () {
    test('default preferences initialize expected switches', () {
      const prefs = NotificationPreferences();

      expect(prefs.followedPromoters, isFalse);
      expect(prefs.radarReveals, isFalse);
      expect(prefs.favoriteEventUpdates, isFalse);
      expect(prefs.upcomingFavoriteEvents, isFalse);
      expect(prefs.recommendations, isFalse);
      expect(prefs.marketing, isFalse);
      expect(prefs.hasAnySubscription, isFalse);
    });

    test('allows checks all EventNotificationKind variants', () {
      const allEnabled = NotificationPreferences(
        followedPromoters: true,
        radarReveals: true,
        favoriteEventUpdates: true,
        upcomingFavoriteEvents: true,
        recommendations: true,
        marketing: true,
      );

      expect(allEnabled.allows(EventNotificationKind.promoterNewEvent), isTrue);
      expect(allEnabled.allows(EventNotificationKind.teaserRevealed), isTrue);
      expect(allEnabled.allows(EventNotificationKind.favoriteChanged), isTrue);
      expect(allEnabled.allows(EventNotificationKind.favoriteCancelled), isTrue);
      expect(allEnabled.allows(EventNotificationKind.favoriteStartingSoon), isTrue);
      expect(allEnabled.allows(EventNotificationKind.recommendationsDigest), isTrue);

      const allDisabled = NotificationPreferences(
        followedPromoters: false,
        radarReveals: false,
        favoriteEventUpdates: false,
        upcomingFavoriteEvents: false,
        recommendations: false,
        marketing: false,
      );

      expect(allDisabled.allows(EventNotificationKind.promoterNewEvent), isFalse);
      expect(allDisabled.allows(EventNotificationKind.teaserRevealed), isFalse);
      expect(allDisabled.allows(EventNotificationKind.favoriteChanged), isFalse);
      expect(allDisabled.allows(EventNotificationKind.favoriteCancelled), isFalse);
      expect(allDisabled.allows(EventNotificationKind.favoriteStartingSoon), isFalse);
      expect(allDisabled.allows(EventNotificationKind.recommendationsDigest), isFalse);
      expect(allDisabled.hasAnySubscription, isFalse);
    });

    test('copyWith properly updates specific notification toggles', () {
      const initial = NotificationPreferences(
        followedPromoters: true,
        radarReveals: true,
        marketing: false,
      );

      final updated = initial.copyWith(
        followedPromoters: false,
        marketing: true,
        recommendations: true,
      );

      expect(updated.followedPromoters, isFalse);
      expect(updated.marketing, isTrue);
      expect(updated.recommendations, isTrue);
      expect(updated.radarReveals, isTrue);
    });
  });

  group('AppNotification domain model tests', () {
    test('parses status correctly and identifies read/unread state', () {
      final unread = AppNotification(
        id: 'n1',
        title: 'Novo Evento',
        body: 'O promoter publicou um evento',
        type: 'promoter_new_event',
        status: AppNotificationStatus.fromString('UNREAD'),
        deepLink: 'lotus://event/e123',
        createdAt: DateTime(2026, 8, 21, 18, 0),
      );

      expect(unread.isUnread, isTrue);
      expect(unread.isRead, isFalse);
      expect(unread.status.wireName, 'UNREAD');

      final read = unread.copyWith(
        status: AppNotificationStatus.fromString('READ'),
        readAt: DateTime(2026, 8, 21, 18, 5),
      );

      expect(read.isRead, isTrue);
      expect(read.isUnread, isFalse);
      expect(read.status.wireName, 'READ');
      expect(read.readAt, isNotNull);
    });
  });
}
