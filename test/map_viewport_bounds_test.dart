import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  test('contains coordinates inside an ordinary viewport', () {
    final bounds = MapViewportBounds(
      south: 41.0,
      west: -8.8,
      north: 41.3,
      east: -8.4,
    );

    expect(
      bounds.contains(GeoCoordinates(latitude: 41.15, longitude: -8.61)),
      isTrue,
    );
    expect(
      bounds.contains(GeoCoordinates(latitude: 41.15, longitude: -9.0)),
      isFalse,
    );
  });

  test('supports viewports that cross the antimeridian', () {
    final bounds = MapViewportBounds(
      south: -10,
      west: 170,
      north: 10,
      east: -170,
    );

    expect(
      bounds.contains(GeoCoordinates(latitude: 0, longitude: 175)),
      isTrue,
    );
    expect(
      bounds.contains(GeoCoordinates(latitude: 0, longitude: -175)),
      isTrue,
    );
    expect(bounds.contains(GeoCoordinates(latitude: 0, longitude: 0)), isFalse);
  });

  test('rejects inverted latitude bounds', () {
    expect(
      () => MapViewportBounds(south: 42, west: -9, north: 41, east: -8),
      throwsArgumentError,
    );
  });
}
