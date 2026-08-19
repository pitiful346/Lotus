import 'package:flutter/material.dart';

import '/custom_code/product_quality/lotus_product_quality.dart';
import 'lotus_onboarding_flow.dart';
import 'lotus_onboarding_repository.dart';

class LotusOnboardingGate extends StatefulWidget {
  const LotusOnboardingGate({
    super.key,
    required this.userId,
    required this.child,
    this.repository,
  });

  final String userId;
  final Widget child;
  final LotusOnboardingRepository? repository;

  @override
  State<LotusOnboardingGate> createState() => _LotusOnboardingGateState();
}

class _LotusOnboardingGateState extends State<LotusOnboardingGate> {
  late final LotusOnboardingRepository _repository;
  late Future<bool?> _cachedCompletion;
  bool _completedInSession = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FirestoreLotusOnboardingRepository();
    _cachedCompletion = _repository.readCachedCompletion(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    if (_completedInSession) return widget.child;
    return FutureBuilder<bool?>(
      future: _cachedCompletion,
      builder: (context, cachedSnapshot) {
        if (cachedSnapshot.connectionState == ConnectionState.waiting) {
          return const _OnboardingLoading();
        }
        final cached = cachedSnapshot.data;
        if (cached == true) return widget.child;
        return StreamBuilder<bool>(
          stream: _repository.watchCompletion(widget.userId),
          initialData: cached,
          builder: (context, snapshot) {
            if (snapshot.hasError && !snapshot.hasData) {
              return LotusStateView(
                kind: LotusStateKind.offline,
                title: 'Não foi possível preparar a app',
                message: 'Verifica a ligação e tenta novamente.',
                actionLabel: 'Tentar novamente',
                onAction: _reloadCachedCompletion,
              );
            }
            if (!snapshot.hasData) return const _OnboardingLoading();
            if (snapshot.data == true) return widget.child;
            return LotusOnboardingFlow(
              userId: widget.userId,
              repository: _repository,
              onFinished: () => setState(() => _completedInSession = true),
            );
          },
        );
      },
    );
  }

  void _reloadCachedCompletion() {
    final nextCompletion = _repository.readCachedCompletion(widget.userId);
    if (!mounted) return;
    setState(() {
      _cachedCompletion = nextCompletion;
    });
  }
}

class _OnboardingLoading extends StatelessWidget {
  const _OnboardingLoading();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF080C11),
    body: SafeArea(child: LotusSkeletonList(itemCount: 4)),
  );
}
