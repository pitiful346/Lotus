import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/widgets/event_filter_sheet.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  testWidgets('filter sheet exposes all requested presets', (tester) async {
    await _setLargeSurface(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventFilterSheet(
            initialFilters: EventFilters(),
            hasUserLocation: false,
          ),
        ),
      ),
    );

    for (final label in [
      'Hoje',
      'Amanhã',
      'Este fim de semana',
      'Música',
      'Festas',
      'Cultura',
      'Desporto',
      'Gratuitos',
      'Distância máxima',
      'Preço máximo',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.text('Ativa a localização para filtrar por distância.'),
      findsOneWidget,
    );
  });

  testWidgets('applies date, category, free, distance, and price choices', (
    tester,
  ) async {
    await _setLargeSurface(tester);
    EventFilters? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await showModalBottomSheet<EventFilters>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => EventFilterSheet(
                    initialFilters: EventFilters(),
                    hasUserLocation: true,
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoje'));
    await tester.tap(find.text('Música'));
    await tester.tap(find.text('Gratuitos'));
    await tester.tap(find.text('5 km'));
    await tester.tap(find.text('Até 20 €'));
    await tester.tap(find.byKey(const Key('apply-event-filters')));
    await tester.pumpAndSettle();

    expect(result?.date, EventDateFilter.today);
    expect(result?.categoryIds, {'musica'});
    expect(result?.freeOnly, isTrue);
    expect(result?.maximumDistanceMeters, 5000);
    expect(result?.maximumPriceMinorUnits, 2000);
  });
}

Future<void> _setLargeSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(800, 1400);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
