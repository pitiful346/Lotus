import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';

import '../onboarding/lotus_onboarding_repository.dart';
import 'lotus_home_map.dart';

class LotusHomeExperience extends StatelessWidget {
  const LotusHomeExperience({super.key, this.repository});

  final LotusInitialCityRepository? repository;

  String get _currentUserId {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId;
    if (userId.isEmpty) return const LotusHomeMap();
    final cityRepository = repository ?? FirestoreLotusOnboardingRepository();
    return StreamBuilder<String>(
      stream: cityRepository.watchInitialCity(userId),
      initialData: 'Porto',
      builder: (context, snapshot) {
        final city = snapshot.data ?? 'Porto';
        return LotusHomeMap(
          key: ValueKey('lotus-home-$city'),
          initialCenter: lotusCoordinatesForCity(city),
        );
      },
    );
  }
}

GeoCoordinates lotusCoordinatesForCity(String city) =>
    switch (city.trim().toLowerCase()) {
      'lisboa' => GeoCoordinates(latitude: 38.7223, longitude: -9.1393),
      'braga' => GeoCoordinates(latitude: 41.5454, longitude: -8.4265),
      'coimbra' => GeoCoordinates(latitude: 40.2033, longitude: -8.4103),
      'aveiro' => GeoCoordinates(latitude: 40.6405, longitude: -8.6538),
      _ => GeoCoordinates(latitude: 41.14961, longitude: -8.61099),
    };
