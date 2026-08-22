import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/widgets/lotus_home_map_platform_native.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  group('Lotus Poster Marker Proximity & Stacking', () {
    test('single event creates single unstacked location group', () {
      final e1 = _createEvent('e1', lat: 41.1496, lng: -8.6109);
      final groups = groupLotusEventsByProximity([e1]);

      expect(groups.length, 1);
      expect(groups.first.events.length, 1);
      expect(groups.first.events.first.id, 'e1');

      final geojson = jsonDecode(
        buildLotusEventGroupFeatureCollection(groups, null),
      );
      final features = geojson['features'] as List;
      expect(features.length, 1);
      expect(features.first['properties']['isStacked'], false);
      expect(features.first['properties']['count'], 1);
      expect(features.first['properties']['sortKey'], 1);
    });

    test('events with nearly identical coordinates group into a stacked deck', () {
      final e1 = _createEvent('e1', lat: 41.14960, lng: -8.61090);
      final e2 = _createEvent('e2', lat: 41.14965, lng: -8.61092);
      final e3 = _createEvent('e3', lat: 41.14962, lng: -8.61089);
      final separate = _createEvent('separate', lat: 41.18000, lng: -8.65000);

      final groups = groupLotusEventsByProximity([e1, e2, e3, separate]);

      expect(groups.length, 2);
      final stacked = groups.firstWhere((g) => g.events.length == 3);
      expect(stacked.events.map((e) => e.id).toSet(), {'e1', 'e2', 'e3'});

      final geojson = jsonDecode(
        buildLotusEventGroupFeatureCollection(groups, null),
      );
      final features = geojson['features'] as List;
      final stackedFeature = features.firstWhere(
        (f) => f['properties']['isStacked'] == true,
      );
      expect(stackedFeature['properties']['count'], 3);
      expect(stackedFeature['properties']['eventIds'], ['e1', 'e2', 'e3']);
    });

    test('selected event takes top priority in feature properties and sortKey', () {
      final e1 = _createEvent('e1', lat: 41.14960, lng: -8.61090);
      final e2 = _createEvent('e2', lat: 41.14961, lng: -8.61091, isFeatured: true);

      final groups = groupLotusEventsByProximity([e1, e2]);
      final geojson = jsonDecode(
        buildLotusEventGroupFeatureCollection(groups, 'e1'),
      );
      final feature = (geojson['features'] as List).first;

      expect(feature['properties']['selected'], true);
      expect(feature['properties']['eventId'], 'e1');
      expect(feature['properties']['sortKey'], 3);
    });

    test('featured event takes priority when nothing is selected', () {
      final e1 = _createEvent('e1', lat: 41.14960, lng: -8.61090);
      final e2 = _createEvent('e2', lat: 41.14961, lng: -8.61091, isFeatured: true);

      final groups = groupLotusEventsByProximity([e1, e2]);
      final geojson = jsonDecode(
        buildLotusEventGroupFeatureCollection(groups, null),
      );
      final feature = (geojson['features'] as List).first;

      expect(feature['properties']['featured'], true);
      expect(feature['properties']['eventId'], 'e2');
      expect(feature['properties']['sortKey'], 2);
    });

    test('buildLotusPosterImageId generates unique identifiers', () {
      final e1 = _createEvent('e1', lat: 41.1496, lng: -8.6109);
      final normalId = buildLotusPosterImageId(
        e1,
        selected: false,
        featured: false,
        stackedCount: 1,
      );
      final selectedId = buildLotusPosterImageId(
        e1,
        selected: true,
        featured: false,
        stackedCount: 1,
      );
      final featuredId = buildLotusPosterImageId(
        e1,
        selected: false,
        featured: true,
        stackedCount: 1,
      );
      final stackedId = buildLotusPosterImageId(
        e1,
        selected: false,
        featured: false,
        stackedCount: 3,
      );

      expect(normalId, isNot(selectedId));
      expect(normalId, isNot(featuredId));
      expect(normalId, isNot(stackedId));
      expect(selectedId.contains('-selected'), true);
      expect(featuredId.contains('-featured'), true);
      expect(stackedId.contains('-stack3'), true);
    });
  });
}

Event _createEvent(
  String id, {
  required double lat,
  required double lng,
  bool isFeatured = false,
}) {
  return Event(
    id: id,
    title: 'Event $id',
    description: 'Description for $id',
    categories: [EventCategory(id: 'music', label: 'Music')],
    location: EventLocation(
      displayName: 'Porto',
      coordinates: GeoCoordinates(latitude: lat, longitude: lng),
    ),
    startsAt: DateTime.utc(2026, 9, 10, 22, 0),
    isFeatured: isFeatured,
    imageUri: Uri.parse('https://example.com/poster_$id.jpg'),
  );
}
