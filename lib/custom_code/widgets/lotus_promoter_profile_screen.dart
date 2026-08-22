import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/custom_code/event_mapping/firestore_organizer_repository.dart';
import '/custom_code/event_mapping/firestore_promoter_follow_repository.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';
import 'lotus_event_navigation.dart';
import 'lotus_event_tiles.dart';

const _background = Color(0xFF0A0E13);
const _surface = Color(0xFF151B23);
const _surfaceBorder = Color(0xFF293342);
const _accent = Color(0xFFB7F34A);
const _muted = Color(0xFF9AA8B9);

class LotusPromoterProfileScreen extends StatefulWidget {
  const LotusPromoterProfileScreen({
    super.key,
    this.organizer,
    this.organizerId,
    this.organizerReference,
    this.followRepository,
    this.eventsStream,
    this.now,
    this.userId,
  });

  final EventOrganizer? organizer;
  final String? organizerId;
  final DocumentReference? organizerReference;
  final PromoterFollowRepository? followRepository;
  final Stream<List<Event>>? eventsStream;
  final DateTime Function()? now;
  final String? userId;

  @override
  State<LotusPromoterProfileScreen> createState() =>
      _LotusPromoterProfileScreenState();
}

class _LotusPromoterProfileScreenState
    extends State<LotusPromoterProfileScreen> {
  late final PromoterFollowRepository _followRepo;
  late final String _resolvedId;
  DocumentReference? _organizerRef;
  late Stream<bool> _isFollowingStream;
  late Stream<int> _followerCountStream;
  late Stream<List<Event>> _eventsStream;
  Stream<EventOrganizer?>? _organizerStream;
  bool _isTogglingFollow = false;
  int _selectedTab = 0; // 0: Próximos, 1: Anteriores

  @override
  void initState() {
    super.initState();
    _followRepo =
        widget.followRepository ?? FirestorePromoterFollowRepository();

    if (widget.organizerReference != null) {
      _organizerRef = widget.organizerReference;
      _resolvedId = widget.organizerReference!.id;
    } else if (widget.organizer != null) {
      _resolvedId = widget.organizer!.id.split('/').last;
    } else if (widget.organizerId != null && widget.organizerId!.isNotEmpty) {
      _resolvedId = widget.organizerId!.split('/').last;
    } else {
      _resolvedId = 'unknown';
    }

    final currentUserId = widget.userId ?? currentUserUid;
    _isFollowingStream = currentUserId.isEmpty
        ? Stream<bool>.value(false)
        : _followRepo.watchIsFollowing(
            userId: currentUserId,
            organizerId: _resolvedId,
          );

    _followerCountStream = _followRepo.watchFollowerCount(_resolvedId);

    if (widget.eventsStream != null) {
      _eventsStream = widget.eventsStream!;
    } else if (widget.organizer != null) {
      _eventsStream = watchOrganizerEvents(_resolvedRef, organizer: widget.organizer);
    } else {
      _eventsStream = watchOrganizerEvents(_resolvedRef);
    }

    if (widget.organizer == null) {
      _organizerStream = watchEventOrganizer(_resolvedRef);
    }
  }

  DocumentReference get _resolvedRef =>
      _organizerRef ??
      resolveOrganizerReference(
        widget.organizer?.id ??
            widget.organizerId ??
            'organizers/unknown',
      );

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.userId ?? currentUserUid;

    if (widget.organizer != null) {
      return _buildProfile(context, widget.organizer!, currentUserId);
    }

    return StreamBuilder<EventOrganizer?>(
      stream: _organizerStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: _background,
            appBar: AppBar(
              backgroundColor: _background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            body: const LotusStateView(
              kind: LotusStateKind.error,
              title: 'Organizador indisponível',
              message: 'Não foi possível carregar o perfil deste organizador.',
            ),
          );
        }

        final organizer = snapshot.data;
        if (organizer == null) {
          return Scaffold(
            backgroundColor: _background,
            appBar: AppBar(
              backgroundColor: _background,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: _accent),
            ),
          );
        }

        return _buildProfile(context, organizer, currentUserId);
      },
    );
  }

  Widget _buildProfile(
    BuildContext context,
    EventOrganizer organizer,
    String currentUserId,
  ) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: _RoundAction(
          tooltip: 'Voltar',
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          _RoundAction(
            tooltip: 'Partilhar perfil',
            icon: Icons.ios_share_rounded,
            onPressed: () => _sharePromoter(organizer),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Event>>(
        stream: _eventsStream,
        builder: (context, eventsSnapshot) {
          final events = eventsSnapshot.data ?? const [];
          final now = (widget.now?.call() ?? DateTime.now()).toUtc();
          final upcoming = events
              .where((e) => !e.startsAt.isBefore(now))
              .toList();
          final past = events
              .where((e) => e.startsAt.isBefore(now))
              .toList()
              .reversed
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
            children: [
              _PromoterBanner(organizer: organizer),
              const SizedBox(height: 14),
              _PromoterHeader(
                organizer: organizer,
                currentUserId: currentUserId,
                isFollowingStream: _isFollowingStream,
                followerCountStream: _followerCountStream,
                resolvedId: _resolvedId,
                isTogglingFollow: _isTogglingFollow,
                onToggleFollow: (isFollowing) => _toggleFollow(
                  currentUserId: currentUserId,
                  isFollowing: isFollowing,
                ),
                eventCount: events.length,
              ),
              if (organizer.description != null &&
                  organizer.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _PromoterBio(bio: organizer.description!),
              ],
              const SizedBox(height: 18),
              _SocialLinksRow(organizer: organizer),
              const SizedBox(height: 24),
              _SegmentedTabs(
                selectedIndex: _selectedTab,
                upcomingCount: upcoming.length,
                pastCount: past.length,
                onTabSelected: (index) =>
                    setState(() => _selectedTab = index),
              ),
              const SizedBox(height: 16),
              if (_selectedTab == 0) ...[
                if (upcoming.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: LotusStateView(
                      kind: LotusStateKind.empty,
                      icon: Icons.event_available_outlined,
                      title: 'Sem eventos agendados',
                      message:
                          'Este promotor não tem próximos eventos agendados de momento.',
                    ),
                  )
                else
                  for (final event in upcoming)
                    LotusEventListTile(
                      event: event,
                      onTap: () => unawaited(openLotusEvent(context, event)),
                    ),
              ] else ...[
                if (past.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: LotusStateView(
                      kind: LotusStateKind.empty,
                      icon: Icons.history_rounded,
                      title: 'Sem eventos passados',
                      message:
                          'Não existem eventos anteriores registados para este promotor.',
                    ),
                  )
                else
                  for (final event in past)
                    LotusEventListTile(
                      event: event,
                      onTap: () => unawaited(openLotusEvent(context, event)),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleFollow({
    required String currentUserId,
    required bool isFollowing,
  }) async {
    if (_isTogglingFollow) return;
    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sessão para seguires promotores.'),
        ),
      );
      return;
    }

    setState(() => _isTogglingFollow = true);
    unawaited(LotusProductFeedback.selection());
    try {
      await _followRepo.setFollowing(
        userId: currentUserId,
        organizerId: _resolvedId,
        isFollowing: !isFollowing,
      );
      unawaited(LotusProductFeedback.success());
    } catch (_) {
      unawaited(LotusProductFeedback.error());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar o estado de seguir.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingFollow = false);
    }
  }

  Future<void> _sharePromoter(EventOrganizer organizer) async {
    unawaited(LotusProductFeedback.selection());
    final message = [
      organizer.name,
      if (organizer.description != null) organizer.description!,
      if (organizer.websiteUri != null) organizer.websiteUri!.toString(),
    ].join('\n\n');

    try {
      await Share.share(message, subject: organizer.name);
    } catch (_) {}
  }
}

class _PromoterBanner extends StatelessWidget {
  const _PromoterBanner({required this.organizer});

  final EventOrganizer organizer;

  @override
  Widget build(BuildContext context) {
    final bannerUri = organizer.bannerUri;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bannerUri != null)
              CachedNetworkImage(
                imageUrl: bannerUri.toString(),
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                placeholder: (_, __) => _defaultBanner(),
                errorWidget: (_, __, ___) => _defaultBanner(),
              )
            else
              _defaultBanner(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x200A0E13),
                    Color(0x800A0E13),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultBanner() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B232E), Color(0xFF0F141A)],
          ),
        ),
      );
}

class _PromoterHeader extends StatelessWidget {
  const _PromoterHeader({
    required this.organizer,
    required this.currentUserId,
    required this.isFollowingStream,
    required this.followerCountStream,
    required this.resolvedId,
    required this.isTogglingFollow,
    required this.onToggleFollow,
    required this.eventCount,
  });

  final EventOrganizer organizer;
  final String currentUserId;
  final Stream<bool> isFollowingStream;
  final Stream<int> followerCountStream;
  final String resolvedId;
  final bool isTogglingFollow;
  final void Function(bool isFollowing) onToggleFollow;
  final int eventCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PromoterAvatar(organizer: organizer),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        organizer.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (organizer.isVerified)
                        const Icon(
                          Icons.verified_rounded,
                          color: _accent,
                          size: 20,
                        ),
                    ],
                  ),
                  if (organizer.legalName != null &&
                      organizer.legalName!.isNotEmpty &&
                      organizer.legalName != organizer.name) ...[
                    const SizedBox(height: 2),
                    Text(
                      organizer.legalName!,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  StreamBuilder<int>(
                    stream: followerCountStream,
                    initialData: organizer.followerCount,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          _StatChip(
                            label: '$count',
                            subtitle: count == 1 ? 'Seguidor' : 'Seguidores',
                          ),
                          _StatChip(
                            label: '$eventCount',
                            subtitle: eventCount == 1 ? 'Evento' : 'Eventos',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        StreamBuilder<bool>(
          stream: isFollowingStream,
          initialData: false,
          builder: (context, snapshot) {
            final isFollowing = snapshot.data ?? false;
            return SizedBox(
              width: double.infinity,
              height: 44,
              child: isFollowing
                  ? OutlinedButton(
                      key: const Key('promoter-unfollow-btn'),
                      onPressed: isTogglingFollow
                          ? null
                          : () => onToggleFollow(true),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _surfaceBorder),
                        foregroundColor: Colors.white,
                        backgroundColor: _surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isTogglingFollow)
                            const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(Icons.check_rounded, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'A seguir',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    )
                  : FilledButton(
                      key: const Key('promoter-follow-btn'),
                      onPressed: isTogglingFollow
                          ? null
                          : () => onToggleFollow(false),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: const Color(0xFF0A0E13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isTogglingFollow)
                            const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0A0E13),
                              ),
                            )
                          else
                            const Icon(Icons.add_rounded, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Seguir',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _PromoterAvatar extends StatelessWidget {
  const _PromoterAvatar({required this.organizer});

  final EventOrganizer organizer;

  @override
  Widget build(BuildContext context) {
    final imageUri = organizer.imageUri;
    final initial = organizer.name.characters.first.toUpperCase();

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _surfaceBorder, width: 2),
        color: const Color(0xFF1E2631),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUri != null
          ? CachedNetworkImage(
              imageUrl: imageUri.toString(),
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              placeholder: (_, __) => _fallback(initial),
              errorWidget: (_, __, ___) => _fallback(initial),
            )
          : _fallback(initial),
    );
  }

  Widget _fallback(String initial) => Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: _accent,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.subtitle});

  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: _muted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _PromoterBio extends StatefulWidget {
  const _PromoterBio({required this.bio});

  final String bio;

  @override
  State<_PromoterBio> createState() => _PromoterBioState();
}

class _PromoterBioState extends State<_PromoterBio> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.bio.length > 140;
    return GestureDetector(
      onTap: isLong ? () => setState(() => _expanded = !_expanded) : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bio,
              maxLines: _expanded ? null : 3,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (isLong) ...[
              const SizedBox(height: 6),
              Text(
                _expanded ? 'Ver menos' : 'Ver mais',
                style: const TextStyle(
                  color: _accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SocialLinksRow extends StatelessWidget {
  const _SocialLinksRow({required this.organizer});

  final EventOrganizer organizer;

  @override
  Widget build(BuildContext context) {
    final hasWebsite = organizer.websiteUri != null;
    final hasInstagram = organizer.instagramUri != null;

    if (!hasWebsite && !hasInstagram) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (hasWebsite)
          Expanded(
            child: _SocialButton(
              icon: Icons.language_rounded,
              label: 'Website',
              onPressed: () => launchUrl(
                organizer.websiteUri!,
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
        if (hasWebsite && hasInstagram) const SizedBox(width: 10),
        if (hasInstagram)
          Expanded(
            child: _SocialButton(
              icon: Icons.camera_alt_outlined,
              label: 'Instagram',
              onPressed: () => launchUrl(
                organizer.instagramUri!,
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _surfaceBorder),
        backgroundColor: _surface,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(icon, size: 16, color: _accent),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.selectedIndex,
    required this.upcomingCount,
    required this.pastCount,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final int upcomingCount;
  final int pastCount;
  final void Function(int index) onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _surfaceBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Próximos ($upcomingCount)',
              isSelected: selectedIndex == 0,
              onTap: () => onTabSelected(0),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Anteriores ($pastCount)',
              isSelected: selectedIndex == 1,
              onTap: () => onTabSelected(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFF25303C) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : _muted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xB3181F28),
      ),
    );
  }
}
