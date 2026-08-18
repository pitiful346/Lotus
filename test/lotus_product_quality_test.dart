import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/product_quality/lotus_product_quality.dart';

void main() {
  testWidgets('error state is exposed as an accessible live region', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LotusStateView(
            kind: LotusStateKind.error,
            title: 'Não foi possível carregar',
            message: 'Verifica a ligação e tenta novamente.',
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Não foi possível carregar. Verifica a ligação e tenta novamente.',
      ),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('state action has a minimum accessible target', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LotusStateView(
            kind: LotusStateKind.empty,
            title: 'Sem eventos',
            message: 'Ainda não existem eventos aqui.',
            actionLabel: 'Atualizar',
            onAction: () {},
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.text('Atualizar')).height,
      lessThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('animated swap honors reduced-motion preference', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: LotusAnimatedSwap(child: Text('Conteúdo')),
        ),
      ),
    );

    final switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, Duration.zero);
    expect(switcher.reverseDuration, Duration.zero);
  });

  testWidgets('skeleton exposes one loading announcement', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox(height: 400, child: LotusSkeletonList())),
      ),
    );

    expect(find.bySemanticsLabel('A carregar conteúdo'), findsOneWidget);
    expect(find.byKey(const Key('lotus-skeleton-list')), findsOneWidget);
    semantics.dispose();
  });
}
