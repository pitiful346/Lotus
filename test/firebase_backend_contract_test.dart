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
    expect(rules, contains('match /interactions/{eventId}'));
    expect(rules, contains('interactionCount(request.resource.data)'));
    expect(rules, contains('match /organizers/{organizerId}'));
    expect(rules, contains('request.auth.token.admin == true'));
    expect(rules, contains('match /{document=**}'));
  });

  test('Storage rules limit image uploads and deny unmatched paths', () {
    final rules = File('firebase/storage.rules').readAsStringSync();

    expect(rules, contains("contentType.matches('image/"));
    expect(rules, contains('request.resource.size <= maxBytes'));
    expect(rules, contains('match /{allPaths=**}'));
    expect(rules, isNot(contains('allow write: if true')));
  });
}
