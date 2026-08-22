// ignore_for_file: subtype_of_sealed_class

import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/backend/backend.dart';
import 'package:lotus/custom_code/event_mapping/events_record_to_event.dart';
import 'package:lotus_core/lotus_core.dart';

void main() {
  test('maps a published EventsRecord with full fields to domain Event', () {
    final record = EventsRecord.getDocumentFromData(
      {
        'name': 'LOTUS MOBILE E2E TEST',
        'description': 'Grande concerto de teste E2E.',
        'location': 'Porto',
        'venue_name': 'Hard Club',
        'image': 'https://firebasestorage.googleapis.com/v0/b/lotus/test.jpg',
        'price_min': 15.0,
        'is_free': false,
        'ticket_status': 'AVAILABLE',
        'ticket_url': 'https://tickets.example.com/e2e',
        'categoria': ['Música & Festivais'],
        'click_count': 42,
        'is_boosted': true,
        'is_archived': false,
        'status': 'PUBLISHED',
        'coordenadas': const LatLng(41.1496, -8.6109),
        'start_date': DateTime.utc(2026, 9, 15, 21),
        'end_date': DateTime.utc(2026, 9, 16, 2),
      },
      _FakeDocumentReference('events/e2e-test-1'),
    );

    final event = eventFromRecord(record);

    expect(event, isNotNull);
    expect(event!.id, 'events/e2e-test-1');
    expect(event.title, 'LOTUS MOBILE E2E TEST');
    expect(event.description, 'Grande concerto de teste E2E.');
    expect(event.location.displayName, 'Porto');
    expect(event.location.venueName, 'Hard Club');
    expect(event.location.coordinates?.latitude, 41.1496);
    expect(event.location.coordinates?.longitude, -8.6109);
    expect(
      event.imageUri?.toString(),
      'https://firebasestorage.googleapis.com/v0/b/lotus/test.jpg',
    );
    expect(event.price.minimumMinorUnits, 1500);
    expect(event.price.isFree, isFalse);
    expect(event.status, EventStatus.published);
    expect(event.ticketAvailability, TicketAvailability.available);
    expect(event.isFeatured, isTrue);
    expect(event.popularityScore, 42);
    expect(event.startsAt, DateTime.utc(2026, 9, 15, 21));
    expect(event.endsAt, DateTime.utc(2026, 9, 16, 2));
    expect(event.hasTickets, isTrue);
  });

  test('maps CANCELLED status correctly to EventStatus.cancelled', () {
    final record = EventsRecord.getDocumentFromData(
      {
        'name': 'LOTUS MOBILE E2E TEST',
        'status': 'CANCELLED',
        'start_date': DateTime.utc(2026, 9, 15, 21),
        'is_archived': false,
      },
      _FakeDocumentReference('events/e2e-cancelled'),
    );

    final event = eventFromRecord(record);

    expect(event, isNotNull);
    expect(event!.status, EventStatus.cancelled);
  });

  test('omits DRAFT, ARCHIVED, and REJECTED events from public catalog', () {
    final draft = EventsRecord.getDocumentFromData(
      {
        'name': 'Draft Event',
        'status': 'DRAFT',
        'start_date': DateTime.utc(2026, 9, 15, 21),
        'is_archived': false,
      },
      _FakeDocumentReference('events/draft'),
    );
    final archived = EventsRecord.getDocumentFromData(
      {
        'name': 'Archived Event',
        'status': 'ARCHIVED',
        'start_date': DateTime.utc(2026, 9, 15, 21),
        'is_archived': false,
      },
      _FakeDocumentReference('events/archived'),
    );
    final isArchivedFlag = EventsRecord.getDocumentFromData(
      {
        'name': 'Is Archived Event',
        'status': 'PUBLISHED',
        'start_date': DateTime.utc(2026, 9, 15, 21),
        'is_archived': true,
      },
      _FakeDocumentReference('events/is-archived'),
    );
    final rejected = EventsRecord.getDocumentFromData(
      {
        'name': 'Rejected Event',
        'status': 'REJECTED',
        'start_date': DateTime.utc(2026, 9, 15, 21),
        'is_archived': false,
      },
      _FakeDocumentReference('events/rejected'),
    );

    expect(eventFromRecord(draft), isNull);
    expect(eventFromRecord(archived), isNull);
    expect(eventFromRecord(isArchivedFlag), isNull);
    expect(eventFromRecord(rejected), isNull);
  });

  test('handles free events and missing optional fields gracefully', () {
    final record = EventsRecord.getDocumentFromData(
      {
        'name': 'Free Community Jam',
        'is_free': true,
        'start_date': DateTime.utc(2026, 10, 1, 18),
      },
      _FakeDocumentReference('events/free-jam'),
    );

    final event = eventFromRecord(record);

    expect(event, isNotNull);
    expect(event!.price.isFree, isTrue);
    expect(event.location.coordinates, isNull);
    expect(event.imageUri, isNull);
    expect(event.categories.first.label, 'Outros');
    expect(event.hasTickets, isFalse);
    expect(event.status, EventStatus.published);
  });
}

class _FakeDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _FakeDocumentReference(this.path);

  @override
  final String path;

  @override
  String get id => path.split('/').last;
}
