import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/custom_code/event_mapping/events_record_to_event.dart';
import '/custom_code/event_mapping/firestore_event_search_repository.dart';
import '/custom_code/event_mapping/firestore_favorite_repository.dart';
import '/custom_code/event_mapping/firestore_personalization_repository.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/event_details/event_details_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

const _background = Color(0xFF0A0E13);
const _surface = Color(0xFF151B23);
const _border = Color(0xFF293342);
const _accent = Color(0xFFB7F34A);
const _muted = Color(0xFF9AA8B9);

/// Saved events, explicit interests, activity, and transparent recommendations.
class LotusPersonalizationHub extends StatefulWidget {
  const LotusPersonalizationHub({
    super.key,
    this.favoriteRepository,
    this.personalizationRepository,
    this.eventRepository,
  });

  final FavoriteRepository? favoriteRepository;
  final PersonalizationRepository? personalizationRepository;
  final EventSearchRepository? eventRepository;

  @override
  State<LotusPersonalizationHub> createState() =>
      _LotusPersonalizationHubState();
}

class _LotusPersonalizationHubState extends State<LotusPersonalizationHub> {
  late final FavoriteRepository _favorites;
  late final PersonalizationRepository _personalization;
  late final EventSearchRepository _events;
  Future<List<Event>>? _corpus;
  Stream<_PersonalizationState>? _profile;
  String? _profileUserId;

  @override
  void initState() {
    super.initState();
    _favorites = widget.favoriteRepository ?? FirestoreFavoriteRepository();
    _personalization =
        widget.personalizationRepository ??
        FirestorePersonalizationRepository();
    _events = widget.eventRepository ?? FirestoreEventSearchRepository();
    _corpus = _events.loadCorpus(limit: 200);
  }

  @override
  Widget build(BuildContext context) {
    final userId = currentUserUid;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Os teus eventos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                tooltip: 'Voltar',
                onPressed: context.safePop,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
      ),
      body: userId.isEmpty
          ? const _SignedOutState()
          : FutureBuilder<List<Event>>(
              future: _corpus,
              builder: (context, corpusSnapshot) {
                if (corpusSnapshot.hasError) {
                  return _ErrorState(onRetry: _reloadCorpus);
                }
                final corpus = corpusSnapshot.data;
                if (corpus == null) {
                  return const LotusSkeletonList();
                }
                return StreamBuilder<_PersonalizationState>(
                  stream: _profileFor(userId),
                  builder: (context, profileSnapshot) {
                    if (profileSnapshot.hasError) {
                      return _ErrorState(onRetry: _reloadProfile);
                    }
                    final profile = profileSnapshot.data;
                    if (profile == null) {
                      return const LotusSkeletonList();
                    }
                    return _HubContent(
                      corpus: corpus,
                      profile: profile,
                      onEditInterests: () => _editInterests(profile, corpus),
                      onOpenEvent: _openEvent,
                    );
                  },
                );
              },
            ),
    );
  }

  Stream<_PersonalizationState> _profileFor(String userId) {
    if (_profile == null || _profileUserId != userId) {
      _profileUserId = userId;
      _profile = Rx.combineLatest3(
        _favorites.watchFavoriteEventIds(userId),
        _personalization.watchInterestCategoryIds(userId),
        _personalization.watchInteractionHistory(userId),
        (favorites, interests, interactions) => _PersonalizationState(
          favoriteEventIds: favorites,
          interestCategoryIds: interests,
          interactions: interactions,
        ),
      );
    }
    return _profile!;
  }

  void _reloadCorpus() {
    final nextCorpus = _events.loadCorpus(limit: 200);
    if (!mounted) return;
    setState(() {
      _corpus = nextCorpus;
    });
  }

  void _reloadProfile() {
    setState(() {
      _profile = null;
      _profileUserId = null;
    });
  }

  Future<void> _editInterests(
    _PersonalizationState profile,
    List<Event> corpus,
  ) async {
    unawaited(LotusProductFeedback.selection());
    final categories = <String, String>{
      'música': 'Música',
      'festas': 'Festas',
      'cultura': 'Cultura',
      'desporto': 'Desporto',
    };
    for (final event in corpus) {
      for (final category in event.categories) {
        categories[category.id] = category.label;
      }
    }
    final selected = {...profile.interestCategoryIds};
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: _surface,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Os teus interesses',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Escolhe temas para melhorar as sugestões. Podes alterar isto quando quiseres.',
                  style: TextStyle(color: _muted, height: 1.4),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.entries
                          .map((entry) {
                            final active = selected.contains(entry.key);
                            return FilterChip(
                              selected: active,
                              label: Text(
                                entry.value,
                                style: TextStyle(
                                  color: active
                                      ? const Color(0xFF11161D)
                                      : Colors.white,
                                  fontWeight: active
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                              onSelected: (value) => setSheetState(() {
                                value
                                    ? selected.add(entry.key)
                                    : selected.remove(entry.key);
                              }),
                              selectedColor: _accent,
                              backgroundColor: _surface,
                              checkmarkColor: const Color(0xFF11161D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: active ? _accent : _border,
                                ),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: const Color(0xFF11161D),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context, selected),
                    child: const Text(
                      'Guardar interesses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    try {
      await _personalization.setInterestCategoryIds(
        userId: currentUserUid,
        categoryIds: result,
      );
      unawaited(LotusProductFeedback.success());
    } catch (_) {
      unawaited(LotusProductFeedback.error());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível guardar interesses.')),
        );
      }
    }
  }

  Future<void> _openEvent(Event event) async {
    unawaited(LotusProductFeedback.selection());
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
          const SnackBar(content: Text('Este evento já não está disponível.')),
        );
      }
    }
  }
}

final class _PersonalizationState {
  const _PersonalizationState({
    required this.favoriteEventIds,
    required this.interestCategoryIds,
    required this.interactions,
  });

  final Set<String> favoriteEventIds;
  final Set<String> interestCategoryIds;
  final List<EventInteractionSummary> interactions;
}

class _HubContent extends StatelessWidget {
  const _HubContent({
    required this.corpus,
    required this.profile,
    required this.onEditInterests,
    required this.onOpenEvent,
  });

  final List<Event> corpus;
  final _PersonalizationState profile;
  final VoidCallback onEditInterests;
  final ValueChanged<Event> onOpenEvent;

  @override
  Widget build(BuildContext context) {
    final recommendations = const RecommendEvents()(
      candidates: corpus,
      interestCategoryIds: profile.interestCategoryIds,
      interactions: profile.interactions,
      favoriteEventIds: profile.favoriteEventIds,
      limit: 30,
    );
    final corpusById = {for (final event in corpus) event.id: event};

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    profile.interestCategoryIds.isEmpty
                        ? 'Adiciona interesses para melhorar as sugestões.'
                        : '${profile.interestCategoryIds.length} interesses ativos',
                    style: const TextStyle(color: _muted),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEditInterests,
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Interesses'),
                  style: TextButton.styleFrom(foregroundColor: _accent),
                ),
              ],
            ),
          ),
          const TabBar(
            indicatorColor: _accent,
            labelColor: Colors.white,
            unselectedLabelColor: _muted,
            tabs: [
              Tab(text: 'Guardados'),
              Tab(text: 'Para ti'),
              Tab(text: 'Atividade'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _SavedEvents(
                  eventIds: profile.favoriteEventIds,
                  onOpenEvent: onOpenEvent,
                ),
                _RecommendationList(
                  recommendations: recommendations,
                  onOpenEvent: onOpenEvent,
                ),
                _ActivityList(
                  interactions: profile.interactions,
                  corpusById: corpusById,
                  onOpenEvent: onOpenEvent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedEvents extends StatelessWidget {
  const _SavedEvents({required this.eventIds, required this.onOpenEvent});

  final Set<String> eventIds;
  final ValueChanged<Event> onOpenEvent;

  @override
  Widget build(BuildContext context) {
    if (eventIds.isEmpty) {
      return const _EmptyState(
        icon: Icons.favorite_border_rounded,
        message: 'Os eventos que guardares aparecem aqui.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: eventIds.length.clamp(0, 100),
      itemBuilder: (context, index) {
        final path = eventIds.elementAt(index);
        return StreamBuilder<EventsRecord>(
          stream: EventsRecord.getDocument(
            FirebaseFirestore.instance.doc(path),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 112,
                child: LotusSkeletonList(itemCount: 1, compact: true),
              );
            }
            if (snapshot.hasError) {
              return const ListTile(
                leading: Icon(Icons.cloud_off_outlined, color: _muted),
                title: Text(
                  'Evento temporariamente indisponível',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Será atualizado quando recuperares a ligação.',
                  style: TextStyle(color: _muted),
                ),
              );
            }
            final record = snapshot.data;
            final event = record == null ? null : eventFromRecord(record);
            return event == null
                ? const SizedBox.shrink()
                : _EventCard(event: event, onTap: () => onOpenEvent(event));
          },
        );
      },
    );
  }
}

class _RecommendationList extends StatelessWidget {
  const _RecommendationList({
    required this.recommendations,
    required this.onOpenEvent,
  });

  final List<RecommendedEvent> recommendations;
  final ValueChanged<Event> onOpenEvent;

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const _EmptyState(
        icon: Icons.auto_awesome_rounded,
        message: 'Ainda não existem sugestões disponíveis.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = recommendations[index];
        return _EventCard(
          event: recommendation.event,
          reason: recommendation.reason,
          onTap: () => onOpenEvent(recommendation.event),
        );
      },
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({
    required this.interactions,
    required this.corpusById,
    required this.onOpenEvent,
  });

  final List<EventInteractionSummary> interactions;
  final Map<String, Event> corpusById;
  final ValueChanged<Event> onOpenEvent;

  @override
  Widget build(BuildContext context) {
    if (interactions.isEmpty) {
      return const _EmptyState(
        icon: Icons.history_rounded,
        message: 'A tua atividade recente aparece aqui.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: interactions.length,
      separatorBuilder: (_, __) => const Divider(color: _border),
      itemBuilder: (context, index) {
        final interaction = interactions[index];
        final event = corpusById[interaction.eventId];
        return _ActivityTile(
          interaction: interaction,
          event: event,
          onOpenEvent: onOpenEvent,
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.interaction,
    required this.event,
    required this.onOpenEvent,
  });

  final EventInteractionSummary interaction;
  final Event? event;
  final ValueChanged<Event> onOpenEvent;

  @override
  Widget build(BuildContext context) {
    if (event != null) {
      return _buildTile(event);
    }
    return StreamBuilder<EventsRecord>(
      stream: EventsRecord.getDocument(
        FirebaseFirestore.instance.doc(interaction.eventId),
      ),
      builder: (context, snapshot) {
        final record = snapshot.data;
        return _buildTile(record == null ? null : eventFromRecord(record));
      },
    );
  }

  Widget _buildTile(Event? resolvedEvent) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(_interactionIcon(interaction.lastType), color: _accent),
    title: Text(
      resolvedEvent?.title ?? 'Evento indisponível',
      style: const TextStyle(color: Colors.white),
    ),
    subtitle: Text(
      '${_interactionLabel(interaction.lastType)} · '
      '${DateFormat('d MMM, HH:mm').format(interaction.lastInteractedAt.toLocal())}',
      style: const TextStyle(color: _muted),
    ),
    onTap: resolvedEvent == null ? null : () => onOpenEvent(resolvedEvent),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap, this.reason});

  final Event event;
  final VoidCallback onTap;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '${event.title}, ${DateFormat('EEE, d MMM, HH:mm').format(event.startsAt.toLocal())}, ${event.location.displayName}',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Row(
              children: [
                SizedBox(
                  width: 112,
                  height: 112,
                  child: event.imageUri == null
                      ? const ColoredBox(
                          color: Color(0xFF202A36),
                          child: Icon(Icons.event_rounded, color: _muted),
                        )
                      : CachedNetworkImage(
                          imageUrl: event.imageUri.toString(),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const ColoredBox(
                            color: Color(0xFF202A36),
                            child: Icon(Icons.event_rounded, color: _muted),
                          ),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (reason != null) ...[
                          Text(
                            reason!,
                            style: const TextStyle(
                              color: _accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                        ],
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat(
                            'EEE, d MMM · HH:mm',
                          ).format(event.startsAt.toLocal()),
                          style: const TextStyle(color: _muted, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.location.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _muted, fontSize: 13),
                        ),
                      ],
                    ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => LotusStateView(
    kind: LotusStateKind.empty,
    icon: icon,
    title: 'Ainda não há conteúdo',
    message: message,
  );
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState();

  @override
  Widget build(BuildContext context) => const _EmptyState(
    icon: Icons.lock_outline_rounded,
    message: 'Inicia sessão para guardares eventos e receberes sugestões.',
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => LotusStateView(
    kind: LotusStateKind.offline,
    title: 'Não foi possível atualizar',
    message: 'Verifica a ligação e tenta novamente.',
    actionLabel: 'Tentar novamente',
    onAction: onRetry,
  );
}

String _interactionLabel(EventInteractionType type) => switch (type) {
  EventInteractionType.viewed => 'Visto',
  EventInteractionType.saved => 'Guardado',
  EventInteractionType.shared => 'Partilhado',
  EventInteractionType.directionsOpened => 'Direções abertas',
  EventInteractionType.ticketOpened => 'Bilheteira aberta',
};

IconData _interactionIcon(EventInteractionType type) => switch (type) {
  EventInteractionType.viewed => Icons.visibility_outlined,
  EventInteractionType.saved => Icons.favorite_outline_rounded,
  EventInteractionType.shared => Icons.ios_share_rounded,
  EventInteractionType.directionsOpened => Icons.directions_outlined,
  EventInteractionType.ticketOpened => Icons.confirmation_num_outlined,
};
