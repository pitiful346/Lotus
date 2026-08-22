import 'event_category.dart';
import 'event_organizer.dart';

/// The lifecycle status of an event teaser.
enum TeaserStatus {
  draft,
  published,
  revealed,
  expired,
  cancelled;

  static TeaserStatus fromString(String? value) => switch (value?.trim().toUpperCase()) {
        'PUBLISHED' || 'TEASER_ACTIVE' || 'ACTIVE' => TeaserStatus.published,
        'REVEALED' => TeaserStatus.revealed,
        'EXPIRED' => TeaserStatus.expired,
        'CANCELLED' => TeaserStatus.cancelled,
        _ => TeaserStatus.draft,
      };

  String get wireName => switch (this) {
        TeaserStatus.draft => 'DRAFT',
        TeaserStatus.published => 'PUBLISHED',
        TeaserStatus.revealed => 'REVEALED',
        TeaserStatus.expired => 'EXPIRED',
        TeaserStatus.cancelled => 'CANCELLED',
      };
}

/// A secret or preview teaser for an event before full publication.
class Teaser {
  const Teaser({
    required this.id,
    this.title,
    required this.description,
    this.imageUri,
    this.organizer,
    this.category,
    this.city,
    this.approximateDate,
    required this.revealAt,
    this.status = TeaserStatus.published,
    this.targetEventId,
    this.trackerCount = 0,
    this.createdAt,
  });

  /// The unique document identifier (e.g. `teasers/teaser_123`).
  final String id;

  /// Optional teaser name or codename (e.g. "Projeto X" or null for full mystery).
  final String? title;

  /// Enigmatic hint or description of what is coming.
  final String description;

  /// Artwork or teaser poster image.
  final Uri? imageUri;

  /// The promoter or organization hosting the secret event.
  final EventOrganizer? organizer;

  /// Musical or cultural category for this teaser.
  final EventCategory? category;

  /// Approximate geographic area or city (e.g. "Porto", "Lisboa", "Costa Alentejana").
  final String? city;

  /// Approximate time frame (e.g. "Outono 2026", "Outubro 2026", "Em breve").
  final String? approximateDate;

  /// The exact timestamp when the event reveal takes place.
  final DateTime revealAt;

  /// Current status of the teaser.
  final TeaserStatus status;

  /// When revealed, the document ID of the published event (e.g. `events/event_456`).
  final String? targetEventId;

  /// Number of users tracking/following this teaser.
  final int trackerCount;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Whether the teaser has reached its reveal time or is explicitly marked revealed.
  bool get isRevealed =>
      status == TeaserStatus.revealed ||
      (status == TeaserStatus.published && !revealAt.isAfter(DateTime.now().toUtc()));

  /// Whether the teaser is currently active and awaiting reveal.
  bool get isActive =>
      status == TeaserStatus.published && revealAt.isAfter(DateTime.now().toUtc());

  /// Whether the teaser is expired or cancelled.
  bool get isExpired => status == TeaserStatus.expired;
  bool get isCancelled => status == TeaserStatus.cancelled;

  /// Human-readable title for display (fallback if title is null).
  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) return title!.trim();
    if (category != null) return 'Evento Secreto de ${category!.label}';
    if (city != null && city!.trim().isNotEmpty) return 'Evento Secreto em ${city!.trim()}';
    return 'Evento Secreto';
  }

  /// Calculates the remaining duration until reveal against a given reference time.
  Duration timeUntilReveal([DateTime? now]) {
    final reference = (now ?? DateTime.now()).toUtc();
    final difference = revealAt.difference(reference);
    return difference.isNegative ? Duration.zero : difference;
  }

  Teaser copyWith({
    String? id,
    String? title,
    String? description,
    Uri? imageUri,
    EventOrganizer? organizer,
    EventCategory? category,
    String? city,
    String? approximateDate,
    DateTime? revealAt,
    TeaserStatus? status,
    String? targetEventId,
    int? trackerCount,
    DateTime? createdAt,
  }) =>
      Teaser(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        imageUri: imageUri ?? this.imageUri,
        organizer: organizer ?? this.organizer,
        category: category ?? this.category,
        city: city ?? this.city,
        approximateDate: approximateDate ?? this.approximateDate,
        revealAt: revealAt ?? this.revealAt,
        status: status ?? this.status,
        targetEventId: targetEventId ?? this.targetEventId,
        trackerCount: trackerCount ?? this.trackerCount,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Teaser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          imageUri == other.imageUri &&
          organizer == other.organizer &&
          category == other.category &&
          city == other.city &&
          approximateDate == other.approximateDate &&
          revealAt == other.revealAt &&
          status == other.status &&
          targetEventId == other.targetEventId &&
          trackerCount == other.trackerCount &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        imageUri,
        organizer,
        category,
        city,
        approximateDate,
        revealAt,
        status,
        targetEventId,
        trackerCount,
        createdAt,
      );
}
