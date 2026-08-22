/// Persistence boundary for following event organizers and promoters.
abstract interface class PromoterFollowRepository {
  /// Emits whether [organizerId] is currently followed by [userId].
  Stream<bool> watchIsFollowing({
    required String userId,
    required String organizerId,
  });

  /// Emits all organizer document IDs currently followed by [userId].
  Stream<Set<String>> watchFollowedOrganizerIds(String userId);

  /// Emits the total follower count for [organizerId].
  Stream<int> watchFollowerCount(String organizerId);

  /// Sets follow status idempotently.
  Future<void> setFollowing({
    required String userId,
    required String organizerId,
    required bool isFollowing,
  });
}
