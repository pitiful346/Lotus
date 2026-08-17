import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class EventsRecord extends FirestoreRecord {
  EventsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "location" field.
  String? _location;
  String get location => _location ?? '';
  bool hasLocation() => _location != null;

  // "image" field.
  String? _image;
  String get image => _image ?? '';
  bool hasImage() => _image != null;

  // "description" field.
  String? _description;
  String get description => _description ?? '';
  bool hasDescription() => _description != null;

  // "ticket_status" field.
  String? _ticketStatus;
  String get ticketStatus => _ticketStatus ?? '';
  bool hasTicketStatus() => _ticketStatus != null;

  // "coordenadas" field.
  LatLng? _coordenadas;
  LatLng? get coordenadas => _coordenadas;
  bool hasCoordenadas() => _coordenadas != null;

  // "start_date" field.
  DateTime? _startDate;
  DateTime? get startDate => _startDate;
  bool hasStartDate() => _startDate != null;

  // "end_date" field.
  DateTime? _endDate;
  DateTime? get endDate => _endDate;
  bool hasEndDate() => _endDate != null;

  // "is_free" field.
  bool? _isFree;
  bool get isFree => _isFree ?? false;
  bool hasIsFree() => _isFree != null;

  // "price_min" field.
  double? _priceMin;
  double get priceMin => _priceMin ?? 0.0;
  bool hasPriceMin() => _priceMin != null;

  // "venue_name" field.
  String? _venueName;
  String get venueName => _venueName ?? '';
  bool hasVenueName() => _venueName != null;

  // "organizer_id" field.
  DocumentReference? _organizerId;
  DocumentReference? get organizerId => _organizerId;
  bool hasOrganizerId() => _organizerId != null;

  // "categoria" field.
  List<String>? _categoria;
  List<String> get categoria => _categoria ?? const [];
  bool hasCategoria() => _categoria != null;

  // "ticket_url" field.
  String? _ticketUrl;
  String get ticketUrl => _ticketUrl ?? '';
  bool hasTicketUrl() => _ticketUrl != null;

  // "click_count" field.
  int? _clickCount;
  int get clickCount => _clickCount ?? 0;
  bool hasClickCount() => _clickCount != null;

  // "is_boosted" field.
  bool? _isBoosted;
  bool get isBoosted => _isBoosted ?? false;
  bool hasIsBoosted() => _isBoosted != null;

  // "is_archived" field.
  bool? _isArchived;
  bool get isArchived => _isArchived ?? false;
  bool hasIsArchived() => _isArchived != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _location = snapshotData['location'] as String?;
    _image = snapshotData['image'] as String?;
    _description = snapshotData['description'] as String?;
    _ticketStatus = snapshotData['ticket_status'] as String?;
    _coordenadas = snapshotData['coordenadas'] as LatLng?;
    _startDate = snapshotData['start_date'] as DateTime?;
    _endDate = snapshotData['end_date'] as DateTime?;
    _isFree = snapshotData['is_free'] as bool?;
    _priceMin = castToType<double>(snapshotData['price_min']);
    _venueName = snapshotData['venue_name'] as String?;
    _organizerId = snapshotData['organizer_id'] as DocumentReference?;
    _categoria = getDataList(snapshotData['categoria']);
    _ticketUrl = snapshotData['ticket_url'] as String?;
    _clickCount = castToType<int>(snapshotData['click_count']);
    _isBoosted = snapshotData['is_boosted'] as bool?;
    _isArchived = snapshotData['is_archived'] as bool?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('events');

  static Stream<EventsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => EventsRecord.fromSnapshot(s));

  static Future<EventsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => EventsRecord.fromSnapshot(s));

  static EventsRecord fromSnapshot(DocumentSnapshot snapshot) => EventsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static EventsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      EventsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'EventsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is EventsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createEventsRecordData({
  String? name,
  String? location,
  String? image,
  String? description,
  String? ticketStatus,
  LatLng? coordenadas,
  DateTime? startDate,
  DateTime? endDate,
  bool? isFree,
  double? priceMin,
  String? venueName,
  DocumentReference? organizerId,
  String? ticketUrl,
  int? clickCount,
  bool? isBoosted,
  bool? isArchived,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name': name,
      'location': location,
      'image': image,
      'description': description,
      'ticket_status': ticketStatus,
      'coordenadas': coordenadas,
      'start_date': startDate,
      'end_date': endDate,
      'is_free': isFree,
      'price_min': priceMin,
      'venue_name': venueName,
      'organizer_id': organizerId,
      'ticket_url': ticketUrl,
      'click_count': clickCount,
      'is_boosted': isBoosted,
      'is_archived': isArchived,
    }.withoutNulls,
  );

  return firestoreData;
}

class EventsRecordDocumentEquality implements Equality<EventsRecord> {
  const EventsRecordDocumentEquality();

  @override
  bool equals(EventsRecord? e1, EventsRecord? e2) {
    const listEquality = ListEquality();
    return e1?.name == e2?.name &&
        e1?.location == e2?.location &&
        e1?.image == e2?.image &&
        e1?.description == e2?.description &&
        e1?.ticketStatus == e2?.ticketStatus &&
        e1?.coordenadas == e2?.coordenadas &&
        e1?.startDate == e2?.startDate &&
        e1?.endDate == e2?.endDate &&
        e1?.isFree == e2?.isFree &&
        e1?.priceMin == e2?.priceMin &&
        e1?.venueName == e2?.venueName &&
        e1?.organizerId == e2?.organizerId &&
        listEquality.equals(e1?.categoria, e2?.categoria) &&
        e1?.ticketUrl == e2?.ticketUrl &&
        e1?.clickCount == e2?.clickCount &&
        e1?.isBoosted == e2?.isBoosted &&
        e1?.isArchived == e2?.isArchived;
  }

  @override
  int hash(EventsRecord? e) => const ListEquality().hash([
        e?.name,
        e?.location,
        e?.image,
        e?.description,
        e?.ticketStatus,
        e?.coordenadas,
        e?.startDate,
        e?.endDate,
        e?.isFree,
        e?.priceMin,
        e?.venueName,
        e?.organizerId,
        e?.categoria,
        e?.ticketUrl,
        e?.clickCount,
        e?.isBoosted,
        e?.isArchived
      ]);

  @override
  bool isValidKey(Object? o) => o is EventsRecord;
}
