import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/widgets/lotus_admin_screen.dart';

void main() {
  testWidgets('LotusAdminScreen renders tabs and header properly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LotusAdminScreen(
          eventsStream: Stream.value([]),
          usersStream: Stream.value([]),
        ),
      ),
    );

    expect(find.text('ADMIN'), findsOneWidget);
    expect(find.text('Lotus Backoffice'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Visão Geral'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Eventos'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Promoters'), findsOneWidget);
    expect(find.widgetWithText(Tab, 'Radar / Teasers'), findsOneWidget);
  });
}
