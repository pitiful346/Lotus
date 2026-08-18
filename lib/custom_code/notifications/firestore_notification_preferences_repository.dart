import '/backend/backend.dart';
import 'package:lotus_core/lotus_core.dart';

final class FirestoreNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  FirestoreNotificationPreferencesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Stream<NotificationPreferences> watch(String userId) {
    return _document(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      return NotificationPreferences(
        favoriteEventUpdates: data?['favorite_event_updates'] == true,
        upcomingFavoriteEvents: data?['upcoming_favorite_events'] == true,
        recommendations: data?['recommendations'] == true,
      );
    });
  }

  @override
  Future<void> save({
    required String userId,
    required NotificationPreferences preferences,
  }) {
    return _document(userId).set({
      'favorite_event_updates': preferences.favoriteEventUpdates,
      'upcoming_favorite_events': preferences.upcomingFavoriteEvents,
      'recommendations': preferences.recommendations,
      'quiet_hours_start': preferences.quietHoursStart,
      'quiet_hours_end': preferences.quietHoursEnd,
      'max_per_day': preferences.maxPerDay,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  DocumentReference<Map<String, dynamic>> _document(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty || normalized.contains('/')) {
      throw ArgumentError.value(userId, 'userId', 'Must be a document ID.');
    }
    return _firestore
        .collection('users')
        .doc(normalized)
        .collection('preferences')
        .doc('notifications');
  }
}
