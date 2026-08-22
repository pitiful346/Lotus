import 'event_category.dart';
import 'event_link.dart';
import 'event_location.dart';
import 'event_organizer.dart';
import 'event_price.dart';

enum EventFormat { inPerson, online, hybrid }

enum EventStatus { draft, published, postponed, cancelled, completed, archived }

enum TicketAvailability { unknown, available, limited, soldOut, unavailable }

/// Framework-independent representation of an event in Lotus.
final class Event {
  Event({
    required String id,
    required String title,
    required String description,
    required Iterable<EventCategory> categories,
    required this.location,
    required DateTime startsAt,
    DateTime? endsAt,
    this.imageUri,
    EventPrice? price,
    this.organizer,
    Iterable<EventLink> links = const [],
    this.format = EventFormat.inPerson,
    this.status = EventStatus.draft,
    this.ticketAvailability = TicketAvailability.unknown,
    Iterable<String> artists = const [],
    Iterable<String> tags = const [],
    Iterable<String> languageCodes = const [],
    Iterable<String> accessibilityTags = const [],
    this.minimumAge,
    this.isFeatured = false,
    this.popularityScore = 0,
    String timeZoneId = 'Europe/Lisbon',
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) : id = _requiredText(id, 'id'),
       title = _requiredText(title, 'title'),
       description = _requiredText(description, 'description'),
       categories = Set.unmodifiable(categories),
       startsAt = startsAt.toUtc(),
       endsAt = endsAt?.toUtc(),
       price = price ?? EventPrice.unknown(),
       links = List.unmodifiable(links),
       artists = List.unmodifiable(_normalizeNames(artists)),
       tags = Set.unmodifiable(_normalizeValues(tags)),
       languageCodes = Set.unmodifiable(_normalizeValues(languageCodes)),
       accessibilityTags = Set.unmodifiable(
         _normalizeValues(accessibilityTags),
       ),
       timeZoneId = _requiredText(timeZoneId, 'timeZoneId'),
       createdAt = createdAt?.toUtc(),
       updatedAt = updatedAt?.toUtc(),
       publishedAt = publishedAt?.toUtc() {
    if (this.categories.isEmpty) {
      throw ArgumentError.value(
        categories,
        'categories',
        'At least one category is required.',
      );
    }
    if (this.endsAt != null && this.endsAt!.isBefore(this.startsAt)) {
      throw ArgumentError.value(
        endsAt,
        'endsAt',
        'Must not be before startsAt.',
      );
    }
    if (minimumAge != null && minimumAge! < 0) {
      throw ArgumentError.value(
        minimumAge,
        'minimumAge',
        'Must be non-negative.',
      );
    }
    if (popularityScore < 0) {
      throw ArgumentError.value(
        popularityScore,
        'popularityScore',
        'Must be non-negative.',
      );
    }
    if (imageUri != null && !imageUri!.isAbsolute) {
      throw ArgumentError.value(
        imageUri,
        'imageUri',
        'Must be an absolute URI.',
      );
    }
  }

  final String id;
  final String title;
  final String description;
  final Set<EventCategory> categories;
  final EventLocation location;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String timeZoneId;
  final Uri? imageUri;
  final EventPrice price;
  final EventOrganizer? organizer;
  final List<EventLink> links;

  // Stable fields that can be indexed by future filter implementations.
  final EventFormat format;
  final EventStatus status;
  final TicketAvailability ticketAvailability;
  final List<String> artists;
  final Set<String> tags;
  final Set<String> languageCodes;
  final Set<String> accessibilityTags;
  final int? minimumAge;
  final bool isFeatured;
  final int popularityScore;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  Set<String> get categoryIds =>
      Set.unmodifiable(categories.map((category) => category.id));
  bool get isFree => price.isFree;
  bool get hasTickets =>
      links.any((link) => link.kind == EventLinkKind.tickets);

  bool occursBetween(DateTime from, DateTime until) {
    final rangeStart = from.toUtc();
    final rangeEnd = until.toUtc();
    if (rangeEnd.isBefore(rangeStart)) {
      throw ArgumentError('until must not be before from.');
    }

    final eventEnd = endsAt ?? startsAt;
    return !eventEnd.isBefore(rangeStart) && !startsAt.isAfter(rangeEnd);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Event && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'Must not be empty.');
  }
  return normalized;
}

Iterable<String> _normalizeValues(Iterable<String> values) sync* {
  for (final value in values) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isNotEmpty) {
      yield normalized;
    }
  }
}

Iterable<String> _normalizeNames(Iterable<String> values) sync* {
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isNotEmpty) {
      yield normalized;
    }
  }
}
