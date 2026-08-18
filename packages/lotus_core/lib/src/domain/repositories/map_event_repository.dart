import '../models/event.dart';
import '../models/map_viewport_bounds.dart';

/// Loads only event candidates relevant to a visible map area.
abstract interface class MapEventRepository {
  Future<List<Event>> findWithin(
    MapViewportBounds bounds, {
    required int limit,
  });
}
