import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';

import '/custom_code/product_quality/lotus_product_quality.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/search/search_widget.dart';
import '../event_mapping/firestore_event_search_repository.dart';
import '../location/user_location_controller.dart';
import 'lotus_event_navigation.dart';
import 'lotus_event_tiles.dart';

class LotusExploreTab extends StatefulWidget {
  const LotusExploreTab({
    super.key,
    this.repository,
    this.locationController,
    this.now,
  });

  final EventSearchRepository? repository;
  final UserLocationController? locationController;
  final DateTime Function()? now;

  @override
  State<LotusExploreTab> createState() => _LotusExploreTabState();
}

class _LotusExploreTabState extends State<LotusExploreTab> {
  late EventSearchRepository _repository;
  late UserLocationController _locationController;
  late bool _ownsLocationController;
  Future<List<Event>>? _events;
  String? _categoryId;

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FirestoreEventSearchRepository();
    _events = _repository.loadCorpus(limit: 80);
    _ownsLocationController = widget.locationController == null;
    _locationController = widget.locationController ?? UserLocationController();
    _locationController.addListener(_locationChanged);
    unawaited(_locationController.refresh(requestPermission: false));
  }

  @override
  void dispose() {
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
    final featured = events.where((event) => event.isFeatured).take(8).toList();
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
          if (featured.isNotEmpty)
            _EventSection(
              title: 'Em destaque',
              events: featured,
              badge: 'Destaque',
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
    setState(() => _events = next);
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
