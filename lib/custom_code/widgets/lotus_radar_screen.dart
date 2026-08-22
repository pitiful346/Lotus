import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/custom_code/event_mapping/firestore_teaser_repository.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';
import 'lotus_event_navigation.dart';

const _background = Color(0xFF080B10);
const _surface = Color(0xFF151B23);
const _surfaceBorder = Color(0xFF293342);
const _accent = Color(0xFFB7F34A);
const _muted = Color(0xFF9AA8B9);

class LotusRadarScreen extends StatefulWidget {
  const LotusRadarScreen({
    super.key,
    this.teaserRepository,
    this.userId,
    this.now,
  });

  static const String routeName = 'Radar';
  static const String routePath = '/radar';

  final TeaserRepository? teaserRepository;
  final String? userId;
  final DateTime Function()? now;

  @override
  State<LotusRadarScreen> createState() => _LotusRadarScreenState();
}

class _LotusRadarScreenState extends State<LotusRadarScreen> {
  late final TeaserRepository _repo;
  String? _selectedCategory;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _repo = widget.teaserRepository ?? FirestoreTeaserRepository();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime get _now => (widget.now?.call() ?? DateTime.now()).toUtc();

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.userId ?? currentUserUid;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.radar_rounded, color: _accent, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'RADAR LOTUS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Teaser>>(
        stream: _repo.watchActiveTeasers(categoryId: _selectedCategory),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const LotusSkeletonList(itemCount: 4);
          }

          final allTeasers = snapshot.data ?? const <Teaser>[];
          final activeTeasers =
              allTeasers.where((t) => t.isActive).toList();
          final revealedTeasers =
              allTeasers.where((t) => t.isRevealed).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RadarHeroCard(
                        activeCount: activeTeasers.length,
                        revealedCount: revealedTeasers.length,
                      ),
                      const SizedBox(height: 18),
                      _CategoryFilterBar(
                        selectedCategory: _selectedCategory,
                        onSelectCategory: (cat) {
                          unawaited(LotusProductFeedback.selection());
                          setState(() => _selectedCategory = cat);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (allTeasers.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: LotusStateView(
                    kind: LotusStateKind.empty,
                    title: 'Radar sem sinais ativos',
                    message:
                        'Ainda não existem teasers ou revelações secretas agendadas para este filtro.',
                    actionLabel: _selectedCategory != null ? 'Limpar filtro' : null,
                    onAction: () => setState(() => _selectedCategory = null),
                  ),
                )
              else ...[
                if (activeTeasers.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: _accent, size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'EM CONTAGEM DECRESCENTE',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${activeTeasers.length}',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final teaser = activeTeasers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _RadarTeaserCard(
                              teaser: teaser,
                              now: _now,
                              currentUserId: currentUserId,
                              repository: _repo,
                            ),
                          );
                        },
                        childCount: activeTeasers.length,
                      ),
                    ),
                  ),
                ],
                if (revealedTeasers.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: const Row(
                        children: [
                          Icon(Icons.visibility_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'REVELADOS RECENTEMENTE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final teaser = revealedTeasers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _RadarTeaserCard(
                              teaser: teaser,
                              now: _now,
                              currentUserId: currentUserId,
                              repository: _repo,
                            ),
                          );
                        },
                        childCount: revealedTeasers.length,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 36)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RadarHeroCard extends StatelessWidget {
  const _RadarHeroCard({
    required this.activeCount,
    required this.revealedCount,
  });

  final int activeCount;
  final int revealedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
        gradient: const RadialGradient(
          center: Alignment.topRight,
          radius: 1.4,
          colors: [
            Color(0xFF1E2835),
            Color(0xFF12171F),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'EXCLUSIVO',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.blur_on_rounded, color: _accent, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Descobre o que vem aí antes de todos.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Acompanha teasers de promotores e sê avisado no momento exato do reveal.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onSelectCategory;

  static const _categories = [
    (id: null, label: 'Todos'),
    (id: 'musica', label: 'Música'),
    (id: 'cultura', label: 'Cultura'),
    (id: 'noite', label: 'Noite & Clubbing'),
    (id: 'gastronomia', label: 'Gastronomia'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = selectedCategory == cat.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat.label),
              selected: isSelected,
              onSelected: (_) => onSelectCategory(cat.id),
              selectedColor: _accent,
              checkmarkColor: const Color(0xFF080B10),
              backgroundColor: _surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? _accent : _surfaceBorder,
                ),
              ),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF080B10) : Colors.white,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RadarTeaserCard extends StatelessWidget {
  const _RadarTeaserCard({
    required this.teaser,
    required this.now,
    required this.currentUserId,
    required this.repository,
  });

  final Teaser teaser;
  final DateTime now;
  final String currentUserId;
  final TeaserRepository repository;

  @override
  Widget build(BuildContext context) {
    final isRevealed = teaser.isRevealed;
    final timeRemaining = teaser.timeUntilReveal(now);

    return Material(
      color: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isRevealed ? _surfaceBorder : _accent.withValues(alpha: 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(openLotusTeaserDetails(context, teaser)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E2632),
                      ),
                      child: teaser.imageUri != null
                          ? CachedNetworkImage(
                              imageUrl: teaser.imageUri.toString(),
                              fit: BoxFit.cover,
                              fadeInDuration: Duration.zero,
                              placeholder: (_, __) => _fallbackMysteryIcon(),
                              errorWidget: (_, __, ___) => _fallbackMysteryIcon(),
                            )
                          : _fallbackMysteryIcon(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isRevealed
                                    ? const Color(0xFF222D3D)
                                    : _accent.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isRevealed
                                    ? 'REVELADO'
                                    : _formatCountdown(timeRemaining),
                                style: TextStyle(
                                  color: isRevealed ? Colors.white70 : _accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (teaser.trackerCount > 0)
                              Row(
                                children: [
                                  const Icon(Icons.people_outline_rounded,
                                      color: _muted, size: 13),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${teaser.trackerCount}',
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          teaser.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          teaser.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: _surfaceBorder, height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (teaser.organizer != null) ...[
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              teaser.organizer!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (teaser.organizer!.isVerified) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.verified_rounded,
                                color: _accent, size: 14),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (teaser.city != null && teaser.city!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• ${teaser.city}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                  const Spacer(),
                  const Text(
                    'Ver Teaser',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded, color: _accent, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCountdown(Duration diff) {
    if (diff.inDays > 0) {
      return 'Reveal em ${diff.inDays}d ${diff.inHours % 24}h';
    }
    if (diff.inHours > 0) {
      return 'Reveal em ${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    if (diff.inMinutes > 0) {
      return 'Reveal em ${diff.inMinutes}m';
    }
    return 'Reveal eminente';
  }

  Widget _fallbackMysteryIcon() => const Center(
        child: Icon(Icons.radar_rounded, color: _accent, size: 28),
      );
}
