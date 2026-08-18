import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/pages/home/home_widget.dart';
import 'lotus_auth_screen.dart';
import '/custom_code/onboarding/lotus_onboarding_gate.dart';

class LotusAppEntry extends StatelessWidget {
  const LotusAppEntry({super.key, required this.loggedIn});

  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (!loggedIn || userId.isEmpty) return const LotusAuthScreen();
    return LotusOnboardingGate(
      userId: userId,
      child: const HomeWidget(isScrolling: null),
    );
  }
}
