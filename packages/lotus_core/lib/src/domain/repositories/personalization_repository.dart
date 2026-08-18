import '../models/event_interaction_summary.dart';

abstract interface class PersonalizationRepository {
  Stream<Set<String>> watchInterestCategoryIds(String userId);

  Future<void> setInterestCategoryIds({
    required String userId,
    required Set<String> categoryIds,
  });

  Stream<List<EventInteractionSummary>> watchInteractionHistory(
    String userId, {
    int limit = 100,
  });

  Future<void> recordInteraction({
    required String userId,
    required String eventId,
    required Set<String> categoryIds,
    required EventInteractionType type,
  });
}
