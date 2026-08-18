import '../../domain/models/event.dart';
import '../../domain/models/map_viewport_bounds.dart';
import '../../domain/repositories/map_event_repository.dart';

/// Executes a bounded map search so the Home never requests every event.
final class LoadEventsInViewport {
  LoadEventsInViewport({required MapEventRepository repository})
    : _repository = repository;

  static const defaultLimit = 250;
  static const maximumLimit = 500;

  final MapEventRepository _repository;

  Future<List<Event>> call(
    MapViewportBounds bounds, {
    int limit = defaultLimit,
  }) async {
    if (limit < 1 || limit > maximumLimit) {
      throw ArgumentError.value(
        limit,
        'limit',
        'Must be between 1 and $maximumLimit.',
      );
    }
    final events = await _repository.findWithin(bounds, limit: limit);
    final insideViewport =
        events
            .where((event) {
              final coordinates = event.location.coordinates;
              return coordinates != null && bounds.contains(coordinates);
            })
            .toList(growable: false)
          ..sort((left, right) => left.startsAt.compareTo(right.startsAt));
    return List.unmodifiable(insideViewport.take(limit));
  }
}
