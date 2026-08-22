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

import 'package:firebase_auth/firebase_auth.dart';
import '/pages/event_details/event_details_widget.dart';
import '/pages/search/search_widget.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';
import 'dart:async';
import 'package:lotus_core/lotus_core.dart';

import '../event_mapping/firestore_favorite_repository.dart';
import '../event_mapping/firestore_map_event_repository.dart';
import '../location/user_location_controller.dart';
import 'event_filter_sheet.dart';
import 'event_map_preview_card.dart';
import 'lotus_event_tiles.dart';
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
    this.favoriteRepository,
    this.initialCenter,
  });

  /// Injectable for tests and future repository implementations.
  final Stream<List<Event>>? eventStream;
  final ValueChanged<Event>? onEventTap;
  final ValueChanged<Event>? onOpenEvent;
  final UserLocationController? locationController;
  final MapEventRepository? eventRepository;
  final FavoriteRepository? favoriteRepository;
  final GeoCoordinates? initialCenter;

  @override
  State<LotusHomeMap> createState() => _LotusHomeMapState();
}

class _LotusHomeMapState extends State<LotusHomeMap> {
  late UserLocationController _locationController;
  late bool _ownsLocationController;
  late MapEventRepository _eventRepository;
  late FavoriteRepository _favoriteRepository;
  StreamSubscription<Set<String>>? _favoritesSubscription;
  Set<String> _favoriteIds = const {};
  List<Event> _events = const [];
  MapViewportBounds? _pendingViewport;
  MapViewportBounds? _searchedViewport;
  bool _isLoadingEvents = false;
  bool _hasEventError = false;
  bool _isCenteredOnUser = false;
  int _eventRequestVersion = 0;
  EventFilters _filters = EventFilters();
  String? _selectedEventId;
  String? _openingEventId;
  String? _updatingFavoriteId;
  int _centerOnUserRequest = 0;

  @override
  void initState() {
    super.initState();
    _eventRepository =
        widget.eventRepository ?? const FirestoreMapEventRepository();
    _favoriteRepository =
        widget.favoriteRepository ?? FirestoreFavoriteRepository();
    _attachLocationController();
    _subscribeFavorites();
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
    if (oldWidget.favoriteRepository != widget.favoriteRepository) {
      _favoriteRepository =
          widget.favoriteRepository ?? FirestoreFavoriteRepository();
      _subscribeFavorites();
    }
    if (oldWidget.locationController != widget.locationController) {
      _detachLocationController();
      _attachLocationController();
    }
  }

  String get _currentUserId {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  void _subscribeFavorites() {
    _favoritesSubscription?.cancel();
    final userId = _currentUserId;
    if (userId.isNotEmpty) {
      _favoritesSubscription = _favoriteRepository
          .watchFavoriteEventIds(userId)
          .listen(
            (ids) {
              if (mounted) {
                setState(() => _favoriteIds = ids);
              }
            },
            onError: (_) {},
          );
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

  @override
  void dispose() {
    _favoritesSubscription?.cancel();
    _detachLocationController();
    super.dispose();
  }

  bool get _supportsLocation =>
      platform.isLotusHomeMapSupported || widget.locationController != null;

  void _handleLocationChange() {
    final coordinates = _locationController.state.coordinates;
    if (coordinates != null) {
      cachedUserLocation = LatLng(coordinates.latitude, coordinates.longitude);
    }
  }

  void _handleViewportChanged(MapViewportBounds bounds) {
    _pendingViewport = bounds;
    if (_events.isEmpty && !_isLoadingEvents && !_hasEventError) {
      _searchPendingViewport();
      return;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _searchPendingViewport() async {
    final bounds = _pendingViewport;
    if (bounds == null) {
      return;
    }

    final requestVersion = _eventRequestVersion + 1;
    _eventRequestVersion = requestVersion;

    setState(() {
      _isLoadingEvents = true;
      _hasEventError = false;
    });

    try {
      final events = await _eventRepository.findWithin(bounds, limit: 60);
      if (!mounted || requestVersion != _eventRequestVersion) {
        return;
      }
      setState(() {
        _events = events;
        _searchedViewport = bounds;
        _isLoadingEvents = false;
        final currentSelectionIsVisible = events.any(
          (event) => event.id == _selectedEventId,
        );
        if (!currentSelectionIsVisible) {
          _selectedEventId = null;
        }
      });
    } catch (_) {
      if (!mounted || requestVersion != _eventRequestVersion) {
        return;
      }
      setState(() {
        _isLoadingEvents = false;
        _hasEventError = true;
      });
    }
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
        _selectedEventId = null;
      });
      return;
    }
    _showLocationProblem(status);
  }

  void _showLocationProblem(UserLocationStatus status) {
    final message = switch (status) {
      UserLocationStatus.permissionDenied =>
        'Autoriza a localização para ver a tua posição no mapa.',
      UserLocationStatus.permissionDeniedForever =>
        'Ativa a localização nas definições do telemóvel.',
      UserLocationStatus.serviceDisabled =>
        'Ativa os serviços de localização do telemóvel.',
      UserLocationStatus.unavailable =>
        'Não foi possível obter a tua localização.',
      UserLocationStatus.idle ||
      UserLocationStatus.loading ||
      UserLocationStatus.available => null,
    };
    if (message == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: status == UserLocationStatus.permissionDeniedForever
            ? SnackBarAction(
                label: 'Definições',
                onPressed: _locationController.openRelevantSettings,
              )
            : null,
      ),
    );
  }

  void _selectEvent(String eventId, Map<String, Event> eventsById) {
    unawaited(LotusProductFeedback.selection());
    final event = eventsById[eventId];
    setState(() => _selectedEventId = eventId);
    if (event != null) {
      widget.onEventTap?.call(event);
    }
  }

  void _handleStackedEventsTap(
    List<String> eventIds,
    Map<String, Event> eventsById,
  ) {
    final matching =
        eventIds.map((id) => eventsById[id]).whereType<Event>().toList();
    if (matching.isEmpty) return;
    if (matching.length == 1) {
      _selectEvent(matching.first.id, eventsById);
      return;
    }
    _showEventsInAreaSheet(
      matching,
      title: 'Eventos neste local (${matching.length})',
    );
  }

  void _handleClusterAreaTap(
    GeoCoordinates coords,
    List<Event> visibleEvents,
  ) {
    final nearby = visibleEvents.where((event) {
      final c = event.location.coordinates;
      if (c == null) return false;
      final dLat = (c.latitude - coords.latitude).abs();
      final dLng = (c.longitude - coords.longitude).abs();
      return dLat < 0.003 && dLng < 0.003;
    }).toList();
    if (nearby.isNotEmpty) {
      _showEventsInAreaSheet(
        nearby,
        title: 'Eventos nesta área (${nearby.length})',
      );
    }
  }

  void _showEventsInAreaSheet(
    List<Event> eventsInArea, {
    required String title,
  }) {
    unawaited(LotusProductFeedback.selection());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EventsInAreaSheet(
        title: title,
        events: eventsInArea,
        favoriteIds: _favoriteIds,
        onToggleFavorite: _toggleFavorite,
        onSelectEvent: (event) {
          Navigator.of(context).pop();
          _selectEvent(event.id, {event.id: event});
        },
        onOpenDetails: (event) {
          Navigator.of(context).pop();
          _openEventDetails(event);
        },
      ),
    );
  }

  void _handleUserMapGesture() {
    if (mounted && _isCenteredOnUser) {
      setState(() => _isCenteredOnUser = false);
    }
  }

  void _clearSelectedEvent() {
    if (mounted && _selectedEventId != null) {
      setState(() => _selectedEventId = null);
    }
  }

  Future<void> _toggleFavorite(Event event) async {
    final userId = _currentUserId;
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sessão para guardar eventos nos favoritos.'),
        ),
      );
      return;
    }

    final isFavorite = _favoriteIds.contains(event.id);
    setState(() => _updatingFavoriteId = event.id);
    try {
      await _favoriteRepository.setFavorite(
        userId: userId,
        eventId: event.id,
        isFavorite: !isFavorite,
      );
      if (!mounted) return;
      unawaited(LotusProductFeedback.selection());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? 'Evento removido dos favoritos.'
                : 'Evento guardado nos favoritos.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      unawaited(LotusProductFeedback.error());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar os favoritos.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingFavoriteId = null);
      }
    }
  }

  Future<void> _openEventDetails(Event event) async {
    unawaited(LotusProductFeedback.selection());
    widget.onOpenEvent?.call(event);
    if (widget.onOpenEvent != null) {
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
            onMapTapEmpty: _clearSelectedEvent,
            onViewportChanged: _handleViewportChanged,
            onUserMapGesture: _handleUserMapGesture,
            selectedEventId: _selectedEventId,
            userCoordinates: locationState.coordinates,
            centerOnUserRequest: _centerOnUserRequest,
            initialCenter:
                widget.initialCenter ??
                GeoCoordinates(latitude: 41.14961, longitude: -8.61099),
            onStackedEventsTap: (ids) =>
                _handleStackedEventsTap(ids, eventsById),
            onClusterTapArea: (coords) =>
                _handleClusterAreaTap(coords, visibleEvents),
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
                  isFavorite: _favoriteIds.contains(selectedEvent.id),
                  isUpdatingFavorite: _updatingFavoriteId == selectedEvent.id,
                  bottomInset: 108,
                  onClose: _clearSelectedEvent,
                  onToggleFavorite: () => _toggleFavorite(selectedEvent),
                  onOpenDetails: () => _openEventDetails(selectedEvent),
                ),
        ),
      ],
    );
  }

  double? _distanceTo(Event event) {
    final coordinates = _locationController.state.coordinates;
    if (coordinates == null) {
      return null;
    }
    return calculateDistanceToEvent(coordinates, event);
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
          shape: const CircleBorder(
            side: BorderSide(color: Color(0x33FFFFFF)),
          ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0x33FFFFFF)),
            ),
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
        decoration: BoxDecoration(
          color: const Color(0xF21B2029),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.all(color: const Color(0x33FFFFFF)),
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
          key: const Key('search-this-area-button'),
          onPressed: onPressed,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Pesquisar nesta área'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xF21B2029),
            foregroundColor: const Color(0xFFB7F34A),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0x33FFFFFF)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    return SafeArea(
      minimum: EdgeInsets.only(right: 16, bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomRight,
        child: FloatingActionButton.small(
          key: const Key('center-on-user'),
          heroTag: null,
          tooltip: 'Centrar em mim',
          onPressed: isLoading ? null : onPressed,
          shape: const CircleBorder(
            side: BorderSide(color: Color(0x33FFFFFF)),
          ),
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
                  isActive
                      ? Icons.my_location_rounded
                      : Icons.location_searching_rounded,
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
    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 72),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFFB7F34A),
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
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        child: Material(
          color: const Color(0xF21B2029),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.signal_wifi_off_outlined,
                  color: Color(0xFFFF6B5E),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  hasCachedEvents
                      ? 'A usar eventos guardados'
                      : 'Não foi possível carregar eventos',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB7F34A),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Tentar de novo'),
                ),
              ],
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Nenhum evento encontrado nesta área.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Tentar de novo'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB7F34A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventsInAreaSheet extends StatelessWidget {
  const _EventsInAreaSheet({
    required this.title,
    required this.events,
    required this.favoriteIds,
    required this.onToggleFavorite,
    required this.onSelectEvent,
    required this.onOpenDetails,
  });

  final String title;
  final List<Event> events;
  final Set<String> favoriteIds;
  final ValueChanged<Event> onToggleFavorite;
  final ValueChanged<Event> onSelectEvent;
  final ValueChanged<Event> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151B23),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF293342)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0x4DFFFFFF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final event = events[index];
                final isFav = favoriteIds.contains(event.id);
                return LotusEventListTile(
                  event: event,
                  onTap: () => onOpenDetails(event),
                  trailing: IconButton(
                    icon: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav
                          ? const Color(0xFFFF5252)
                          : const Color(0xFF9AA8B9),
                    ),
                    onPressed: () => onToggleFavorite(event),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

