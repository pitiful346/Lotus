import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
final class LotusOnboardingSelection {
  const LotusOnboardingSelection({
    required this.city,
    required this.interestIds,
    required this.locationPermissionStatus,
    this.skipped = false,
  });

  final String city;
  final Set<String> interestIds;
  final String locationPermissionStatus;
  final bool skipped;
}

abstract interface class LotusOnboardingRepository {
  Future<bool?> readCachedCompletion(String userId);

  Stream<bool> watchCompletion(String userId);

  Future<void> complete(String userId, LotusOnboardingSelection selection);
}

abstract interface class LotusInitialCityRepository {
  Stream<String> watchInitialCity(String userId);

  Future<void> updateInitialCity(String userId, String city);
}

final class FirestoreLotusOnboardingRepository
    implements LotusOnboardingRepository, LotusInitialCityRepository {
  FirestoreLotusOnboardingRepository({
    FirebaseFirestore? firestore,
    Future<SharedPreferences> Function()? preferences,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _preferences = preferences ?? SharedPreferences.getInstance;

  final FirebaseFirestore _firestore;
  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<bool?> readCachedCompletion(String userId) async {
    final preferences = await _preferences();
    return preferences.getBool(_cacheKey(_validUserId(userId)));
  }

  @override
  Stream<bool> watchCompletion(String userId) {
    return _onboarding(
      _validUserId(userId),
    ).snapshots().map((snapshot) => snapshot.data()?['completed'] == true);
  }

  @override
  Stream<String> watchInitialCity(String userId) {
    return _onboarding(_validUserId(userId)).snapshots().map((snapshot) {
      final city = snapshot.data()?['city'];
      return city is String && city.trim().isNotEmpty ? city.trim() : 'Porto';
    });
  }

  @override
  Future<void> updateInitialCity(String userId, String city) async {
    final normalized = city.trim();
    if (normalized.isEmpty || normalized.length > 120) {
      throw ArgumentError.value(city, 'city', 'Invalid city.');
    }
    await _onboarding(
      _validUserId(userId),
    ).update({'city': normalized, 'updated_at': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> complete(
    String userId,
    LotusOnboardingSelection selection,
  ) async {
    final id = _validUserId(userId);
    final city = selection.city.trim();
    if (city.isEmpty || city.length > 120) {
      throw ArgumentError.value(selection.city, 'city', 'Invalid city.');
    }
    final interests = selection.interestIds
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (interests.length > 30) {
      throw ArgumentError.value(
        selection.interestIds,
        'interestIds',
        'Maximum is 30.',
      );
    }

    final batch = _firestore.batch();
    batch.set(_onboarding(id), {
      'completed': true,
      'skipped': selection.skipped,
      'city': city,
      'location_permission_status': selection.locationPermissionStatus,
      'updated_at': FieldValue.serverTimestamp(),
    });
    if (!selection.skipped) {
      batch.set(_personalization(id), {
        'interest_ids': interests.toList()..sort(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    final preferences = await _preferences();
    await preferences.setBool(_cacheKey(id), true);
  }

  DocumentReference<Map<String, dynamic>> _onboarding(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('onboarding');

  DocumentReference<Map<String, dynamic>> _personalization(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('personalization');
}

String _validUserId(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized.contains('/')) {
    throw ArgumentError.value(value, 'userId', 'Must be a document ID.');
  }
  return normalized;
}

String _cacheKey(String userId) => 'lotus.onboarding.complete.$userId';
