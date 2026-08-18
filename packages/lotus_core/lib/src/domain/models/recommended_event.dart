import 'event.dart';

final class RecommendedEvent {
  const RecommendedEvent({
    required this.event,
    required this.score,
    required this.reason,
  });

  final Event event;
  final double score;
  final String reason;
}
