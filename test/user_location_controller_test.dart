import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/location/user_location_controller.dart';
import 'package:lotus/custom_code/widgets/lotus_home_map.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  test('silent refresh never requests a denied permission', () async {
    final gateway = _FakeLocationGateway();
    final controller = UserLocationController(gateway: gateway);
    addTearDown(controller.dispose);

    final status = await controller.refresh(requestPermission: false);

    expect(status, UserLocationStatus.permissionDenied);
    expect(gateway.requestPermissionCalls, 0);
  });

  testWidgets(
    'center button requests permission and obtains current position',
    (tester) async {
      final gateway = _FakeLocationGateway(
        requestedPermission: UserLocationPermission.granted,
        currentCoordinates: GeoCoordinates(
          latitude: 41.14961,
          longitude: -8.61099,
        ),
      );
      final controller = UserLocationController(gateway: gateway);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LotusHomeMap(
              eventStream: Stream.value(const []),
              locationController: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final normalButton = tester.widget<FloatingActionButton>(
        find.byKey(const Key('center-on-user')),
      );
      expect(normalButton.backgroundColor, const Color(0xF21B2029));

      await tester.tap(find.byKey(const Key('center-on-user')));
      await tester.pumpAndSettle();

      expect(gateway.requestPermissionCalls, 1);
      expect(controller.state.status, UserLocationStatus.available);
      expect(controller.state.coordinates?.latitude, 41.14961);
      final activeButton = tester.widget<FloatingActionButton>(
        find.byKey(const Key('center-on-user')),
      );
      expect(activeButton.backgroundColor, const Color(0xFFB7F34A));
      expect(activeButton.foregroundColor, const Color(0xFF11161D));
    },
  );

  testWidgets('permanently denied permission offers application settings', (
    tester,
  ) async {
    final gateway = _FakeLocationGateway(
      checkedPermission: UserLocationPermission.deniedForever,
    );
    final controller = UserLocationController(gateway: gateway);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LotusHomeMap(
            eventStream: Stream.value(const []),
            locationController: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('center-on-user')));
    await tester.pumpAndSettle();
    expect(find.text('Definições'), findsOneWidget);

    await tester.tap(find.text('Definições'));
    await tester.pump();
    expect(gateway.openAppSettingsCalls, 1);
  });

  test('timeout falls back to the last known position', () async {
    final gateway = _FakeLocationGateway(
      checkedPermission: UserLocationPermission.granted,
      currentError: TimeoutException('location timeout'),
      lastKnownCoordinates: GeoCoordinates(latitude: 41.15, longitude: -8.61),
    );
    final controller = UserLocationController(gateway: gateway);
    addTearDown(controller.dispose);

    final status = await controller.refresh(requestPermission: false);

    expect(status, UserLocationStatus.available);
    expect(controller.state.coordinates, isNotNull);
  });

  test('disabled service routes the user to location settings', () async {
    final gateway = _FakeLocationGateway(serviceEnabled: false);
    final controller = UserLocationController(gateway: gateway);
    addTearDown(controller.dispose);

    final status = await controller.refresh(requestPermission: true);
    await controller.openRelevantSettings();

    expect(status, UserLocationStatus.serviceDisabled);
    expect(gateway.openLocationSettingsCalls, 1);
  });
}

final class _FakeLocationGateway implements UserLocationGateway {
  _FakeLocationGateway({
    this.serviceEnabled = true,
    this.checkedPermission = UserLocationPermission.denied,
    this.requestedPermission = UserLocationPermission.denied,
    this.currentCoordinates,
    this.lastKnownCoordinates,
    this.currentError,
  });

  final bool serviceEnabled;
  final UserLocationPermission checkedPermission;
  final UserLocationPermission requestedPermission;
  final GeoCoordinates? currentCoordinates;
  final GeoCoordinates? lastKnownCoordinates;
  final Object? currentError;
  int requestPermissionCalls = 0;
  int openAppSettingsCalls = 0;
  int openLocationSettingsCalls = 0;

  @override
  Future<UserLocationPermission> checkPermission() async => checkedPermission;

  @override
  Future<GeoCoordinates> getCurrentCoordinates() async {
    final error = currentError;
    if (error != null) {
      throw error;
    }
    return currentCoordinates!;
  }

  @override
  Future<GeoCoordinates?> getLastKnownCoordinates() async =>
      lastKnownCoordinates;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCalls += 1;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCalls += 1;
    return true;
  }

  @override
  Future<UserLocationPermission> requestPermission() async {
    requestPermissionCalls += 1;
    return requestedPermission;
  }
}
