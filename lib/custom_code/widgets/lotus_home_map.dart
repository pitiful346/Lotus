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
import '/pages/search/search_widget.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';
import 'dart:async';
import 'package:lotus_core/lotus_core.dart';

import '../event_mapping/firestore_map_event_repository.dart';
import '../location/user_location_controller.dart';
import 'event_filter_sheet.dart';
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
    this.eventRepository,
    this.initialCenter,
  });

  /// Injectable for tests and future repository implementations.
  final Stream<List<Event>>? eventStream;
  final ValueChanged<Event>? onEventTap;
  final ValueChanged<Event>? onOpenEvent;
  final UserLocationController? locationController;
  final MapEventRepository? eventRepository;
  final GeoCoordinates? initialCenter;

  @override
  State<LotusHomeMap> createState() => _LotusHomeMapState();
}

class _LotusHomeMapState extends State<LotusHomeMap> {
  late UserLocationController _locationController;
  late bool _ownsLocationController;
  late MapEventRepository _eventRepository;
  List<Event> _events = const [];
  MapViewportBounds? _pendingViewport;
  MapViewportBounds? _searchedViewport;
  bool _isLoadingEvents = false;
  bool _hasEventError = false;
  int _eventRequestVersion = 0;
  EventFilters _filters = EventFilters();
  String? _selectedEventId;
  String? _openingEventId;
  int _centerOnUserRequest = 0;
  bool _isCenteredOnUser = false;

  @override
  void initState() {
    super.initState();
    _eventRepository =
        widget.eventRepository ?? const FirestoreMapEventRepository();
    _attachLocationController();
  }

  @override
  void didUpdateWidget(LotusHomeMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventStream != widget.eventStream) {
      _eventRequestVersion += 1;
      _isLoadingEvents = false;
      _selectedEventId = null;
    }
    if (oldWidget.eventRepository != widget.eventRepository) {
      _eventRequestVersion += 1;
      _eventRepository =
          widget.eventRepository ?? const FirestoreMapEventRepository();
      _events = const [];
      _searchedViewport = null;
      _isLoadingEvents = false;
      _hasEventError = false;
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
    unawaited(LotusProductFeedback.selection());
    setState(() => _selectedEventId = eventId);
    widget.onEventTap?.call(event);
  }

  void _handleViewportChanged(MapViewportBounds bounds) {
    if (widget.eventStream != null ||
        _pendingViewport?.isApproximatelyEqualTo(bounds) == true) {
      return;
    }
    setState(() => _pendingViewport = bounds);
    if (_searchedViewport == null && !_isLoadingEvents) {
      _searchPendingViewport();
    }
  }

  Future<void> _searchPendingViewport() async {
    final bounds = _pendingViewport;
    if (bounds == null || _isLoadingEvents) {
      return;
    }
    final requestVersion = ++_eventRequestVersion;
    setState(() {
      _isLoadingEvents = true;
      _hasEventError = false;
    });

    try {
      final events = await LoadEventsInViewport(repository: _eventRepository)(
        bounds,
      );
      if (!mounted || requestVersion != _eventRequestVersion) {
        return;
      }
      setState(() {
        _events = events;
        _searchedViewport = bounds;
        _isLoadingEvents = false;
        _selectedEventId = events.any((event) => event.id == _selectedEventId)
            ? _selectedEventId
            : null;
      });
    } catch (_) {
      if (!mounted || requestVersion != _eventRequestVersion) {
        return;
      }
      setState(() {
        _isLoadingEvents = false;
        _hasEventError = true;
      });
      unawaited(LotusProductFeedback.error());
    }
  }

  double? _distanceTo(Event event) {
    final user = _locationController.state.coordinates;
    return user == null ? null : calculateDistanceToEvent(user, event);
  }

  Future<void> _centerOnUser() async {
    unawaited(LotusProductFeedback.selection());
    final status = await _locationController.refresh(requestPermission: true);
    if (!mounted) {
      return;
    }
    if (status == UserLocationStatus.available) {
      setState(() {
        _centerOnUserRequest += 1;
        _isCenteredOnUser = true;
      });
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

  Future<void> _openFilters() async {
    unawaited(LotusProductFeedback.selection());
    final filters = await showModalBottomSheet<EventFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: EventFilterSheet(
          initialFilters: _filters,
          hasUserLocation: _locationController.state.coordinates != null,
        ),
      ),
    );
    if (!mounted || filters == null) {
      return;
    }
    setState(() {
      _filters = filters;
      _selectedEventId = null;
    });
  }

  void _clearFilters() {
    unawaited(LotusProductFeedback.selection());
    setState(() {
      _filters = EventFilters();
      _selectedEventId = null;
    });
  }

  void _openSearch() {
    unawaited(LotusProductFeedback.selection());
    context.pushNamed(SearchWidget.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final stream = widget.eventStream;
    if (stream == null) {
      return _buildMap(
        events: _events,
        isLoading: _isLoadingEvents,
        hasError: _hasEventError,
        showSearchButton: _shouldShowSearchButton,
      );
    }
    return StreamBuilder<List<Event>>(
      stream: stream,
      initialData: const [],
      builder: (context, snapshot) {
        return _buildMap(
          events: snapshot.data ?? const <Event>[],
          isLoading: snapshot.connectionState == ConnectionState.waiting,
          hasError: snapshot.hasError,
          showSearchButton: false,
        );
      },
    );
  }

  bool get _shouldShowSearchButton {
    final pending = _pendingViewport;
    final searched = _searchedViewport;
    return !_isLoadingEvents &&
        pending != null &&
        (searched == null || !pending.isApproximatelyEqualTo(searched));
  }

  Widget _buildMap({
    required List<Event> events,
    required bool isLoading,
    required bool hasError,
    required bool showSearchButton,
  }) {
    final visibleEvents = FilterEvents()(
      events,
      filters: _filters,
      now: DateTime.now(),
      userCoordinates: _locationController.state.coordinates,
    );
    final eventsById = {for (final event in visibleEvents) event.id: event};
    final selectedEvent = eventsById[_selectedEventId];
    final locationState = _locationController.state;

    return Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
          container: true,
          label: 'Mapa com ${visibleEvents.length} eventos visíveis',
          child: platform.buildLotusHomeMap(
            events: visibleEvents,
            onEventTap: (eventId) => _selectEvent(eventId, eventsById),
            onViewportChanged: _handleViewportChanged,
            onUserMapGesture: _handleUserMapGesture,
            userCoordinates: locationState.coordinates,
            centerOnUserRequest: _centerOnUserRequest,
            initialCenter:
                widget.initialCenter ??
                GeoCoordinates(latitude: 41.14961, longitude: -8.61099),
          ),
        ),
        if (isLoading) const _MapLoadingIndicator(),
        if (hasError)
          _MapErrorIndicator(
            hasCachedEvents: events.isNotEmpty,
            onRetry: _searchPendingViewport,
          ),
        if (showSearchButton)
          _SearchThisAreaButton(onPressed: _searchPendingViewport),
        _EventFiltersButton(
          activeCount: _filters.activeCount,
          topInset: showSearchButton ? 68 : 16,
          onPressed: _openFilters,
        ),
        _OpenSearchButton(
          topInset: showSearchButton ? 68 : 16,
          onPressed: _openSearch,
        ),
        if (_filters.isEmpty == false &&
            events.isNotEmpty &&
            visibleEvents.isEmpty)
          _NoFilteredEvents(onClear: _clearFilters),
        if (!isLoading &&
            !hasError &&
            events.isEmpty &&
            (_pendingViewport != null || widget.eventStream != null))
          _NoEventsInArea(onRetry: _searchPendingViewport),
        if (_supportsLocation)
          _CenterOnUserButton(
            status: locationState.status,
            isActive: _isCenteredOnUser,
            bottomInset: selectedEvent == null ? 108 : 310,
            onPressed: _centerOnUser,
          ),
        LotusAnimatedSwap(
          child: selectedEvent == null
              ? const SizedBox.shrink(key: ValueKey('no-event-preview'))
              : EventMapPreviewCard(
                  key: ValueKey(selectedEvent.id),
                  event: selectedEvent,
                  distanceMeters: _distanceTo(selectedEvent),
                  isOpening: _openingEventId == selectedEvent.id,
                  bottomInset: 108,
                  onClose: () => setState(() => _selectedEventId = null),
                  onOpenDetails: () => _openEventDetails(selectedEvent),
                ),
        ),
      ],
    );
  }

  void _handleUserMapGesture() {
    if (mounted && _isCenteredOnUser) {
      setState(() => _isCenteredOnUser = false);
    }
  }
}

class _OpenSearchButton extends StatelessWidget {
  const _OpenSearchButton({required this.topInset, required this.onPressed});

  final double topInset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.only(top: topInset, right: 16),
      child: Align(
        alignment: Alignment.topRight,
        child: FloatingActionButton.small(
          key: const Key('open-event-search'),
          heroTag: null,
          tooltip: 'Pesquisar',
          onPressed: onPressed,
          backgroundColor: const Color(0xF21B2029),
          foregroundColor: const Color(0xFFB7F34A),
          child: const Icon(Icons.search_rounded),
        ),
      ),
    );
  }
}

class _EventFiltersButton extends StatelessWidget {
  const _EventFiltersButton({
    required this.activeCount,
    required this.topInset,
    required this.onPressed,
  });

  final int activeCount;
  final double topInset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: EdgeInsets.only(top: topInset, left: 16),
      child: Align(
        alignment: Alignment.topLeft,
        child: FilledButton.icon(
          key: const Key('open-event-filters'),
          onPressed: onPressed,
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: Text(activeCount == 0 ? 'Filtros' : 'Filtros · $activeCount'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xF21B2029),
            foregroundColor: activeCount == 0
                ? Colors.white
                : const Color(0xFFB7F34A),
            elevation: 5,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          ),
        ),
      ),
    );
  }
}

class _NoFilteredEvents extends StatelessWidget {
  const _NoFilteredEvents({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xF21B2029),
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nenhum evento corresponde aos filtros.',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: onClear,
                child: const Text('Limpar filtros'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchThisAreaButton extends StatelessWidget {
  const _SearchThisAreaButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(top: 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: FilledButton.icon(
          key: const Key('search-this-area'),
          onPressed: onPressed,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Pesquisar nesta área'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xF21B2029),
            foregroundColor: Colors.white,
            elevation: 5,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          ),
        ),
      ),
    );
  }
}

class _CenterOnUserButton extends StatelessWidget {
  const _CenterOnUserButton({
    required this.status,
    required this.isActive,
    required this.bottomInset,
    required this.onPressed,
  });

  final UserLocationStatus status;
  final bool isActive;
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
          backgroundColor: isActive
              ? lotusQualityAccent
              : const Color(0xF21B2029),
          foregroundColor: isActive
              ? const Color(0xFF11161D)
              : const Color(0xFFD5DEE9),
          disabledElevation: 2,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: lotusQualityAccent,
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
    return Semantics(
      liveRegion: true,
      label: 'A atualizar eventos no mapa',
      child: const ExcludeSemantics(
        child: SafeArea(
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
        ),
      ),
    );
  }
}

class _MapErrorIndicator extends StatelessWidget {
  const _MapErrorIndicator({
    required this.hasCachedEvents,
    required this.onRetry,
  });

  final bool hasCachedEvents;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xE61B2029),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              child: Semantics(
                liveRegion: true,
                label: hasCachedEvents
                    ? 'Sem ligação. A mostrar os últimos eventos guardados.'
                    : 'Não foi possível carregar os eventos.',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        hasCachedEvents
                            ? 'Offline · a mostrar dados guardados'
                            : 'Não foi possível carregar os eventos',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: onRetry,
                      child: const Text('Repetir'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoEventsInArea extends StatelessWidget {
  const _NoEventsInArea({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 24, 24, 116),
        child: Material(
          color: const Color(0xF21B2029),
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 320,
            child: LotusStateView(
              compact: true,
              kind: LotusStateKind.empty,
              icon: Icons.location_off_outlined,
              title: 'Sem eventos nesta área',
              message: 'Move o mapa ou volta a pesquisar mais tarde.',
              actionLabel: 'Pesquisar novamente',
              onAction: onRetry,
            ),
          ),
        ),
      ),
    );
  }
}
