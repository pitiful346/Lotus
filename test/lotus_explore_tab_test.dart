import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/location/user_location_controller.dart';
import 'package:lotus/custom_code/widgets/lotus_explore_tab.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  testWidgets('explore presents discovery sections without requiring the map', (
    tester,
  ) async {
    final location = UserLocationController(gateway: const _DeniedLocation());
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: LotusExploreTab(
            repository: _ExploreRepository(_events()),
            locationController: location,
            now: () => DateTime(2026, 8, 18, 12),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Explorar'), findsOneWidget);
    expect(find.byKey(const Key('explore-search')), findsOneWidget);
    expect(find.byKey(const Key('explore-radar-banner')), findsOneWidget);
    expect(find.text('Em destaque'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Hoje'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Hoje'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Perto de mim'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Perto de mim'), findsOneWidget);
    expect(find.textContaining('localização foi recusada'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Trending'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Categorias'), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    location.dispose();
  });
}

final class _ExploreRepository implements EventSearchRepository {
  const _ExploreRepository(this.events);

  final List<Event> events;

  @override
  Future<List<Event>> loadCorpus({required int limit}) async => events;
}

final class _DeniedLocation implements UserLocationGateway {
  const _DeniedLocation();

  @override
  Future<UserLocationPermission> checkPermission() async =>
      UserLocationPermission.denied;

  @override
  Future<GeoCoordinates> getCurrentCoordinates() =>
      throw UnsupportedError('Permission denied');

  @override
  Future<GeoCoordinates?> getLastKnownCoordinates() async => null;

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<bool> openAppSettings() async => false;

  @override
  Future<bool> openLocationSettings() async => false;

  @override
  Future<UserLocationPermission> requestPermission() async =>
      UserLocationPermission.denied;
}

List<Event> _events() => [
  Event(
    id: 'events/featured',
    title: 'Lotus Porto',
    description: 'Evento em destaque',
    categories: [EventCategory(id: 'musica', label: 'Música')],
    location: EventLocation(displayName: 'Porto', city: 'Porto'),
    startsAt: DateTime(2026, 8, 18, 20),
    isFeatured: true,
    popularityScore: 100,
  ),
];
