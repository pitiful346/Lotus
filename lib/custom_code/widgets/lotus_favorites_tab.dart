import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/custom_code/event_mapping/favorite_events_loader.dart';
import '/custom_code/event_mapping/firestore_favorite_repository.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';
import 'lotus_event_navigation.dart';
import 'lotus_event_tiles.dart';

export '/custom_code/event_mapping/favorite_events_loader.dart';

class LotusFavoritesTab extends StatefulWidget {
  const LotusFavoritesTab({
    super.key,
    this.favoriteRepository,
    this.eventsLoader,
    this.now,
    this.userId,
  });

  final FavoriteRepository? favoriteRepository;
  final FavoriteEventsLoader? eventsLoader;
  final DateTime Function()? now;
  final String? userId;

  @override
  State<LotusFavoritesTab> createState() => _LotusFavoritesTabState();
}

class _LotusFavoritesTabState extends State<LotusFavoritesTab> {
  late final FavoriteRepository _favorites;
  late final FavoriteEventsLoader _loader;
  Set<String>? _loadedIds;
  Future<FavoriteEventsResult>? _loadedEvents;
  final Set<String> _removingIds = {};

  @override
  void initState() {
    super.initState();
    _favorites = widget.favoriteRepository ?? FirestoreFavoriteRepository();
    _loader = widget.eventsLoader ?? const FirestoreFavoriteEventsLoader();
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId ?? currentUserUid;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Text(
              'Favoritos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: userId.isEmpty
                ? const LotusStateView(
                    kind: LotusStateKind.information,
                    title: 'Inicia sessão',
                    message: 'Entra na tua conta para veres eventos guardados.',
                  )
                : StreamBuilder<Set<String>>(
                    stream: _favorites.watchFavoriteEventIds(userId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const LotusStateView(
                          kind: LotusStateKind.offline,
                          title: 'Favoritos indisponíveis',
                          message: 'Verifica a ligação e tenta novamente.',
                        );
                      }
                      final ids = snapshot.data;
                      if (ids == null) return const LotusSkeletonList();
                      if (ids.isEmpty) {
                        return const LotusStateView(
                          kind: LotusStateKind.empty,
                          icon: Icons.favorite_border_rounded,
                          title: 'Ainda não guardaste eventos',
                          message:
                              'Toca no coração de um evento para o encontrares aqui.',
                        );
                      }
                      return FutureBuilder<FavoriteEventsResult>(
                        future: _eventsFor(ids),
                        builder: (context, eventSnapshot) {
                          if (eventSnapshot.hasError) {
                            return LotusStateView(
                              kind: LotusStateKind.offline,
                              title: 'Não foi possível carregar',
                              message: 'Os favoritos continuam guardados.',
                              actionLabel: 'Tentar novamente',
                              onAction: () => setState(() {
                                _loadedIds = null;
                                _loadedEvents = null;
                              }),
                            );
                          }
                          final result = eventSnapshot.data;
                          if (result == null) return const LotusSkeletonList();
                          return _favoritesList(userId, result);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<FavoriteEventsResult> _eventsFor(Set<String> ids) {
    if (_loadedIds == null || !_sameIds(_loadedIds!, ids)) {
      _loadedIds = Set.unmodifiable(ids);
      _loadedEvents = _loader.load(ids);
    }
    return _loadedEvents!;
  }

  Widget _favoritesList(String userId, FavoriteEventsResult result) {
    final now = (widget.now?.call() ?? DateTime.now()).toUtc();
    final upcoming = result.events
        .where((event) => !event.startsAt.isBefore(now))
        .toList();
    final past = result.events
        .where((event) => event.startsAt.isBefore(now))
        .toList()
        .reversed
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        if (result.missingCount > 0)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _RemovedEventNotice(),
          ),
        if (upcoming.isEmpty && past.isEmpty)
          const SizedBox(
            height: 360,
            child: LotusStateView(
              kind: LotusStateKind.empty,
              title: 'Sem eventos disponíveis',
              message: 'Alguns eventos guardados podem ter sido removidos.',
            ),
          ),
        if (upcoming.isNotEmpty) ...[
          const _FavoritesHeading('Próximos'),
          for (final event in upcoming) _eventTile(userId, event),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 18),
          const _FavoritesHeading('Eventos passados'),
          for (final event in past) _eventTile(userId, event),
        ],
      ],
    );
  }

  Widget _eventTile(String userId, Event event) => LotusEventListTile(
    event: event,
    onTap: () => unawaited(openLotusEvent(context, event)),
    trailing: IconButton(
      tooltip: 'Remover dos favoritos',
      onPressed: _removingIds.contains(event.id)
          ? null
          : () => _remove(userId, event),
      icon: _removingIds.contains(event.id)
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.favorite_rounded, color: lotusQualityAccent),
    ),
  );

  Future<void> _remove(String userId, Event event) async {
    setState(() => _removingIds.add(event.id));
    try {
      await _favorites.setFavorite(
        userId: userId,
        eventId: event.id,
        isFavorite: false,
      );
      unawaited(LotusProductFeedback.success());
    } catch (_) {
      unawaited(LotusProductFeedback.error());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível remover o favorito.')),
        );
      }
    } finally {
      if (mounted) setState(() => _removingIds.remove(event.id));
    }
  }
}

class _FavoritesHeading extends StatelessWidget {
  const _FavoritesHeading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _RemovedEventNotice extends StatelessWidget {
  const _RemovedEventNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: lotusSurface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: lotusBorder),
    ),
    child: const Row(
      children: [
        Icon(Icons.event_busy_outlined, color: lotusQualityMuted),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Um evento guardado foi removido ou deixou de estar disponível.',
            style: TextStyle(color: lotusQualityMuted),
          ),
        ),
      ],
    ),
  );
}

bool _sameIds(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);
