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

import 'package:lotus_core/lotus_core.dart';

import '../event_mapping/events_record_to_event.dart';
import 'lotus_home_map_platform_stub.dart'
    if (dart.library.io) 'lotus_home_map_platform_native.dart'
    as platform;

/// Full-screen event map used as the foundation of the Lotus Home page.
class LotusHomeMap extends StatefulWidget {
  const LotusHomeMap({super.key, this.eventStream, this.onEventTap});

  /// Injectable for tests and future repository implementations.
  final Stream<List<Event>>? eventStream;
  final ValueChanged<Event>? onEventTap;

  @override
  State<LotusHomeMap> createState() => _LotusHomeMapState();
}

class _LotusHomeMapState extends State<LotusHomeMap> {
  late Stream<List<Event>> _eventStream;
  String? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _eventStream = widget.eventStream ?? watchMapEvents();
  }

  @override
  void didUpdateWidget(LotusHomeMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventStream != widget.eventStream) {
      _eventStream = widget.eventStream ?? watchMapEvents();
      _selectedEventId = null;
    }
  }

  void _selectEvent(String eventId, Map<String, Event> eventsById) {
    final event = eventsById[eventId];
    if (event == null) {
      return;
    }
    setState(() => _selectedEventId = eventId);
    widget.onEventTap?.call(event);
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
              _EventSelectionCard(
                event: selectedEvent,
                onClose: () => setState(() => _selectedEventId = null),
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

class _EventSelectionCard extends StatelessWidget {
  const _EventSelectionCard({required this.event, required this.onClose});

  final Event event;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final localStart = event.startsAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(localStart);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localStart),
    );

    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: const Color(0xF21B2029),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFFB7F34A)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.location.displayName} · $date, $time',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFB6C2D1)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
