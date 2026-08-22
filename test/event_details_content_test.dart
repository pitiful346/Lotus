import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lotus/custom_code/widgets/event_details_content.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_PT', null);
  });
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

  testWidgets('cancelled event displays cancellation banner and disabled action', (
    tester,
  ) async {
    final cancelled = _event(status: EventStatus.cancelled);
    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailsContent(
          event: cancelled,
          isFavorite: false,
          onBack: () {},
          onShare: () {},
          onToggleFavorite: () {},
          onOpenTickets: () {},
        ),
      ),
    );

    expect(
      find.text('Este evento foi cancelado pela organização.'),
      findsOneWidget,
    );
    expect(find.text('Evento cancelado'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('event-ticket-cta')),
    );
    expect(find.text('Cancelado'), findsOneWidget);
    expect(button.onPressed, isNull);
  });

  testWidgets('tapping organizer invokes onTapOrganizer', (tester) async {
    var organizerTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventDetailsContent(
            event: _event(),
            isFavorite: false,
            onBack: () {},
            onShare: () {},
            onToggleFavorite: () {},
            onTapOrganizer: () => organizerTapped = true,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Lotus Collective'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lotus Collective'));
    expect(organizerTapped, isTrue);
  });

  testWidgets('renders artists lineup section when available', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final eventWithArtists = _event(artists: ['DJ Vibe', 'Amelie Lens']);
    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailsContent(
          event: eventWithArtists,
          isFavorite: false,
          onBack: () {},
          onShare: () {},
          onToggleFavorite: () {},
          onOpenTickets: () {},
        ),
      ),
    );

    expect(find.text('Artistas / Lineup'), findsOneWidget);
    expect(find.text('DJ Vibe'), findsOneWidget);
    expect(find.text('Amelie Lens'), findsOneWidget);
  });

  testWidgets('omits organizer section completely when organizer is null', (
    tester,
  ) async {
    final eventWithoutOrg = _event(organizer: null);
    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailsContent(
          event: eventWithoutOrg,
          isFavorite: false,
          onBack: () {},
          onShare: () {},
          onToggleFavorite: () {},
        ),
      ),
    );

    expect(find.text('Organização'), findsNothing);
    expect(find.text('Organizador não indicado'), findsNothing);
  });

  testWidgets('renders minimum age pill when minimumAge is provided', (
    tester,
  ) async {
    final eventWithAge = _event(minimumAge: 18);
    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailsContent(
          event: eventWithAge,
          isFavorite: false,
          onBack: () {},
          onShare: () {},
          onToggleFavorite: () {},
        ),
      ),
    );

    expect(find.text('+18 anos'), findsOneWidget);
  });

  testWidgets('directions button triggers onOpenDirections', (tester) async {
    var directionsOpened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: EventDetailsContent(
          event: _event(),
          isFavorite: false,
          onBack: () {},
          onShare: () {},
          onToggleFavorite: () {},
          onOpenDirections: () => directionsOpened = true,
        ),
      ),
    );

    final directionsButton = find.text('Ver no mapa / Como chegar');
    expect(directionsButton, findsOneWidget);
    await tester.ensureVisible(directionsButton);
    await tester.pumpAndSettle();
    await tester.tap(directionsButton);
    expect(directionsOpened, isTrue);
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

const _defaultOrganizerSentinel = Object();

Event _event({
  TicketAvailability ticketAvailability = TicketAvailability.available,
  EventStatus status = EventStatus.published,
  Iterable<String> artists = const [],
  Object? organizer = _defaultOrganizerSentinel,
  int? minimumAge,
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
    organizer: identical(organizer, _defaultOrganizerSentinel)
        ? EventOrganizer(id: 'users/lotus', name: 'Lotus Collective')
        : (organizer as EventOrganizer?),
    links: [
      EventLink(
        kind: EventLinkKind.tickets,
        uri: Uri.parse('https://tickets.example.com/lotus-night'),
      ),
    ],
    status: status,
    artists: artists,
    minimumAge: minimumAge,
    ticketAvailability: ticketAvailability,
  );
}
