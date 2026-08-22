import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lotus_core/lotus_core.dart';
import 'package:share_plus/share_plus.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/custom_code/event_mapping/events_record_to_event.dart';
import '/custom_code/event_mapping/firestore_favorite_repository.dart';
import '/custom_code/event_mapping/firestore_teaser_repository.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';
import 'lotus_event_navigation.dart';

const _background = Color(0xFF080B10);
const _surface = Color(0xFF151B23);
const _surfaceBorder = Color(0xFF293342);
const _accent = Color(0xFFB7F34A);
const _muted = Color(0xFF9AA8B9);

class LotusTeaserDetailsScreen extends StatefulWidget {
  const LotusTeaserDetailsScreen({
    super.key,
    required this.teaser,
    this.teaserRepository,
    this.favoriteRepository,
    this.targetEvent,
    this.userId,
    this.now,
  });

  final Teaser teaser;
  final TeaserRepository? teaserRepository;
  final FavoriteRepository? favoriteRepository;
  final Event? targetEvent;
  final String? userId;
  final DateTime Function()? now;

  @override
  State<LotusTeaserDetailsScreen> createState() =>
      _LotusTeaserDetailsScreenState();
}

class _LotusTeaserDetailsScreenState extends State<LotusTeaserDetailsScreen> {
  late final TeaserRepository _repo;
  late final FavoriteRepository _favoriteRepo;
  late Stream<bool> _isTrackingStream;
  late Stream<int> _trackerCountStream;
  late Stream<Teaser?> _teaserStream;
  bool _isToggling = false;
  Timer? _timer;
  bool _wasRevealed = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.teaserRepository ?? FirestoreTeaserRepository();
    _favoriteRepo = widget.favoriteRepository ?? FirestoreFavoriteRepository();

    final currentUserId = widget.userId ?? currentUserUid;
    _isTrackingStream = currentUserId.isEmpty
        ? Stream<bool>.value(false)
        : _repo.watchIsTrackingTeaser(
            userId: currentUserId,
            teaserId: widget.teaser.id,
          );

    _trackerCountStream = _repo.watchTeaserTrackerCount(widget.teaser.id);
    _teaserStream = _repo.watchTeaser(widget.teaser.id);
    _wasRevealed = widget.teaser.isRevealed;

    // Refresh live countdown every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final nowUtc = _currentTime;
      final nowRevealed = widget.teaser.revealAt.isBefore(nowUtc) ||
          widget.teaser.status == TeaserStatus.revealed;
      if (nowRevealed && !_wasRevealed) {
        _wasRevealed = true;
        unawaited(LotusProductFeedback.success());
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime get _currentTime => (widget.now?.call() ?? DateTime.now()).toUtc();

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.userId ?? currentUserUid;

    return StreamBuilder<Teaser?>(
      stream: _teaserStream,
      initialData: widget.teaser,
      builder: (context, snapshot) {
        final teaser = snapshot.data ?? widget.teaser;
        final isRevealed = teaser.isRevealed;

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
            title: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.radar_rounded, color: _accent, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      isRevealed ? 'REVELADO' : 'RADAR LOTUS',
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Partilhar teaser',
                icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
                onPressed: () => _shareTeaser(teaser),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
            children: [
              _TeaserPoster(teaser: teaser),
              const SizedBox(height: 18),
              _CountdownCard(
                revealAt: teaser.revealAt,
                now: _currentTime,
                isRevealed: isRevealed,
              ),
              const SizedBox(height: 18),
              Text(
                teaser.displayTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              _PillsRow(teaser: teaser),
              const SizedBox(height: 18),
              _TeaserDescription(description: teaser.description),
              if (teaser.organizer != null) ...[
                const SizedBox(height: 20),
                _OrganizerPreviewCard(organizer: teaser.organizer!),
              ],
              const SizedBox(height: 26),
              if (isRevealed) ...[
                _RevealedEventSection(
                  targetEventId: teaser.targetEventId ?? '',
                  targetEvent: widget.targetEvent,
                  currentUserId: currentUserId,
                  favoriteRepository: _favoriteRepo,
                ),
              ] else ...[
                _TrackButton(
                  currentUserId: currentUserId,
                  isTrackingStream: _isTrackingStream,
                  trackerCountStream: _trackerCountStream,
                  fallbackTrackerCount: teaser.trackerCount,
                  isToggling: _isToggling,
                  onToggle: (currentTracking) => _toggleTracking(
                    currentUserId: currentUserId,
                    teaserId: teaser.id,
                    isTracking: currentTracking,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleTracking({
    required String currentUserId,
    required String teaserId,
    required bool isTracking,
  }) async {
    if (_isToggling) return;
    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sessão para acompanhares eventos no Radar.'),
        ),
      );
      return;
    }

    setState(() => _isToggling = true);
    unawaited(LotusProductFeedback.selection());
    try {
      await _repo.setTrackingTeaser(
        userId: currentUserId,
        teaserId: teaserId,
        isTracking: !isTracking,
      );
      unawaited(LotusProductFeedback.success());
    } catch (_) {
      unawaited(LotusProductFeedback.error());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar o acompanhamento.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  Future<void> _shareTeaser(Teaser teaser) async {
    unawaited(LotusProductFeedback.selection());
    final message = [
      '⚡ Evento Secreto no Radar Lotus: ${teaser.displayTitle}',
      teaser.description,
      'Data de Revelação: ${DateFormat('dd/MM/yyyy HH:mm').format(teaser.revealAt.toLocal())}',
      'Descobre no Lotus Mobile!',
    ].join('\n\n');

    try {
      await Share.share(message, subject: teaser.displayTitle);
    } catch (_) {}
  }
}

class _TeaserPoster extends StatelessWidget {
  const _TeaserPoster({required this.teaser});

  final Teaser teaser;

  @override
  Widget build(BuildContext context) {
    final imageUri = teaser.imageUri;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: _surfaceBorder),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUri != null)
              CachedNetworkImage(
                imageUrl: imageUri.toString(),
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                placeholder: (_, __) => _fallbackMystery(),
                errorWidget: (_, __, ___) => _fallbackMystery(),
              )
            else
              _fallbackMystery(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x10080B10),
                    Color(0x90080B10),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xCC151B23),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _surfaceBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_off_rounded,
                            color: _accent, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          teaser.isRevealed ? 'Revelado' : 'Info Secreta',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackMystery() => Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.9,
            colors: [Color(0xFF222B38), Color(0xFF0F141A)],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.radar_rounded,
            color: Color(0x66B7F34A),
            size: 64,
          ),
        ),
      );
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({
    required this.revealAt,
    required this.now,
    required this.isRevealed,
  });

  final DateTime revealAt;
  final DateTime now;
  final bool isRevealed;

  @override
  Widget build(BuildContext context) {
    final difference = revealAt.difference(now);
    final isPast = isRevealed || difference.isNegative || difference == Duration.zero;

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: isPast ? 0.6 : 0.3)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: isPast ? 0.12 : 0.05),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            spacing: 6,
            children: [
              Icon(
                isPast ? Icons.lock_open_rounded : Icons.timer_outlined,
                color: _accent,
                size: 16,
              ),
              Text(
                isPast ? 'EVENTO REVELADO' : 'CONTAGEM DECRESCENTE PARA REVEAL',
                style: const TextStyle(
                  color: _accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isPast)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accent.withValues(alpha: 0.3)),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: _accent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'O segredo foi revelado!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TimeBlock(value: days.toString().padLeft(2, '0'), unit: 'Dias'),
                  const _TimeSeparator(),
                  _TimeBlock(value: hours.toString().padLeft(2, '0'), unit: 'Horas'),
                  const _TimeSeparator(),
                  _TimeBlock(value: minutes.toString().padLeft(2, '0'), unit: 'Min'),
                  const _TimeSeparator(),
                  _TimeBlock(value: seconds.toString().padLeft(2, '0'), unit: 'Seg'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock({required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2632),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _surfaceBorder),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: const TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _TimeSeparator extends StatelessWidget {
  const _TimeSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Text(
        ':',
        style: TextStyle(color: _muted, fontSize: 18, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _PillsRow extends StatelessWidget {
  const _PillsRow({required this.teaser});

  final Teaser teaser;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (teaser.category != null)
          _TagChip(
            icon: Icons.category_rounded,
            label: teaser.category!.label,
          ),
        if (teaser.city != null && teaser.city!.isNotEmpty)
          _TagChip(
            icon: Icons.location_on_outlined,
            label: teaser.city!,
          ),
        if (teaser.approximateDate != null && teaser.approximateDate!.isNotEmpty)
          _TagChip(
            icon: Icons.calendar_today_outlined,
            label: teaser.approximateDate!,
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _muted, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeaserDescription extends StatelessWidget {
  const _TeaserDescription({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Icon(Icons.auto_awesome_rounded, color: _accent, size: 16),
              Text(
                'PISTAS & DETALHES',
                style: TextStyle(
                  color: _accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizerPreviewCard extends StatelessWidget {
  const _OrganizerPreviewCard({required this.organizer});

  final EventOrganizer organizer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _surfaceBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(openLotusPromoterProfile(context, organizer: organizer)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _surfaceBorder),
                  color: const Color(0xFF1E2631),
                ),
                clipBehavior: Clip.antiAlias,
                child: organizer.imageUri != null
                    ? CachedNetworkImage(
                        imageUrl: organizer.imageUri.toString(),
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        placeholder: (_, __) => _initial(),
                        errorWidget: (_, __, ___) => _initial(),
                      )
                    : _initial(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            organizer.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (organizer.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            color: _accent,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Promotor do evento • Ver perfil',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initial() => Center(
        child: Text(
          organizer.name.isNotEmpty ? organizer.name[0].toUpperCase() : 'L',
          style: const TextStyle(
            color: _accent,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _TrackButton extends StatelessWidget {
  const _TrackButton({
    required this.currentUserId,
    required this.isTrackingStream,
    required this.trackerCountStream,
    required this.fallbackTrackerCount,
    required this.isToggling,
    required this.onToggle,
  });

  final String currentUserId;
  final Stream<bool> isTrackingStream;
  final Stream<int> trackerCountStream;
  final int fallbackTrackerCount;
  final bool isToggling;
  final void Function(bool isTracking) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<int>(
          stream: trackerCountStream,
          initialData: fallbackTrackerCount,
          builder: (context, countSnapshot) {
            final count = countSnapshot.data ?? 0;
            return Text(
              count == 1
                  ? '1 pessoa a acompanhar este teaser'
                  : '$count pessoas a acompanhar este teaser',
              style: const TextStyle(color: _muted, fontSize: 13),
            );
          },
        ),
        const SizedBox(height: 10),
        StreamBuilder<bool>(
          stream: isTrackingStream,
          initialData: false,
          builder: (context, trackingSnapshot) {
            final isTracking = trackingSnapshot.data ?? false;
            return SizedBox(
              width: double.infinity,
              height: 48,
              child: isTracking
                  ? OutlinedButton(
                      key: const Key('teaser-untrack-btn'),
                      onPressed: isToggling ? null : () => onToggle(true),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _surfaceBorder),
                        foregroundColor: Colors.white,
                        backgroundColor: _surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isToggling)
                            const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(Icons.notifications_active_rounded,
                                color: _accent, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'A acompanhar (Serás avisado no reveal)',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    )
                  : FilledButton(
                      key: const Key('teaser-track-btn'),
                      onPressed: isToggling ? null : () => onToggle(false),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: const Color(0xFF080B10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isToggling)
                            const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF080B10),
                              ),
                            )
                          else
                            const Icon(Icons.radar_rounded, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Acompanhar Teaser',
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

class _RevealedEventSection extends StatefulWidget {
  const _RevealedEventSection({
    required this.targetEventId,
    this.targetEvent,
    required this.currentUserId,
    required this.favoriteRepository,
  });

  final String targetEventId;
  final Event? targetEvent;
  final String currentUserId;
  final FavoriteRepository favoriteRepository;

  @override
  State<_RevealedEventSection> createState() => _RevealedEventSectionState();
}

class _RevealedEventSectionState extends State<_RevealedEventSection> {
  Event? _loadedEvent;
  bool _isLoading = false;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    if (widget.targetEvent != null) {
      _loadedEvent = widget.targetEvent;
    } else if (widget.targetEventId.isNotEmpty) {
      _loadEvent();
    }
  }

  Future<void> _loadEvent() async {
    setState(() => _isLoading = true);
    try {
      final cleanId = widget.targetEventId.trim();
      final docRef = cleanId.contains('/')
          ? FirebaseFirestore.instance.doc(cleanId)
          : FirebaseFirestore.instance.collection('events').doc(cleanId);

      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final record = EventsRecord.fromSnapshot(snapshot);
        final parsed = eventFromRecord(record);
        if (mounted && parsed != null) {
          setState(() => _loadedEvent = parsed);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final event = _loadedEvent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'EVENTO OFICIAL',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              if (event != null)
                Text(
                  _formatPrice(event.price),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (event != null) ...[
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: _muted, size: 14),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMMM yyyy • HH:mm').format(event.startsAt.toLocal()),
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: _muted, size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    event.location.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    key: const Key('teaser-open-event-btn'),
                    onPressed: () => _openEvent(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: const Color(0xFF080B10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF080B10),
                            ),
                          )
                        : const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text(
                      'Explorar Evento Agora',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              if (event != null) ...[
                const SizedBox(width: 8),
                _FavoriteIconButton(
                  eventId: event.id,
                  currentUserId: widget.currentUserId,
                  favoriteRepository: widget.favoriteRepository,
                  isToggling: _isTogglingFavorite,
                  onToggle: () => _toggleFavorite(event.id),
                ),
                const SizedBox(width: 6),
                IconButton(
                  key: const Key('teaser-share-event-btn'),
                  tooltip: 'Partilhar evento',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2632),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: _surfaceBorder),
                    ),
                  ),
                  icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                  onPressed: () => _shareEvent(event),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openEvent(BuildContext context) async {
    unawaited(LotusProductFeedback.selection());
    if (_loadedEvent != null) {
      await openLotusEvent(context, _loadedEvent!);
      return;
    }

    try {
      final cleanId = widget.targetEventId.trim();
      final docRef = cleanId.contains('/')
          ? FirebaseFirestore.instance.doc(cleanId)
          : FirebaseFirestore.instance.collection('events').doc(cleanId);

      final snapshot = await docRef.get();
      if (!snapshot.exists || !context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este evento já não está disponível.')),
        );
        return;
      }

      final record = EventsRecord.fromSnapshot(snapshot);
      final event = eventFromRecord(record);
      if (event != null && context.mounted) {
        await openLotusEvent(context, event);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o evento.')),
        );
      }
    }
  }

  Future<void> _toggleFavorite(String eventId) async {
    if (_isTogglingFavorite) return;
    if (widget.currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicia sessão para guardar eventos nos favoritos.'),
        ),
      );
      return;
    }

    setState(() => _isTogglingFavorite = true);
    unawaited(LotusProductFeedback.selection());
    try {
      final cleanEventId = eventId.split('/').last;
      await widget.favoriteRepository.setFavorite(
        userId: widget.currentUserId,
        eventId: cleanEventId,
        isFavorite: true,
      );
      unawaited(LotusProductFeedback.success());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento guardado nos favoritos!')),
        );
      }
    } catch (_) {
      unawaited(LotusProductFeedback.error());
    } finally {
      if (mounted) setState(() => _isTogglingFavorite = false);
    }
  }

  Future<void> _shareEvent(Event event) async {
    unawaited(LotusProductFeedback.selection());
    final message = [
      '🔥 Evento Revelado no Lotus: ${event.title}',
      '📅 ${DateFormat('dd/MM/yyyy HH:mm').format(event.startsAt.toLocal())}',
      '📍 ${event.location.displayName}',
      'Descobre todos os detalhes no Lotus Mobile!',
    ].join('\n\n');

    try {
      await Share.share(message, subject: event.title);
    } catch (_) {}
  }
}

class _FavoriteIconButton extends StatelessWidget {
  const _FavoriteIconButton({
    required this.eventId,
    required this.currentUserId,
    required this.favoriteRepository,
    required this.isToggling,
    required this.onToggle,
  });

  final String eventId;
  final String currentUserId;
  final FavoriteRepository favoriteRepository;
  final bool isToggling;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    if (currentUserId.isEmpty) {
      return IconButton(
        key: const Key('teaser-favorite-btn'),
        tooltip: 'Guardar favorito',
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF1E2632),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _surfaceBorder),
          ),
        ),
        icon: const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 20),
        onPressed: onToggle,
      );
    }

    final cleanEventId = eventId.split('/').last;

    return StreamBuilder<Set<String>>(
      stream: favoriteRepository.watchFavoriteEventIds(currentUserId),
      initialData: const {},
      builder: (context, snapshot) {
        final favorites = snapshot.data ?? const {};
        final isFav = favorites.contains(cleanEventId) || favorites.contains(eventId);

        return IconButton(
          key: const Key('teaser-favorite-btn'),
          tooltip: isFav ? 'Remover dos favoritos' : 'Guardar favorito',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF1E2632),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isFav ? Colors.redAccent.withValues(alpha: 0.5) : _surfaceBorder,
              ),
            ),
          ),
          icon: Icon(
            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFav ? Colors.redAccent : Colors.white,
            size: 20,
          ),
          onPressed: isToggling ? null : onToggle,
        );
      },
    );
  }
}

String _formatPrice(EventPrice price) {
  if (price.isFree) return 'Gratuito';
  if (!price.isKnown) return 'Sob consulta';
  final min = (price.minimumMinorUnits ?? 0) / 100.0;
  final max = price.maximumMinorUnits != null ? price.maximumMinorUnits! / 100.0 : null;
  if (max != null && max > min) {
    return '${min.toStringAsFixed(2).replaceAll('.', ',')} € - ${max.toStringAsFixed(2).replaceAll('.', ',')} €';
  }
  return '${min.toStringAsFixed(2).replaceAll('.', ',')} €';
}
