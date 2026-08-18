import 'package:flutter_test/flutter_test.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  group('Event', () {
    test('captures event data and filter dimensions', () {
      final event = Event(
        id: 'event-porto-1',
        title: 'Lotus Night',
        description: 'A night event in Porto.',
        categories: [EventCategory(id: 'music', label: 'Music')],
        location: EventLocation(
          displayName: 'Porto',
          venueName: 'Lotus Club',
          city: 'Porto',
          countryCode: 'pt',
          coordinates: GeoCoordinates(latitude: 41.14961, longitude: -8.61099),
        ),
        startsAt: DateTime.parse('2026-09-10T21:00:00+01:00'),
        endsAt: DateTime.parse('2026-09-11T02:00:00+01:00'),
        imageUri: Uri.parse('https://example.com/event.jpg'),
        price: EventPrice(
          currencyCode: 'eur',
          minimumMinorUnits: 1250,
          maximumMinorUnits: 2500,
        ),
        organizer: EventOrganizer(id: 'lotus', name: 'Lotus'),
        links: [
          EventLink(
            kind: EventLinkKind.tickets,
            uri: Uri.parse('https://example.com/tickets'),
          ),
        ],
        format: EventFormat.inPerson,
        status: EventStatus.published,
        ticketAvailability: TicketAvailability.available,
        tags: const [' Nightlife ', 'music'],
        languageCodes: const ['pt', 'EN'],
        accessibilityTags: const ['Wheelchair'],
        minimumAge: 18,
        isFeatured: true,
        popularityScore: 42,
      );

      expect(event.categoryIds, {'music'});
      expect(event.location.latitude, 41.14961);
      expect(event.location.countryCode, 'PT');
      expect(event.price.currencyCode, 'EUR');
      expect(event.tags, {'nightlife', 'music'});
      expect(event.languageCodes, {'pt', 'en'});
      expect(event.hasTickets, isTrue);
      expect(event.isFree, isFalse);
      expect(event.popularityScore, 42);
      expect(event.startsAt.isUtc, isTrue);
      expect(
        event.occursBetween(
          DateTime.utc(2026, 9, 10),
          DateTime.utc(2026, 9, 11),
        ),
        isTrue,
      );
    });

    test('protects immutable collections', () {
      final categories = [EventCategory(id: 'art', label: 'Art')];
      final event = _minimalEvent(categories: categories);

      categories.add(EventCategory(id: 'music', label: 'Music'));

      expect(event.categoryIds, {'art'});
      expect(
        () => event.categories.add(categories.last),
        throwsUnsupportedError,
      );
      expect(() => event.links.add(_ticketLink()), throwsUnsupportedError);
    });

    test('rejects an invalid schedule', () {
      expect(
        () => _minimalEvent(
          startsAt: DateTime.utc(2026, 9, 11),
          endsAt: DateTime.utc(2026, 9, 10),
        ),
        throwsArgumentError,
      );
    });
  });

  group('Event value objects', () {
    test('reject invalid coordinates', () {
      expect(
        () => GeoCoordinates(latitude: 91, longitude: -8.61),
        throwsArgumentError,
      );
    });

    test('support free and unknown prices explicitly', () {
      expect(EventPrice.free().isFree, isTrue);
      expect(EventPrice.unknown().isKnown, isFalse);
      expect(
        () => EventPrice(
          currencyCode: 'EUR',
          minimumMinorUnits: 2000,
          maximumMinorUnits: 1000,
        ),
        throwsArgumentError,
      );
    });
  });
}

Event _minimalEvent({
  List<EventCategory>? categories,
  DateTime? startsAt,
  DateTime? endsAt,
}) {
  return Event(
    id: 'event-1',
    title: 'Event',
    description: 'Description',
    categories: categories ?? [EventCategory(id: 'other', label: 'Other')],
    location: EventLocation(displayName: 'Porto'),
    startsAt: startsAt ?? DateTime.utc(2026, 9, 10),
    endsAt: endsAt,
    links: [_ticketLink()],
  );
}

EventLink _ticketLink() => EventLink(
  kind: EventLinkKind.tickets,
  uri: Uri.parse('https://example.com/tickets'),
);
