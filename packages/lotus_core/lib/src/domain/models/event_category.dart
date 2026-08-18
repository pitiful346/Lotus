/// A stable category reference that can be managed outside an event document.
final class EventCategory {
  EventCategory({required String id, required String label})
    : id = _requiredText(id, 'id'),
      label = _requiredText(label, 'label');

  final String id;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EventCategory && id == other.id;

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
