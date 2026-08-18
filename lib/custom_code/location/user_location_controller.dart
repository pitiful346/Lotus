import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lotus_core/lotus_core.dart';

enum UserLocationStatus {
  idle,
  loading,
  available,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

enum UserLocationPermission { denied, deniedForever, granted }

@immutable
final class UserLocationState {
  const UserLocationState({
    this.status = UserLocationStatus.idle,
    this.coordinates,
  });

  final UserLocationStatus status;
  final GeoCoordinates? coordinates;
}

abstract interface class UserLocationGateway {
  Future<bool> isServiceEnabled();
  Future<UserLocationPermission> checkPermission();
  Future<UserLocationPermission> requestPermission();
  Future<GeoCoordinates?> getLastKnownCoordinates();
  Future<GeoCoordinates> getCurrentCoordinates();
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

final class GeolocatorUserLocationGateway implements UserLocationGateway {
  @override
  Future<UserLocationPermission> checkPermission() async {
    return _permissionFromGeolocator(await Geolocator.checkPermission());
  }

  @override
  Future<UserLocationPermission> requestPermission() async {
    return _permissionFromGeolocator(await Geolocator.requestPermission());
  }

  @override
  Future<GeoCoordinates> getCurrentCoordinates() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return _coordinatesFromPosition(position);
  }

  @override
  Future<GeoCoordinates?> getLastKnownCoordinates() async {
    final position = await Geolocator.getLastKnownPosition();
    return position == null ? null : _coordinatesFromPosition(position);
  }

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}

final class UserLocationController extends ChangeNotifier {
  UserLocationController({UserLocationGateway? gateway})
    : _gateway = gateway ?? GeolocatorUserLocationGateway();

  final UserLocationGateway _gateway;
  UserLocationState _state = const UserLocationState();
  bool _isDisposed = false;

  UserLocationState get state => _state;

  Future<UserLocationStatus> refresh({required bool requestPermission}) async {
    if (_state.status == UserLocationStatus.loading) {
      return _state.status;
    }
    _setState(
      UserLocationState(
        status: UserLocationStatus.loading,
        coordinates: _state.coordinates,
      ),
    );

    try {
      if (!await _gateway.isServiceEnabled()) {
        return _finish(UserLocationStatus.serviceDisabled);
      }

      var permission = await _gateway.checkPermission();
      if (permission == UserLocationPermission.denied && requestPermission) {
        permission = await _gateway.requestPermission();
      }
      if (permission == UserLocationPermission.deniedForever) {
        return _finish(UserLocationStatus.permissionDeniedForever);
      }
      if (permission == UserLocationPermission.denied) {
        return _finish(UserLocationStatus.permissionDenied);
      }

      GeoCoordinates coordinates;
      try {
        coordinates = await _gateway.getCurrentCoordinates();
      } on TimeoutException {
        final lastKnown = await _gateway.getLastKnownCoordinates();
        if (lastKnown == null) {
          return _finish(UserLocationStatus.unavailable);
        }
        coordinates = lastKnown;
      }
      _setState(
        UserLocationState(
          status: UserLocationStatus.available,
          coordinates: coordinates,
        ),
      );
      return UserLocationStatus.available;
    } catch (_) {
      return _finish(UserLocationStatus.unavailable);
    }
  }

  Future<bool> openRelevantSettings() {
    if (_state.status == UserLocationStatus.serviceDisabled) {
      return _gateway.openLocationSettings();
    }
    return _gateway.openAppSettings();
  }

  UserLocationStatus _finish(UserLocationStatus status) {
    _setState(UserLocationState(status: status));
    return status;
  }

  void _setState(UserLocationState value) {
    if (_isDisposed) {
      return;
    }
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

UserLocationPermission _permissionFromGeolocator(LocationPermission value) {
  return switch (value) {
    LocationPermission.always ||
    LocationPermission.whileInUse => UserLocationPermission.granted,
    LocationPermission.deniedForever => UserLocationPermission.deniedForever,
    LocationPermission.denied ||
    LocationPermission.unableToDetermine => UserLocationPermission.denied,
  };
}

GeoCoordinates _coordinatesFromPosition(Position position) {
  return GeoCoordinates(
    latitude: position.latitude,
    longitude: position.longitude,
  );
}
