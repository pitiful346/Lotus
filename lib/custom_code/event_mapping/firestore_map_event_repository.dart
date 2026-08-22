import '/backend/backend.dart';
import 'package:lotus_core/lotus_core.dart';

import 'events_record_to_event.dart';

/// Firestore adapter for the legacy FlutterFlow `Events` collection.
///
/// The current export stores a GeoPoint but no geohash. Firestore can bound
/// candidates by the GeoPoint's latitude ordering; the application use case
/// then applies the exact longitude/viewport filter. The hard limit prevents
/// the Home from ever downloading the complete collection.
final class FirestoreMapEventRepository implements MapEventRepository {
  const FirestoreMapEventRepository();

  @override
  Future<List<Event>> findWithin(
    MapViewportBounds bounds, {
    required int limit,
  }) async {
    final records = await queryEventsRecordOnce(
      queryBuilder: (query) => query
          .orderBy('coordenadas')
          .startAt([GeoPoint(bounds.south, -180)])
          .endAt([GeoPoint(bounds.north, 180)]),
      limit: limit,
    );

    return List.unmodifiable(
      records
          .map(eventFromRecord)
          .whereType<Event>()
          .where((event) => event.status == EventStatus.published),
    );
  }
}
