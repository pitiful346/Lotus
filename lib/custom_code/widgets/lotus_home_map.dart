// FlutterFlow keeps these imports in custom widget exports, even when a
// particular widget does not use all of them.
// ignore_for_file: unnecessary_import, unused_import

// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/pages/event_details/event_details_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lotus_core/lotus_core.dart';

import '../event_mapping/events_record_to_event.dart';
import 'event_map_preview_card.dart';
import 'lotus_home_map_platform_stub.dart'
    if (dart.library.io) 'lotus_home_map_platform_native.dart' as platform;

/// Full-screen event map used as the foundation of the Lotus Home page.
class LotusHomeMap extends StatefulWidget {
  const LotusHomeMap({
    super.key,
    this.eventStream,
    this.onEventTap,
    this.onOpenEvent,
  });

  /// Injectable for tests and future repository implementations.
  final Stream<List<Event>>? eventStream;
  final ValueChanged<Event>? onEventTap;
  final ValueChanged<Event>? onOpenEvent;

  @override
  State<LotusHomeMap> createState() => _LotusHomeMapState();
}

class _LotusHomeMapState extends State<LotusHomeMap> {
  late Stream<List<Event>> _eventStream;
  String? _selectedEventId;
  String? _openingEventId;
  GeoCoordinates? _userCoordinates;

  @override
  void initState() {
    super.initState();
    _eventStream = widget.eventStream ?? watchMapEvents();
    _loadUserCoordinates();
  }

  @override
  void didUpdateWidget(LotusHomeMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventStream != widget.eventStream) {
      _eventStream = widget.eventStream ?? watchMapEvents();
      _selectedEventId = null;
    }
  }

  Future<void> _loadUserCoordinates() async {
    final cached = cachedUserLocation;
    if (cached != null) {
      _setUserCoordinates(cached.latitude, cached.longitude);
      return;
    }

    try {
      final permission = await Geolocator.checkPermission();
      final canReadLocation = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      if (!canReadLocation || !await Geolocator.isLocationServiceEnabled()) {
        return;
      }

      final position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition().timeout(
            const Duration(seconds: 5),
          );
      _setUserCoordinates(position.latitude, position.longitude);
    } catch (_) {
      // Distance is optional; the preview remains useful without permission.
    }
  }

  void _setUserCoordinates(double latitude, double longitude) {
    if (!mounted || (latitude == 0 && longitude == 0)) {
      return;
    }
    setState(() {
      _userCoordinates = GeoCoordinates(
        latitude: latitude,
        longitude: longitude,
      );
    });
  }

  void _selectEvent(String eventId, Map<String, Event> eventsById) {
    final event = eventsById[eventId];
    if (event == null) {
      return;
    }
    setState(() => _selectedEventId = eventId);
    widget.onEventTap?.call(event);
  }

  double? _distanceTo(Event event) {
    final user = _userCoordinates;
    final eventCoordinates = event.location.coordinates;
    if (user == null || eventCoordinates == null) {
      return null;
    }
    return Geolocator.distanceBetween(
      user.latitude,
      user.longitude,
      eventCoordinates.latitude,
      eventCoordinates.longitude,
    );
  }

  Future<void> _openEventDetails(Event event) async {
    if (_openingEventId != null) {
      return;
    }
    final callback = widget.onOpenEvent;
    if (callback != null) {
      callback(event);
      return;
    }

    setState(() => _openingEventId = event.id);
    try {
      final reference = FirebaseFirestore.instance.doc(event.id);
      final record = await EventsRecord.getDocumentOnce(reference);
      if (!mounted) {
        return;
      }
      context.pushNamed(
        EventDetailsWidget.routeName,
        queryParameters: {
          'eventoAtual': serializeParam(record, ParamType.Document),
        }.withoutNulls,
        extra: <String, dynamic>{'eventoAtual': record},
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir os detalhes do evento.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _openingEventId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Event>>(
      stream: _eventStream,
      initialData: const [],
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <Event>[];
        final eventsById = {for (final event in events) event.id: event};
        final selectedEvent = eventsById[_selectedEventId];

        return Stack(
          fit: StackFit.expand,
          children: [
            platform.buildLotusHomeMap(
              events: events,
              onEventTap: (eventId) => _selectEvent(eventId, eventsById),
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const _MapLoadingIndicator(),
            if (snapshot.hasError) const _MapErrorIndicator(),
            if (selectedEvent != null)
              EventMapPreviewCard(
                event: selectedEvent,
                distanceMeters: _distanceTo(selectedEvent),
                isOpening: _openingEventId == selectedEvent.id,
                onClose: () => setState(() => _selectedEventId = null),
                onOpenDetails: () => _openEventDetails(selectedEvent),
              ),
          ],
        );
      },
    );
  }
}

class _MapLoadingIndicator extends StatelessWidget {
  const _MapLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(
            minHeight: 2,
            color: Color(0xFFB7F34A),
            backgroundColor: Color(0x33000000),
          ),
        ),
      ),
    );
  }
}

class _MapErrorIndicator extends StatelessWidget {
  const _MapErrorIndicator();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xE61B2029),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(
                'Não foi possível atualizar os eventos.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
