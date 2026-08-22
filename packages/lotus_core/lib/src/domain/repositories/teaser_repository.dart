import '../models/teaser.dart';

/// Contract for observing and interacting with secret event teasers on Lotus Radar.
abstract interface class TeaserRepository {
  /// Watches all published active teasers, with optional category/city filtering.
  Stream<List<Teaser>> watchActiveTeasers({String? categoryId, String? city});

  /// Watches a single teaser by document ID.
  Stream<Teaser?> watchTeaser(String teaserId);

  /// Watches teasers created by a specific promoter/organizer.
  Stream<List<Teaser>> watchPromoterTeasers(String organizerId);

  /// Watches the set of teaser IDs that the given user is currently tracking.
  Stream<Set<String>> watchTrackedTeaserIds(String userId);

  /// Watches whether a specific user is tracking a specific teaser.
  Stream<bool> watchIsTrackingTeaser({
    required String userId,
    required String teaserId,
  });

  /// Watches the total count of users tracking a specific teaser.
  Stream<int> watchTeaserTrackerCount(String teaserId);

  /// Updates the tracking state for a user and teaser.
  Future<void> setTrackingTeaser({
    required String userId,
    required String teaserId,
    required bool isTracking,
  });
}
