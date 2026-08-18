import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/widgets/lotus_home_map.dart';
import 'package:lotus/custom_code/widgets/mapa_eventos.dart';

void main() {
  testWidgets('MapaEventos renders its placeholder', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 320, height: 480, child: MapaEventos()),
      ),
    );

    expect(find.byType(MapaEventos), findsOneWidget);
    expect(find.byType(Container), findsOneWidget);
  });

  testWidgets('LotusHomeMap has a safe fallback outside mobile', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LotusHomeMap()));

    expect(find.byType(LotusHomeMap), findsOneWidget);
    expect(
      find.text('A Home Mapbox é suportada em iOS e Android.'),
      findsOneWidget,
    );
  });
}
