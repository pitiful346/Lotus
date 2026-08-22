/// Organizer identity shown with an event without coupling it to a database ID.
final class EventOrganizer {
  EventOrganizer({
    required String id,
    required String name,
    this.description,
    this.legalName,
    this.websiteUri,
    this.imageUri,
    this.bannerUri,
    this.instagramUri,
    this.isVerified = false,
    this.followerCount = 0,
  }) : id = _requiredText(id, 'id'),
       name = _requiredText(name, 'name') {
    _validateAbsoluteUri(websiteUri, 'websiteUri');
    _validateAbsoluteUri(imageUri, 'imageUri');
    _validateAbsoluteUri(bannerUri, 'bannerUri');
    _validateAbsoluteUri(instagramUri, 'instagramUri');
  }

  final String id;
  final String name;
  final String? description;
  final String? legalName;
  final Uri? websiteUri;
  final Uri? imageUri;
  final Uri? bannerUri;
  final Uri? instagramUri;
  final bool isVerified;
  final int followerCount;
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
