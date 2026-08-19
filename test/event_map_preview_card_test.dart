import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/widgets/event_map_preview_card.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  testWidgets('event preview shows metadata and opens details', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var opened = false;
    var toggledFavorite = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 500,
            child: EventMapPreviewCard(
              event: _event(),
              distanceMeters: 2340,
              isFavorite: true,
              onToggleFavorite: () => toggledFavorite = true,
              onClose: () {},
              onOpenDetails: () => opened = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Lotus Night'), findsOneWidget);
    expect(find.text('Music +1'), findsOneWidget);
    expect(find.text('Casa da Música'), findsOneWidget);
    expect(find.text('2,3 km de distância · Grátis'), findsOneWidget);
    expect(find.text('Ver evento'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('Remover dos favoritos'));
    expect(toggledFavorite, isTrue);

    await tester.tap(find.text('Ver evento'));
    expect(opened, isTrue);
  });

  test('distance formatter supports nearby and unavailable events', () {
    expect(formatEventDistance(640), '640 m de distância');
    expect(formatEventDistance(null), 'Distância indisponível');
    expect(formatEventPreviewPrice(EventPrice.free()), 'Grátis');
    expect(
      formatEventPreviewPrice(
        EventPrice(currencyCode: 'EUR', minimumMinorUnits: 1250),
      ),
      'Desde 12,50 €',
    );
  });
}

Event _event() => Event(
  id: 'events/lotus-night',
  title: 'Lotus Night',
  description: 'A night in Porto.',
  categories: [
    EventCategory(id: 'music', label: 'Music'),
    EventCategory(id: 'nightlife', label: 'Nightlife'),
  ],
  location: EventLocation(
    displayName: 'Casa da Música',
    venueName: 'Casa da Música',
    coordinates: GeoCoordinates(latitude: 41.15, longitude: -8.61),
  ),
  startsAt: DateTime.utc(2026, 9, 10, 20),
  price: EventPrice.free(),
);
