enum EventInteractionType {
  viewed,
  saved,
  shared,
  directionsOpened,
  ticketOpened,
}

/// Aggregated interaction history for one user and event.
final class EventInteractionSummary {
  EventInteractionSummary({
    required String eventId,
    required Iterable<String> categoryIds,
    required this.lastType,
    required DateTime firstInteractedAt,
    required DateTime lastInteractedAt,
    this.viewCount = 0,
    this.saveCount = 0,
    this.shareCount = 0,
    this.directionsCount = 0,
    this.ticketCount = 0,
  }) : eventId = _requiredText(eventId, 'eventId'),
       categoryIds = Set.unmodifiable(_normalize(categoryIds)),
       firstInteractedAt = firstInteractedAt.toUtc(),
       lastInteractedAt = lastInteractedAt.toUtc() {
    final counts = [
      viewCount,
      saveCount,
      shareCount,
      directionsCount,
      ticketCount,
    ];
    if (counts.any((count) => count < 0)) {
      throw ArgumentError.value(counts, 'counts', 'Must be non-negative.');
    }
    if (this.lastInteractedAt.isBefore(this.firstInteractedAt)) {
      throw ArgumentError(
        'lastInteractedAt must not precede firstInteractedAt.',
      );
    }
  }

  final String eventId;
  final Set<String> categoryIds;
  final EventInteractionType lastType;
  final DateTime firstInteractedAt;
  final DateTime lastInteractedAt;
  final int viewCount;
  final int saveCount;
  final int shareCount;
  final int directionsCount;
  final int ticketCount;

  int get weightedSignal =>
      viewCount +
      (saveCount * 5) +
      (shareCount * 3) +
      (directionsCount * 2) +
      (ticketCount * 6);
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'Must not be empty.');
  }
  return normalized;
}

Iterable<String> _normalize(Iterable<String> values) sync* {
  for (final value in values) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isNotEmpty) {
      yield normalized;
    }
  }
}
