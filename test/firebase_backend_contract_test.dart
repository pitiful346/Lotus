import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firebase deploy configuration includes database and storage rules', () {
    final config =
        jsonDecode(File('firebase/firebase.json').readAsStringSync())
            as Map<String, dynamic>;

    expect((config['firestore'] as Map)['rules'], 'firestore.rules');
    expect((config['firestore'] as Map)['indexes'], 'firestore.indexes.json');
    expect((config['storage'] as Map)['rules'], 'storage.rules');
  });

  test('Firestore rules do not contain unconditional writes', () {
    final rules = File('firebase/firestore.rules').readAsStringSync();

    expect(rules, isNot(contains('allow create: if true')));
    expect(rules, isNot(contains('allow write: if true')));
    expect(rules, contains('match /favorites/{eventId}'));
    expect(rules, contains('match /preferences/{preferenceId}'));
    expect(rules, contains("preferenceId == 'onboarding'"));
    expect(rules, contains('validOnboarding(request.resource.data)'));
    expect(rules, contains('match /interactions/{eventId}'));
    expect(rules, contains('match /devices/{deviceId}'));
    expect(rules, contains('match /notifications/{notificationId}'));
    expect(rules, contains('match /notification_queue/{notificationId}'));
    expect(rules, contains('data.max_per_day >= 1'));
    expect(rules, contains('interactionCount(request.resource.data)'));
    expect(rules, contains('match /organizers/{organizerId}'));
    expect(rules, contains('request.auth.token.admin == true'));
    expect(rules, contains('match /{document=**}'));
  });

  test('notification functions contain the anti-spam guardrails and real triggers', () {
    final functions = File('firebase/functions/index.js').readAsStringSync();

    expect(functions, contains('onEventCreated'));
    expect(functions, contains('revealScheduledTeasers'));
    expect(functions, contains('onFavoriteEventChanged'));
    expect(functions, contains('queueUpcomingFavoriteEvents'));
    expect(functions, contains('queueWeeklyRecommendations'));
    expect(functions, contains('dispatchPendingNotifications'));
    expect(functions, contains('MAX_DAILY_NOTIFICATIONS = 3'));
    expect(functions, contains('QUIET_HOURS_START = 22'));
    expect(functions, contains('crypto.createHash("sha256")'));
  });

  test('Storage rules limit image uploads and deny unmatched paths', () {
    final rules = File('firebase/storage.rules').readAsStringSync();

    expect(rules, contains("contentType.matches('image/"));
    expect(rules, contains('request.resource.size <= maxBytes'));
    expect(rules, contains('match /{allPaths=**}'));
    expect(rules, isNot(contains('allow write: if true')));
  });

  test('mobile Firestore cache is explicit and bounded', () {
    final config = File(
      'lib/backend/firebase/firebase_config.dart',
    ).readAsStringSync();

    expect(config, contains('persistenceEnabled: true'));
    expect(config, contains('cacheSizeBytes: 50 * 1024 * 1024'));
    expect(config, contains('if (kIsWeb)'));
  });
}
