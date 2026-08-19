import 'package:lotus_core/lotus_core.dart';

import 'development_event_seed.dart';
import 'firestore_map_event_repository.dart';

const useDevelopmentEventSeed = bool.fromEnvironment(
  'LOTUS_USE_DEV_EVENTS',
  defaultValue: false,
);

bool isDevelopmentEvent(String eventId) => eventId.startsWith('dev-events/');

MapEventRepository createLotusMapEventRepository() => useDevelopmentEventSeed
    ? DevelopmentMapEventRepository()
    : const FirestoreMapEventRepository();

/// In-memory map repository. It never reads from or writes to Firebase.
final class DevelopmentMapEventRepository implements MapEventRepository {
  DevelopmentMapEventRepository({
    DateTime Function()? now,
    this.loadingDelay = const Duration(milliseconds: 280),
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Duration loadingDelay;
  List<Event>? _cachedEvents;

  List<Event> get allEvents =>
      _cachedEvents ??= buildDevelopmentEventSeed(anchor: _now());

  @override
  Future<List<Event>> findWithin(
    MapViewportBounds bounds, {
    required int limit,
  }) async {
    if (loadingDelay > Duration.zero) {
      await Future<void>.delayed(loadingDelay);
    }
    return List.unmodifiable(
      allEvents
          .where((event) {
            final coordinates = event.location.coordinates;
            return coordinates != null && bounds.contains(coordinates);
          })
          .take(limit),
    );
  }
}
