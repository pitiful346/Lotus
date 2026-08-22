import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_core/lotus_core.dart';
import 'package:lotus/custom_code/widgets/lotus_radar_screen.dart';
import 'package:lotus/custom_code/widgets/lotus_teaser_details_screen.dart';

class FakeTeaserRepository implements TeaserRepository {
  final List<Teaser> teasers;
  final Set<String> trackedIds;
  final Map<String, int> trackerCounts;

  final _teasersController = StreamController<List<Teaser>>.broadcast();
  final _trackingControllers = <String, StreamController<bool>>{};
  final _countControllers = <String, StreamController<int>>{};

  FakeTeaserRepository({
    List<Teaser>? initialTeasers,
    Set<String>? initialTrackedIds,
    Map<String, int>? initialTrackerCounts,
  })  : teasers = initialTeasers ?? [],
        trackedIds = initialTrackedIds ?? {},
        trackerCounts = initialTrackerCounts ?? {};

  @override
  Stream<List<Teaser>> watchActiveTeasers({String? categoryId, String? city}) {
    return Stream.value(
      teasers.where((t) {
        if (categoryId != null && t.category?.id != categoryId) return false;
        if (city != null && t.city?.toLowerCase() != city.toLowerCase()) return false;
        return true;
      }).toList(),
    );
  }

  @override
  Stream<Teaser?> watchTeaser(String teaserId) {
    final match = teasers.where((t) => t.id == teaserId).firstOrNull;
    return Stream.value(match);
  }

  @override
  Stream<List<Teaser>> watchPromoterTeasers(String organizerId) {
    return Stream.value(
      teasers.where((t) => t.organizer?.id == organizerId).toList(),
    );
  }

  @override
  Stream<Set<String>> watchTrackedTeaserIds(String userId) {
    return Stream.value(trackedIds);
  }

  @override
  Stream<bool> watchIsTrackingTeaser({
    required String userId,
    required String teaserId,
  }) {
    final key = '$userId:$teaserId';
    _trackingControllers.putIfAbsent(
      key,
      () => StreamController<bool>.broadcast(),
    );
    return Stream.value(trackedIds.contains(teaserId));
  }

  @override
  Stream<int> watchTeaserTrackerCount(String teaserId) {
    final count = trackerCounts[teaserId] ??
        teasers.where((t) => t.id == teaserId).firstOrNull?.trackerCount ??
        0;
    return Stream.value(count);
  }

  @override
  Future<void> setTrackingTeaser({
    required String userId,
    required String teaserId,
    required bool isTracking,
  }) async {
    if (isTracking) {
      trackedIds.add(teaserId);
      trackerCounts[teaserId] = (trackerCounts[teaserId] ?? 0) + 1;
    } else {
      trackedIds.remove(teaserId);
      trackerCounts[teaserId] = (trackerCounts[teaserId] ?? 1) - 1;
    }

    final key = '$userId:$teaserId';
    _trackingControllers[key]?.add(isTracking);
    _countControllers[teaserId]?.add(trackerCounts[teaserId] ?? 0);
  }

  void dispose() {
    _teasersController.close();
    for (final c in _trackingControllers.values) {
      c.close();
    }
    for (final c in _countControllers.values) {
      c.close();
    }
  }
}

class FakeFavoriteRepository implements FavoriteRepository {
  final Set<String> favoriteIds;
  final _controller = StreamController<Set<String>>.broadcast();

  FakeFavoriteRepository({Set<String>? initialFavoriteIds})
      : favoriteIds = initialFavoriteIds ?? {};

  @override
  Stream<Set<String>> watchFavoriteEventIds(String userId) async* {
    yield favoriteIds;
    yield* _controller.stream;
  }

  @override
  Stream<bool> watchIsFavorite({
    required String userId,
    required String eventId,
  }) async* {
    yield favoriteIds.contains(eventId);
    await for (final set in _controller.stream) {
      yield set.contains(eventId);
    }
  }

  @override
  Future<void> setFavorite({
    required String userId,
    required String eventId,
    required bool isFavorite,
  }) async {
    if (isFavorite) {
      favoriteIds.add(eventId);
    } else {
      favoriteIds.remove(eventId);
    }
    _controller.add(Set.of(favoriteIds));
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  final testOrganizer = EventOrganizer(
    id: 'organizers/org-1',
    name: 'Lotus Collective',
    isVerified: true,
  );

  final testCategory = EventCategory(
    id: 'musica',
    label: 'Música Eletrónica',
  );

  final activeTeaser = Teaser(
    id: 'teasers/secret-1',
    title: 'Projeto Eclipse',
    description: 'Um encontro sonoro exclusivo nas margens do Rio Douro.',
    organizer: testOrganizer,
    category: testCategory,
    city: 'Porto',
    approximateDate: 'Outono 2026',
    revealAt: DateTime.utc(2026, 10, 1, 20, 0),
    status: TeaserStatus.published,
    trackerCount: 42,
  );

  final revealedTeaser = Teaser(
    id: 'teasers/secret-revealed',
    title: 'Projeto Eclipse [Revelado]',
    description: 'O segredo foi revelado!',
    organizer: testOrganizer,
    category: testCategory,
    city: 'Porto',
    approximateDate: 'Outono 2026',
    revealAt: DateTime.utc(2026, 8, 1, 20, 0),
    status: TeaserStatus.revealed,
    targetEventId: 'events/eclipse-2026',
    trackerCount: 150,
  );

  final revealedEvent = Event(
    id: 'events/eclipse-2026',
    title: 'Eclipse Sound Experience',
    description: 'Edição oficial completa.',
    categories: [testCategory],
    organizer: testOrganizer,
    location: EventLocation(
      displayName: 'Alfândega do Porto, Porto',
      venueName: 'Alfândega do Porto',
      address: 'Rua Nova da Alfândega',
      city: 'Porto',
      coordinates: GeoCoordinates(latitude: 41.1435, longitude: -8.6214),
    ),
    startsAt: DateTime.utc(2026, 10, 24, 22, 0),
    price: EventPrice(
      currencyCode: 'EUR',
      minimumMinorUnits: 1500,
      maximumMinorUnits: 1500,
    ),
    status: EventStatus.published,
  );

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('LotusRadarScreen widget tests', () {
    testWidgets('renders hero section and active teasers in countdown', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(430, 932);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRepo = FakeTeaserRepository(
        initialTeasers: [activeTeaser, revealedTeaser],
      );

      await tester.pumpWidget(
        createTestWidget(
          LotusRadarScreen(
            teaserRepository: fakeRepo,
            now: () => DateTime.utc(2026, 8, 20),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RADAR LOTUS'), findsOneWidget);
      expect(find.text('EM CONTAGEM DECRESCENTE'), findsOneWidget);
      expect(find.text('Projeto Eclipse'), findsOneWidget);
      expect(find.text('REVELADOS RECENTEMENTE'), findsOneWidget);
      expect(find.text('Projeto Eclipse [Revelado]'), findsOneWidget);
    });

    testWidgets('displays empty state when no teasers exist for selected category', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(430, 932);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRepo = FakeTeaserRepository(initialTeasers: []);

      await tester.pumpWidget(
        createTestWidget(
          LotusRadarScreen(
            teaserRepository: fakeRepo,
            now: () => DateTime.utc(2026, 8, 20),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Radar sem sinais ativos'), findsOneWidget);
    });
  });

  group('LotusTeaserDetailsScreen widget tests', () {
    testWidgets('renders active teaser details, countdown, and track button', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(430, 932);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRepo = FakeTeaserRepository(
        initialTeasers: [activeTeaser],
      );

      await tester.pumpWidget(
        createTestWidget(
          LotusTeaserDetailsScreen(
            teaser: activeTeaser,
            teaserRepository: fakeRepo,
            userId: 'user-test',
            now: () => DateTime.utc(2026, 8, 20),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RADAR LOTUS'), findsOneWidget);
      expect(find.text('CONTAGEM DECRESCENTE PARA REVEAL'), findsOneWidget);
      expect(find.text('Projeto Eclipse'), findsOneWidget);
      expect(find.text('Música Eletrónica'), findsOneWidget);
      expect(find.text('Porto'), findsOneWidget);
      expect(find.text('Outono 2026'), findsOneWidget);
      expect(find.text('Lotus Collective'), findsOneWidget);
      expect(find.byKey(const Key('teaser-track-btn')), findsOneWidget);
    });

    testWidgets('allows tracking an active teaser and updates button state', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(430, 932);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRepo = FakeTeaserRepository(
        initialTeasers: [activeTeaser],
      );

      await tester.pumpWidget(
        createTestWidget(
          LotusTeaserDetailsScreen(
            teaser: activeTeaser,
            teaserRepository: fakeRepo,
            userId: 'user-test',
            now: () => DateTime.utc(2026, 8, 20),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('teaser-track-btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('teaser-track-btn')));
      await tester.pumpAndSettle();

      expect(fakeRepo.trackedIds.contains('teasers/secret-1'), isTrue);
    });

    testWidgets('renders revealed event details, favorite and share buttons when teaser is in revealed state', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(430, 932);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRepo = FakeTeaserRepository(
        initialTeasers: [revealedTeaser],
      );
      final fakeFavRepo = FakeFavoriteRepository();

      await tester.pumpWidget(
        createTestWidget(
          LotusTeaserDetailsScreen(
            teaser: revealedTeaser,
            teaserRepository: fakeRepo,
            favoriteRepository: fakeFavRepo,
            targetEvent: revealedEvent,
            userId: 'user-test',
            now: () => DateTime.utc(2026, 8, 20),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('teaser-open-event-btn')),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('REVELADO'), findsWidgets);
      expect(find.text('EVENTO OFICIAL'), findsOneWidget);
      expect(find.text('Eclipse Sound Experience'), findsOneWidget);
      expect(find.text('Alfândega do Porto, Porto'), findsOneWidget);
      expect(find.text('15,00 €'), findsOneWidget);
      expect(find.byKey(const Key('teaser-open-event-btn')), findsOneWidget);
      expect(find.byKey(const Key('teaser-favorite-btn')), findsOneWidget);
      expect(find.byKey(const Key('teaser-share-event-btn')), findsOneWidget);
    });

    testWidgets('allows favoriting a revealed event from teaser details', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(430, 932);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final fakeRepo = FakeTeaserRepository(
        initialTeasers: [revealedTeaser],
      );
      final fakeFavRepo = FakeFavoriteRepository();

      await tester.pumpWidget(
        createTestWidget(
          LotusTeaserDetailsScreen(
            teaser: revealedTeaser,
            teaserRepository: fakeRepo,
            favoriteRepository: fakeFavRepo,
            targetEvent: revealedEvent,
            userId: 'user-test',
            now: () => DateTime.utc(2026, 8, 20),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('teaser-favorite-btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('teaser-favorite-btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('teaser-favorite-btn')));
      await tester.pumpAndSettle();

      expect(fakeFavRepo.favoriteIds.contains('eclipse-2026'), isTrue);
    });

    testWidgets('transitions into revealed state live when countdown reaches revealAt', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(430, 932);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      var simulatedNow = DateTime.utc(2026, 9, 30, 23, 59, 58);
      final timingTeaser = Teaser(
        id: 'teasers/timing-1',
        title: 'Contagem Ao Vivo',
        description: 'Revelação em instantes...',
        organizer: testOrganizer,
        category: testCategory,
        revealAt: DateTime.utc(2026, 10, 1, 0, 0, 0),
        status: TeaserStatus.published,
      );

      final fakeRepo = FakeTeaserRepository(
        initialTeasers: [timingTeaser],
      );

      await tester.pumpWidget(
        createTestWidget(
          LotusTeaserDetailsScreen(
            teaser: timingTeaser,
            teaserRepository: fakeRepo,
            userId: 'user-test',
            now: () => simulatedNow,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONTAGEM DECRESCENTE PARA REVEAL'), findsOneWidget);

      // Advance time past revealAt
      simulatedNow = DateTime.utc(2026, 10, 1, 0, 0, 2);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('EVENTO REVELADO'), findsOneWidget);
      expect(find.text('O segredo foi revelado!'), findsOneWidget);
    });
  });
}
