enum EventLinkKind { tickets, website, organizer, streaming, social, other }

/// A typed external link associated with an event.
final class EventLink {
  EventLink({required this.kind, required this.uri, String? label})
    : label = _optionalText(label) {
    if (!uri.isAbsolute) {
      throw ArgumentError.value(uri, 'uri', 'Must be an absolute URI.');
    }
  }

  final EventLinkKind kind;
  final Uri uri;
  final String? label;
}

String? _optionalText(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
