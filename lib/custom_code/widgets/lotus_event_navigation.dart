import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/event_details/event_details_widget.dart';
import 'lotus_promoter_profile_screen.dart';
import 'lotus_radar_screen.dart';
import 'lotus_teaser_details_screen.dart';

Future<void> openLotusEvent(BuildContext context, Event event) async {
  try {
    final record = await EventsRecord.getDocumentOnce(
      FirebaseFirestore.instance.doc(event.id),
    );
    if (!context.mounted) return;
    context.pushNamed(
      EventDetailsWidget.routeName,
      queryParameters: {
        'eventoAtual': serializeParam(record, ParamType.Document),
      }.withoutNulls,
      extra: <String, dynamic>{'eventoAtual': record},
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Este evento já não está disponível.')),
    );
  }
}

Future<void> openLotusPromoterProfile(
  BuildContext context, {
  EventOrganizer? organizer,
  String? organizerId,
  DocumentReference? organizerReference,
}) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => LotusPromoterProfileScreen(
        organizer: organizer,
        organizerId: organizerId,
        organizerReference: organizerReference,
      ),
    ),
  );
}

Future<void> openLotusRadar(
  BuildContext context, {
  TeaserRepository? repository,
}) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => LotusRadarScreen(
        teaserRepository: repository,
      ),
    ),
  );
}

Future<void> openLotusTeaserDetails(
  BuildContext context,
  Teaser teaser, {
  TeaserRepository? repository,
}) async {
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => LotusTeaserDetailsScreen(
        teaser: teaser,
        teaserRepository: repository,
      ),
    ),
  );
}

