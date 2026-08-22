import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Owns the FCM lifecycle outside generated FlutterFlow pages.
///
/// Permission is never requested from [start]. Registration only happens after
/// an explicit settings action, or silently on a later launch when permission
/// was already granted and the user still has at least one subscription.
final class FirebaseNotificationCoordinator {
  FirebaseNotificationCoordinator._();

  static final instance = FirebaseNotificationCoordinator._();

  final _foregroundMessages = StreamController<RemoteMessage>.broadcast();
  final _openedMessages = StreamController<RemoteMessage>.broadcast();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  String? _activeUserId;

  Stream<RemoteMessage> get foregroundMessages => _foregroundMessages.stream;
  Stream<RemoteMessage> get openedMessages => _openedMessages.stream;

  Future<void> start() async {
    if (kIsWeb || _authSubscription != null) return;
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      _foregroundMessages.add,
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _openedMessages.add,
    );
    _tokenSubscription = FirebaseMessaging.instance.onTokenRefresh.listen((
      token,
    ) async {
      final userId = _activeUserId;
      if (userId != null) {
        try {
          await _storeToken(userId, token);
        } catch (_) {
          // A later app start or token refresh retries the synchronization.
        }
      }
    });
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) async {
      final previousUserId = _activeUserId;
      if (previousUserId != null && previousUserId != user?.uid) {
        try {
          await FirebaseMessaging.instance.deleteToken();
        } catch (_) {
          // The server also removes invalid and stale registrations.
        }
      }
      _activeUserId = user?.uid;
      if (user != null) {
        try {
          await _refreshExistingAuthorization(user.uid);
        } catch (_) {
          // Startup must not fail when messaging or Firestore is unavailable.
        }
      }
    });
  }

  Future<RemoteMessage?> takeInitialMessage() {
    if (kIsWeb) return Future.value();
    return FirebaseMessaging.instance.getInitialMessage();
  }

  Future<bool> requestAuthorizationAndRegister(String userId) async {
    if (kIsWeb) return false;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (!_isAuthorized(settings.authorizationStatus)) return false;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return false;
    await _storeToken(userId, token);
    _activeUserId = userId;
    return true;
  }

  Future<void> unregisterCurrentDevice(String userId) async {
    if (kIsWeb) return;
    final deviceId = await _deviceId();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(deviceId)
        .delete();
    await FirebaseMessaging.instance.deleteToken();
    _activeUserId = null;
  }

  Future<void> _refreshExistingAuthorization(String userId) async {
    final preference = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('notifications')
        .get();
    final data = preference.data();
    final optedIn =
        data?['followed_promoters'] == true ||
        data?['radar_reveals'] == true ||
        data?['favorite_event_updates'] == true ||
        data?['upcoming_favorite_events'] == true ||
        data?['recommendations'] == true ||
        data?['marketing'] == true;
    if (!optedIn) return;

    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (!_isAuthorized(settings.authorizationStatus)) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) await _storeToken(userId, token);
  }

  Future<void> _storeToken(String userId, String token) async {
    final deviceId = await _deviceId();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('devices')
        .doc(deviceId)
        .set({
          'token': token,
          'platform': defaultTargetPlatform.name,
          'enabled': true,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<String> _deviceId() async {
    const key = 'lotus_notification_device_id';
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(key);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = const Uuid().v4();
    await preferences.setString(key, generated);
    return generated;
  }

  bool _isAuthorized(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _foregroundMessages.close();
    await _openedMessages.close();
  }
}
