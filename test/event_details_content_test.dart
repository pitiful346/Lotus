import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/widgets/event_details_content.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  testWidgets('complete event details expose actions and real metadata', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var shared = false;
    var favoriteToggled = false;
    var ticketsOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailsContent(
          event: _event(),
          isFavorite: false,
          onBack: () {},
          onShare: () => shared = true,
          onToggleFavorite: () => favoriteToggled = true,
          onOpenDirections: () {},
          onOpenTickets: () => ticketsOpened = true,
        ),
      ),
    );

    expect(find.text('Lotus Night'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Casa da Música'), findsOneWidget);
    expect(find.byKey(const Key('event-ticket-cta')), findsOneWidget);

    await tester.tap(find.byTooltip('Partilhar evento'));
    await tester.tap(find.byTooltip('Guardar nos favoritos'));
    await tester.tap(find.byKey(const Key('event-ticket-cta')));
    expect(shared, isTrue);
    expect(favoriteToggled, isTrue);
    expect(ticketsOpened, isTrue);

    await tester.scrollUntilVisible(
      find.text('Lotus Collective'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Lotus Collective'), findsOneWidget);
    expect(find.text('Uma noite no Porto.'), findsOneWidget);
    expect(find.textContaining('12,50'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sold out tickets keep the CTA visible but disabled', (
    tester,
  ) async {
    final soldOut = _event(ticketAvailability: TicketAvailability.soldOut);
    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailsContent(
          event: soldOut,
          isFavorite: true,
          onBack: () {},
          onShare: () {},
          onToggleFavorite: () {},
          onOpenTickets: () {},
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('event-ticket-cta')),
    );
    expect(find.text('Esgotado'), findsOneWidget);
    expect(button.onPressed, isNull);
  });

  test('price formatter handles free and ranged prices', () {
    expect(formatEventPrice(EventPrice.free()), 'Grátis');
    expect(
      formatEventPrice(
        EventPrice(
          currencyCode: 'EUR',
          minimumMinorUnits: 1250,
          maximumMinorUnits: 2000,
        ),
      ),
      allOf(contains('12,50'), contains('20,00')),
    );
  });
}

Event _event({
  TicketAvailability ticketAvailability = TicketAvailability.available,
}) {
  return Event(
    id: 'events/lotus-night',
    title: 'Lotus Night',
    description: 'Uma noite no Porto.',
    categories: [EventCategory(id: 'music', label: 'Music')],
    location: EventLocation(
      displayName: 'Avenida da Boavista, Porto',
      venueName: 'Casa da Música',
      coordinates: GeoCoordinates(latitude: 41.1588, longitude: -8.6308),
    ),
    startsAt: DateTime.utc(2026, 9, 10, 20),
    endsAt: DateTime.utc(2026, 9, 10, 23),
    price: EventPrice(currencyCode: 'EUR', minimumMinorUnits: 1250),
    organizer: EventOrganizer(id: 'users/lotus', name: 'Lotus Collective'),
    links: [
      EventLink(
        kind: EventLinkKind.tickets,
        uri: Uri.parse('https://tickets.example.com/lotus-night'),
      ),
    ],
    ticketAvailability: ticketAvailability,
  );
}
