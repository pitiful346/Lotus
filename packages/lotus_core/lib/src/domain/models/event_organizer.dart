/// Organizer identity shown with an event without coupling it to a database ID.
final class EventOrganizer {
  EventOrganizer({
    required String id,
    required String name,
    this.websiteUri,
    this.imageUri,
  }) : id = _requiredText(id, 'id'),
       name = _requiredText(name, 'name') {
    _validateAbsoluteUri(websiteUri, 'websiteUri');
    _validateAbsoluteUri(imageUri, 'imageUri');
  }

  final String id;
  final String name;
  final Uri? websiteUri;
  final Uri? imageUri;
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'Must not be empty.');
  }
  return normalized;
}

void _validateAbsoluteUri(Uri? value, String field) {
  if (value != null && !value.isAbsolute) {
    throw ArgumentError.value(value, field, 'Must be an absolute URI.');
  }
}
