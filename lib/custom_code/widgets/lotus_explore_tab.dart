import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/search/search_widget.dart';
import '../event_mapping/firestore_event_search_repository.dart';
import '../event_mapping/firestore_promoter_follow_repository.dart';
import '../location/user_location_controller.dart';
import 'lotus_event_navigation.dart';
import 'lotus_event_tiles.dart';

class LotusExploreTab extends StatefulWidget {
  const LotusExploreTab({
    super.key,
    this.repository,
    this.locationController,
    this.followRepository,
    this.now,
  });

  final EventSearchRepository? repository;
  final UserLocationController? locationController;
  final PromoterFollowRepository? followRepository;
  final DateTime Function()? now;

  @override
  State<LotusExploreTab> createState() => _LotusExploreTabState();
}

class _LotusExploreTabState extends State<LotusExploreTab> {
  late EventSearchRepository _repository;
  late PromoterFollowRepository _followRepository;
  late UserLocationController _locationController;
  late bool _ownsLocationController;
  StreamSubscription<Set<String>>? _followSubscription;
  Set<String> _followedOrganizerIds = const {};
  Future<List<Event>>? _events;
  String? _categoryId;

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FirestoreEventSearchRepository();
    _followRepository =
        widget.followRepository ?? FirestorePromoterFollowRepository();
    _events = _repository.loadCorpus(limit: 80);
    _ownsLocationController = widget.locationController == null;
    _locationController = widget.locationController ?? UserLocationController();
    _locationController.addListener(_locationChanged);
    unawaited(_locationController.refresh(requestPermission: false));
    _subscribeFollowedPromoters();
  }

  void _subscribeFollowedPromoters() {
    _followSubscription?.cancel();
    final uid = currentUserUid;
    if (uid.isNotEmpty) {
      _followSubscription = _followRepository
          .watchFollowedOrganizerIds(uid)
          .listen(
            (ids) {
              if (mounted) setState(() => _followedOrganizerIds = ids);
            },
            onError: (_) {},
          );
    }
  }

  @override
  void dispose() {
    _followSubscription?.cancel();
    _locationController.removeListener(_locationChanged);
    if (_ownsLocationController) _locationController.dispose();
    super.dispose();
  }

  void _locationChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: FutureBuilder<List<Event>>(
      future: _events,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LotusSkeletonList(itemCount: 6);
        }
        if (snapshot.hasError) {
          return LotusStateView(
            kind: LotusStateKind.offline,
            title: 'Explorar está indisponível',
            message: 'Verifica a ligação e tenta novamente.',
            actionLabel: 'Tentar novamente',
            onAction: _reload,
          );
        }
        final events = snapshot.data ?? const <Event>[];
        if (events.isEmpty) {
          return LotusStateView(
            kind: LotusStateKind.empty,
            title: 'Ainda não há eventos',
            message: 'Volta mais tarde para descobrires novidades.',
            actionLabel: 'Atualizar',
            onAction: _reload,
          );
        }
        return _content(events);
      },
    ),
  );

  Widget _content(List<Event> events) {
    final validEvents = events
        .where((event) =>
            event.status != EventStatus.cancelled &&
            event.status != EventStatus.archived &&
            (event.endsAt == null || !event.endsAt!.isBefore(_now)) &&
            !event.startsAt.isBefore(_now.subtract(const Duration(hours: 12))))
        .toList();

    var featured =
        validEvents.where((event) => event.isFeatured).take(8).toList();
    if (featured.isEmpty && validEvents.isNotEmpty) {
      final withImage = validEvents.where((e) => e.imageUri != null).toList();
      featured = (withImage.isNotEmpty ? withImage : validEvents).take(3).toList();
    }
    final today = events.where(_isToday).take(12).toList();
    final weekend = events.where(_isThisWeekend).take(12).toList();
    final trending = [...events]
      ..sort((left, right) {
        final popularity = right.popularityScore.compareTo(
          left.popularityScore,
        );
        return popularity != 0
            ? popularity
            : left.startsAt.compareTo(right.startsAt);
      });
    final coordinates = _locationController.state.coordinates;
    final nearby = coordinates == null
        ? <Event>[]
        : events.where((event) => event.location.coordinates != null).toList();
    if (coordinates != null) {
      nearby.sort(
        (left, right) => calculateDistanceToEvent(
          coordinates,
          left,
        )!.compareTo(calculateDistanceToEvent(coordinates, right)!),
      );
    }
    final categories = <String, String>{};
    for (final event in events) {
      for (final category in event.categories) {
        categories[category.id] = category.label;
      }
    }
    final categoryEvents = _categoryId == null
        ? const <Event>[]
        : events
              .where((event) => event.categoryIds.contains(_categoryId))
              .take(16)
              .toList();

    final free =
        validEvents.where((event) => event.isFree).take(12).toList();
    final followedPromoters = _followedOrganizerIds.isEmpty
        ? <Event>[]
        : validEvents
            .where(
              (event) =>
                  event.organizer != null &&
                  _followedOrganizerIds.contains(event.organizer!.id),
            )
            .take(12)
            .toList();

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        key: const PageStorageKey('lotus-explore-scroll'),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          const Text(
            'Explorar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Planos para hoje, para o fim de semana e perto de ti.',
            style: TextStyle(color: lotusQualityMuted, fontSize: 15),
          ),
          const SizedBox(height: 18),
          Semantics(
            button: true,
            label: 'Pesquisar eventos, locais, categorias e organizadores',
            child: InkWell(
              key: const Key('explore-search'),
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.pushNamed(SearchWidget.routeName),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: lotusSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: lotusBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, color: lotusQualityMuted),
                    SizedBox(width: 12),
                    Text(
                      'Eventos, locais, categorias…',
                      style: TextStyle(color: lotusQualityMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _RadarDiscoveryBanner(onTap: () => unawaited(openLotusRadar(context))),
          if (featured.isNotEmpty)
            _FeaturedSection(
              events: featured,
              onOpen: _open,
            ),
          if (followedPromoters.isNotEmpty)
            _EventSection(
              title: 'Dos promoters que segues',
              events: followedPromoters,
              badge: 'A Seguir',
              onOpen: _open,
            ),
          if (today.isNotEmpty)
            _EventSection(title: 'Hoje', events: today, onOpen: _open),
          if (weekend.isNotEmpty)
            _EventSection(
              title: 'Este fim de semana',
              events: weekend,
              onOpen: _open,
            ),
          _NearbySection(
            events: nearby.take(12).toList(),
            status: _locationController.state.status,
            onRequestLocation: () =>
                _locationController.refresh(requestPermission: true),
            onOpen: _open,
          ),
          if (free.isNotEmpty)
            _EventSection(
              title: 'Entrada livre & Gratuitos',
              events: free,
              badge: 'Grátis',
              onOpen: _open,
            ),
          const SizedBox(height: 26),
          const _SectionTitle('Categorias'),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(entry.value),
                        selected: _categoryId == entry.key,
                        onSelected: (selected) => setState(
                          () => _categoryId = selected ? entry.key : null,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (_categoryId != null)
            _EventSection(
              title: categories[_categoryId] ?? 'Categoria',
              events: categoryEvents,
              onOpen: _open,
            ),
          _EventSection(
            title: 'Trending',
            events: trending.take(12).toList(),
            badge: 'Popular',
            onOpen: _open,
          ),
        ],
      ),
    );
  }

  Future<void> _reload() async {
    if (widget.repository == null) {
      _repository = FirestoreEventSearchRepository();
    }
    final next = _repository.loadCorpus(limit: 80);
    if (!mounted) return;
    setState(() {
      _events = next;
    });
    await next;
  }

  void _open(Event event) => unawaited(openLotusEvent(context, event));

  bool _isToday(Event event) {
    final date = event.startsAt.toLocal();
    final now = _now;
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isThisWeekend(Event event) {
    final now = _now;
    final today = DateTime(now.year, now.month, now.day);
    final daysUntilSaturday = (DateTime.saturday - today.weekday) % 7;
    final saturday = today.add(Duration(days: daysUntilSaturday));
    final monday = saturday.add(const Duration(days: 2));
    final date = event.startsAt.toLocal();
    return !date.isBefore(saturday) && date.isBefore(monday);
  }
}

class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection({
    required this.events,
    required this.onOpen,
  });

  final List<Event> events;
  final ValueChanged<Event> onOpen;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Em destaque'),
          const SizedBox(height: 12),
          SizedBox(
            height: 290,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final event = events[index];
                return LotusFeaturedEventHeroCard(
                  event: event,
                  badge: index == 0 ? '⚡ DESTAQUE LOTUS' : 'CURADORIA LOTUS',
                  onTap: () => onOpen(event),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EventSection extends StatelessWidget {
  const _EventSection({
    required this.title,
    required this.events,
    required this.onOpen,
    this.badge,
  });

  final String title;
  final List<Event> events;
  final ValueChanged<Event> onOpen;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title),
          const SizedBox(height: 10),
          SizedBox(
            height: 270,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final event = events[index];
                return LotusEventPosterCard(
                  event: event,
                  badge: badge,
                  onTap: () => onOpen(event),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbySection extends StatelessWidget {
  const _NearbySection({
    required this.events,
    required this.status,
    required this.onRequestLocation,
    required this.onOpen,
  });

  final List<Event> events;
  final UserLocationStatus status;
  final Future<UserLocationStatus> Function() onRequestLocation;
  final ValueChanged<Event> onOpen;

  @override
  Widget build(BuildContext context) {
    if (events.isNotEmpty) {
      return _EventSection(
        title: 'Perto de mim',
        events: events,
        onOpen: onOpen,
      );
    }
    final refused =
        status == UserLocationStatus.permissionDenied ||
        status == UserLocationStatus.permissionDeniedForever;
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Perto de mim'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: lotusSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: lotusBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.near_me_outlined, color: lotusQualityAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    refused
                        ? 'A localização foi recusada. Podes continuar a explorar por cidade.'
                        : 'Ativa a localização para ordenar eventos por distância.',
                    style: const TextStyle(color: lotusQualityMuted),
                  ),
                ),
                if (!refused)
                  TextButton(
                    onPressed: onRequestLocation,
                    child: const Text('Ativar'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _RadarDiscoveryBanner extends StatelessWidget {
  const _RadarDiscoveryBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: lotusSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: lotusQualityAccent.withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('explore-radar-banner'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: lotusQualityAccent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: lotusQualityAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'RADAR LOTUS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        _RadarBadge(),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Descobre teasers e eventos antes da revelação',
                      style: TextStyle(
                        color: lotusQualityMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: lotusQualityAccent,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarBadge extends StatelessWidget {
  const _RadarBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: lotusQualityAccent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'EXCLUSIVO',
        style: TextStyle(
          color: lotusQualityAccent,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

