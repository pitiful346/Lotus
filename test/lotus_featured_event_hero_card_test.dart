import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/widgets/lotus_event_tiles.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  testWidgets('LotusFeaturedEventHeroCard renders title, date, venue, and responds to tap', (
    tester,
  ) async {
    bool tapped = false;
    final event = Event(
      id: 'events/featured-1',
      title: 'Neon Odyssey Night',
      description: 'Grande noite de música eletrónica no Porto.',
      categories: [
        EventCategory(id: 'music', label: 'Música'),
      ],
      location: EventLocation(
        displayName: 'Hard Club Porto',
        city: 'Porto',
      ),
      startsAt: DateTime(2026, 8, 25, 23, 0),
      organizer: EventOrganizer(
        id: 'organizers/lotus',
        name: 'Lotus Events',
        isVerified: true,
      ),
      isFeatured: true,
      price: EventPrice(
        currencyCode: 'EUR',
        minimumMinorUnits: 1500,
        maximumMinorUnits: 1500,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: LotusFeaturedEventHeroCard(
              event: event,
              badge: '⚡ DESTAQUE LOTUS',
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Neon Odyssey Night'), findsOneWidget);
    expect(find.text('⚡ DESTAQUE LOTUS'), findsOneWidget);
    expect(find.text('Hard Club Porto'), findsOneWidget);
    expect(find.text('Lotus Events'), findsOneWidget);
    expect(find.text('Desde 15€'), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);

    await tester.tap(find.byType(LotusFeaturedEventHeroCard));
    expect(tapped, isTrue);
  });

  testWidgets('LotusFeaturedEventHeroCard renders free badge when event is free', (
    tester,
  ) async {
    final event = Event(
      id: 'events/featured-free',
      title: 'Festival ao Ar Livre',
      description: 'Entrada gratuita para todos.',
      categories: [
        EventCategory(id: 'culture', label: 'Cultura'),
      ],
      location: EventLocation(
        displayName: 'Parque da Cidade',
        city: 'Porto',
      ),
      startsAt: DateTime(2026, 8, 26, 17, 0),
      price: EventPrice.free(),
      isFeatured: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: LotusFeaturedEventHeroCard(
              event: event,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Festival ao Ar Livre'), findsOneWidget);
    expect(find.text('ENTRADA LIVRE'), findsOneWidget);
    expect(find.text('CURADORIA LOTUS'), findsOneWidget);
  });
}
