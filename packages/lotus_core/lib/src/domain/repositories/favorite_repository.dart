/// Persistence boundary for a user's saved events.
abstract interface class FavoriteRepository {
  /// Emits all event document paths currently saved by [userId].
  Stream<Set<String>> watchFavoriteEventIds(String userId);

  /// Emits whether [eventId] is currently saved by [userId].
  Stream<bool> watchIsFavorite({
    required String userId,
    required String eventId,
  });

  /// Makes the favorite state idempotently match [isFavorite].
  Future<void> setFavorite({
    required String userId,
    required String eventId,
    required bool isFavorite,
  });
}
