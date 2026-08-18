import '../../domain/models/event.dart';
import '../../domain/models/event_interaction_summary.dart';
import '../../domain/models/recommended_event.dart';

/// Transparent baseline recommender using explicit and recent user signals.
final class RecommendEvents {
  const RecommendEvents();

  List<RecommendedEvent> call({
    required Iterable<Event> candidates,
    required Set<String> interestCategoryIds,
    required Iterable<EventInteractionSummary> interactions,
    Set<String> favoriteEventIds = const {},
    DateTime? now,
    int limit = 20,
  }) {
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 100.');
    }
    final referenceTime = (now ?? DateTime.now()).toUtc();
    final candidateList = candidates.toList(growable: false);
    final interests = interestCategoryIds.map(_normalize).toSet();
    final affinities = <String, double>{};

    for (final interaction in interactions) {
      final age = referenceTime.difference(interaction.lastInteractedAt);
      final recency = age.inDays <= 7
          ? 1.0
          : age.inDays <= 30
          ? 0.65
          : 0.35;
      for (final categoryId in interaction.categoryIds) {
        affinities.update(
          _normalize(categoryId),
          (score) => score + interaction.weightedSignal * recency,
          ifAbsent: () => interaction.weightedSignal * recency,
        );
      }
    }

    // Existing favorites predate interaction tracking, so their categories
    // remain a useful positive signal during the migration.
    for (final event in candidateList.where(
      (event) => favoriteEventIds.contains(event.id),
    )) {
      for (final categoryId in event.categoryIds) {
        affinities.update(
          _normalize(categoryId),
          (score) => score + 8,
          ifAbsent: () => 8,
        );
      }
    }

    final results = <RecommendedEvent>[];
    for (final event in candidateList) {
      if ((event.endsAt ?? event.startsAt).isBefore(referenceTime) ||
          favoriteEventIds.contains(event.id)) {
        continue;
      }
      final matchingInterests = event.categoryIds
          .map(_normalize)
          .where(interests.contains)
          .toSet();
      final learnedScore = event.categoryIds.fold<double>(
        0,
        (score, categoryId) =>
            score + (affinities[_normalize(categoryId)] ?? 0),
      );
      final explicitScore = matchingInterests.length * 12.0;
      final featuredScore = event.isFeatured ? 1.0 : 0.0;
      final score = explicitScore + learnedScore + featuredScore;
      final reason = matchingInterests.isNotEmpty
          ? 'Corresponde aos teus interesses'
          : learnedScore > 0
          ? 'Baseado no que guardaste e viste'
          : event.isFeatured
          ? 'Em destaque'
          : 'A acontecer em breve';
      results.add(RecommendedEvent(event: event, score: score, reason: reason));
    }

    results.sort((left, right) {
      final scoreOrder = right.score.compareTo(left.score);
      return scoreOrder != 0
          ? scoreOrder
          : left.event.startsAt.compareTo(right.event.startsAt);
    });
    return List.unmodifiable(results.take(limit));
  }
}

String _normalize(String value) => value.trim().toLowerCase();
