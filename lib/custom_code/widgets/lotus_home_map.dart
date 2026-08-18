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
import 'package:lotus_core/lotus_core.dart';

import '../event_mapping/events_record_to_event.dart';
import '../location/user_location_controller.dart';
import 'event_map_preview_card.dart';
import 'lotus_home_map_platform_stub.dart'
    if (dart.library.io) 'lotus_home_map_platform_native.dart'
    as platform;

/// Full-screen event map used as the foundation of the Lotus Home page.
class LotusHomeMap extends StatefulWidget {
  const LotusHomeMap({
    super.key,
    this.eventStream,
    this.onEventTap,
    this.onOpenEvent,
    this.locationController,
  });

  /// Injectable for tests and future repository implementations.
  final Stream<List<Event>>? eventStream;
  final ValueChanged<Event>? onEventTap;
  final ValueChanged<Event>? onOpenEvent;
  final UserLocationController? locationController;

  @override
  State<LotusHomeMap> createState() => _LotusHomeMapState();
}

class _LotusHomeMapState extends State<LotusHomeMap> {
  late Stream<List<Event>> _eventStream;
  late UserLocationController _locationController;
  late bool _ownsLocationController;
  String? _selectedEventId;
  String? _openingEventId;
  int _centerOnUserRequest = 0;

  @override
  void initState() {
    super.initState();
    _eventStream = widget.eventStream ?? watchMapEvents();
    _attachLocationController();
  }

  @override
  void didUpdateWidget(LotusHomeMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventStream != widget.eventStream) {
      _eventStream = widget.eventStream ?? watchMapEvents();
      _selectedEventId = null;
    }
    if (oldWidget.locationController != widget.locationController) {
      _detachLocationController();
      _attachLocationController();
    }
  }

  void _attachLocationController() {
    _ownsLocationController = widget.locationController == null;
    _locationController = widget.locationController ?? UserLocationController();
    _locationController.addListener(_handleLocationChange);
    if (_supportsLocation) {
      _locationController.refresh(requestPermission: false);
    }
  }

  void _detachLocationController() {
    _locationController.removeListener(_handleLocationChange);
    if (_ownsLocationController) {
      _locationController.dispose();
    }
  }

  bool get _supportsLocation =>
      platform.isLotusHomeMapSupported || widget.locationController != null;

  void _handleLocationChange() {
    final coordinates = _locationController.state.coordinates;
    if (coordinates != null) {
      cachedUserLocation = LatLng(coordinates.latitude, coordinates.longitude);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _detachLocationController();
    super.dispose();
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
    final user = _locationController.state.coordinates;
    return user == null ? null : calculateDistanceToEvent(user, event);
  }

  Future<void> _centerOnUser() async {
    final status = await _locationController.refresh(requestPermission: true);
    if (!mounted) {
      return;
    }
    if (status == UserLocationStatus.available) {
      setState(() => _centerOnUserRequest += 1);
      return;
    }
    _showLocationProblem(status);
  }

  void _showLocationProblem(UserLocationStatus status) {
    final message = switch (status) {
      UserLocationStatus.serviceDisabled =>
        'Ativa a localização do dispositivo para veres a tua posição.',
      UserLocationStatus.permissionDenied =>
        'A permissão de localização foi recusada.',
      UserLocationStatus.permissionDeniedForever =>
        'Ativa a localização nas definições da aplicação.',
      _ => 'Não foi possível obter a tua localização atual.',
    };
    final canOpenSettings =
        status == UserLocationStatus.serviceDisabled ||
        status == UserLocationStatus.permissionDeniedForever;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: canOpenSettings
              ? SnackBarAction(
                  label: 'Definições',
                  onPressed: () {
                    _locationController.openRelevantSettings();
                  },
                )
              : null,
        ),
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
        final locationState = _locationController.state;

        return Stack(
          fit: StackFit.expand,
          children: [
            platform.buildLotusHomeMap(
              events: events,
              onEventTap: (eventId) => _selectEvent(eventId, eventsById),
              userCoordinates: locationState.coordinates,
              centerOnUserRequest: _centerOnUserRequest,
            ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const _MapLoadingIndicator(),
            if (snapshot.hasError) const _MapErrorIndicator(),
            if (_supportsLocation)
              _CenterOnUserButton(
                status: locationState.status,
                bottomInset: selectedEvent == null ? 24 : 218,
                onPressed: _centerOnUser,
              ),
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

class _CenterOnUserButton extends StatelessWidget {
  const _CenterOnUserButton({
    required this.status,
    required this.bottomInset,
    required this.onPressed,
  });

  final UserLocationStatus status;
  final double bottomInset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isLoading = status == UserLocationStatus.loading;
    final isDenied =
        status == UserLocationStatus.permissionDenied ||
        status == UserLocationStatus.permissionDeniedForever;
    return SafeArea(
      minimum: EdgeInsets.only(right: 16, bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomRight,
        child: FloatingActionButton.small(
          key: const Key('center-on-user'),
          heroTag: null,
          tooltip: 'Centrar em mim',
          onPressed: isLoading ? null : onPressed,
          backgroundColor: const Color(0xF21B2029),
          foregroundColor: const Color(0xFFB7F34A),
          disabledElevation: 2,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFB7F34A),
                  ),
                )
              : Icon(
                  isDenied
                      ? Icons.location_disabled_rounded
                      : Icons.my_location_rounded,
                ),
        ),
      ),
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
