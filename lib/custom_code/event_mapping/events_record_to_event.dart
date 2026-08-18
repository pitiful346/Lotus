import '/backend/backend.dart';
import 'package:lotus_core/lotus_core.dart';

/// Watches legacy FlutterFlow records and exposes valid map events.
Stream<List<Event>> watchMapEvents() {
  return queryEventsRecord().map((records) {
    final events = <Event>[];
    for (final record in records) {
      final event = eventFromRecord(record);
      if (event != null && event.location.coordinates != null) {
        events.add(event);
      }
    }
    events.sort((left, right) => left.startsAt.compareTo(right.startsAt));
    return List.unmodifiable(events);
  });
}

/// Converts the generated Firestore model at the application boundary.
///
/// Invalid, archived, or undated records are omitted so a single legacy
/// document cannot prevent the remaining event views from rendering. Map
/// streams additionally omit events without coordinates.
Event? eventFromRecord(EventsRecord record, {EventOrganizer? organizer}) {
  final coordinates = record.coordenadas;
  final startsAt = record.startDate;
  final title = record.name.trim();

  if (record.isArchived || startsAt == null || title.isEmpty) {
    return null;
  }

  try {
    final categoryLabels = record.categoria
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (categoryLabels.isEmpty) {
      categoryLabels.add('Outros');
    }

    final locationName = _firstNonEmpty([
      record.location,
      record.venueName,
      'Localização não indicada',
    ]);

    return Event(
      id: record.reference.path,
      title: title,
      description: _firstNonEmpty([
        record.description,
        'Descrição não disponível.',
      ]),
      categories: categoryLabels.map(
        (label) => EventCategory(id: _categoryId(label), label: label),
      ),
      location: EventLocation(
        displayName: locationName,
        venueName: _optionalText(record.venueName),
        coordinates: coordinates == null
            ? null
            : GeoCoordinates(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude,
              ),
      ),
      startsAt: startsAt,
      endsAt: record.endDate,
      imageUri: _absoluteUri(record.image),
      price: _priceFromRecord(record),
      organizer: organizer,
      links: _linksFromRecord(record),
      status: EventStatus.published,
      ticketAvailability: _ticketAvailability(record.ticketStatus),
      isFeatured: record.isBoosted,
    );
  } on ArgumentError {
    return null;
  }
}

/// Converts the legacy user document referenced by `organizer_id`.
EventOrganizer eventOrganizerFromRecord(UsersRecord record) {
  return EventOrganizer(
    id: record.reference.path,
    name: _firstNonEmpty([record.displayName, 'Organizador']),
    imageUri: _absoluteUri(record.photoUrl),
  );
}

EventPrice _priceFromRecord(EventsRecord record) {
  if (record.hasIsFree() && record.isFree) {
    return EventPrice.free();
  }
  if (record.hasPriceMin()) {
    return EventPrice(
      currencyCode: 'EUR',
      minimumMinorUnits: (record.priceMin * 100).round(),
    );
  }
  return EventPrice.unknown();
}

List<EventLink> _linksFromRecord(EventsRecord record) {
  final ticketUri = _absoluteUri(record.ticketUrl);
  if (ticketUri == null) {
    return const [];
  }
  return [EventLink(kind: EventLinkKind.tickets, uri: ticketUri)];
}

TicketAvailability _ticketAvailability(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.contains('sold') || normalized.contains('esgot')) {
    return TicketAvailability.soldOut;
  }
  if (normalized.contains('limit') || normalized.contains('últim')) {
    return TicketAvailability.limited;
  }
  if (normalized.contains('unavailable') || normalized.contains('indispon')) {
    return TicketAvailability.unavailable;
  }
  if (normalized.contains('available') || normalized.contains('dispon')) {
    return TicketAvailability.available;
  }
  return TicketAvailability.unknown;
}

String _categoryId(String label) =>
    label.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');

String _firstNonEmpty(Iterable<String> values) =>
    values.map((value) => value.trim()).firstWhere((value) => value.isNotEmpty);

String? _optionalText(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

Uri? _absoluteUri(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && uri.isAbsolute ? uri : null;
}
