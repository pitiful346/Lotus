import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/location/user_location_controller.dart';
import 'package:lotus/custom_code/onboarding/lotus_onboarding_flow.dart';
import 'package:lotus/custom_code/onboarding/lotus_onboarding_gate.dart';
import 'package:lotus/custom_code/onboarding/lotus_onboarding_repository.dart';
import 'package:lotus/custom_code/widgets/lotus_home_experience.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  testWidgets('onboarding captures location, interests and city', (
    tester,
  ) async {
    final repository = _FakeOnboardingRepository();
    final controller = UserLocationController(
      gateway: _GrantedLocationGateway(),
    );
    addTearDown(controller.dispose);
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LotusOnboardingFlow(
          userId: 'user-1',
          repository: repository,
          locationController: controller,
          onFinished: () => finished = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-location')));
    await tester.pumpAndSettle();
    expect(find.text('Localização pronta.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Música'));
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    expect(repository.completedUserId, 'user-1');
    expect(repository.selection?.city, 'Porto');
    expect(repository.selection?.interestIds, contains('musica'));
    expect(
      repository.selection?.locationPermissionStatus,
      UserLocationStatus.available.name,
    );
    expect(repository.selection?.skipped, isFalse);
  });

  testWidgets('onboarding can be skipped explicitly', (tester) async {
    final repository = _FakeOnboardingRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: LotusOnboardingFlow(
          userId: 'user-2',
          repository: repository,
          onFinished: () {},
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('onboarding-skip')));
    await tester.pumpAndSettle();

    expect(repository.selection?.skipped, isTrue);
    expect(repository.selection?.interestIds, isEmpty);
  });

  testWidgets('completed cached onboarding opens the app immediately', (
    tester,
  ) async {
    final repository = _FakeOnboardingRepository(cachedCompletion: true);
    await tester.pumpWidget(
      MaterialApp(
        home: LotusOnboardingGate(
          userId: 'user-3',
          repository: repository,
          child: const Text('Home pronta'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Home pronta'), findsOneWidget);
    expect(find.text('A cidade acontece aqui'), findsNothing);
  });

  testWidgets(
    'retry refreshes bootstrap without returning a Future to setState',
    (tester) async {
      final repository = _FakeOnboardingRepository(streamFails: true);
      await tester.pumpWidget(
        MaterialApp(
          home: LotusOnboardingGate(
            userId: 'user-retry',
            repository: repository,
            child: const Text('Home pronta'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível preparar a app'), findsOneWidget);
      expect(repository.cachedReadCalls, 1);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(repository.cachedReadCalls, 2);
    },
  );

  test('initial city maps to a stable camera position', () {
    expect(
      lotusCoordinatesForCity('Porto').latitude,
      closeTo(41.14961, 0.00001),
    );
    expect(
      lotusCoordinatesForCity('Lisboa').longitude,
      closeTo(-9.1393, 0.0001),
    );
    expect(
      lotusCoordinatesForCity('unknown'),
      lotusCoordinatesForCity('Porto'),
    );
  });
}

final class _FakeOnboardingRepository implements LotusOnboardingRepository {
  _FakeOnboardingRepository({this.cachedCompletion, this.streamFails = false});

  final bool? cachedCompletion;
  final bool streamFails;
  String? completedUserId;
  LotusOnboardingSelection? selection;
  int cachedReadCalls = 0;

  @override
  Future<void> complete(
    String userId,
    LotusOnboardingSelection selection,
  ) async {
    completedUserId = userId;
    this.selection = selection;
  }

  @override
  Future<bool?> readCachedCompletion(String userId) async {
    cachedReadCalls += 1;
    return cachedCompletion;
  }

  @override
  Stream<bool> watchCompletion(String userId) => streamFails
      ? Stream.error(StateError('offline'))
      : Stream.value(cachedCompletion ?? false);
}

final class _GrantedLocationGateway implements UserLocationGateway {
  @override
  Future<UserLocationPermission> checkPermission() async =>
      UserLocationPermission.denied;

  @override
  Future<GeoCoordinates> getCurrentCoordinates() async =>
      GeoCoordinates(latitude: 41.14961, longitude: -8.61099);

  @override
  Future<GeoCoordinates?> getLastKnownCoordinates() async => null;

  @override
  Future<bool> isServiceEnabled() async => true;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<UserLocationPermission> requestPermission() async =>
      UserLocationPermission.granted;
}
