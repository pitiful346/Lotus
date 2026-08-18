import '../models/notification_preferences.dart';

abstract interface class NotificationPreferencesRepository {
  Stream<NotificationPreferences> watch(String userId);

  Future<void> save({
    required String userId,
    required NotificationPreferences preferences,
  });
}
