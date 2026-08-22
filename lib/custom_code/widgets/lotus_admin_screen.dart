import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';

const _background = Color(0xFF080B10);
const _surface = Color(0xFF151B23);
const _surfaceBorder = Color(0xFF293342);
const _accent = Color(0xFFB7F34A);
const _muted = Color(0xFF9AA8B9);

class LotusAdminScreen extends StatefulWidget {
  const LotusAdminScreen({
    super.key,
    this.eventsStream,
    this.usersStream,
  });

  static const String routeName = 'LotusAdmin';
  static const String routePath = '/admin';

  final Stream<List<EventsRecord>>? eventsStream;
  final Stream<List<UsersRecord>>? usersStream;

  @override
  State<LotusAdminScreen> createState() => _LotusAdminScreenState();
}

class _LotusAdminScreenState extends State<LotusAdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _accent.withValues(alpha: 0.5)),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: _accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Lotus Backoffice',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accent,
          indicatorWeight: 3,
          labelColor: _accent,
          unselectedLabelColor: _muted,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Visão Geral'),
            Tab(icon: Icon(Icons.event_note_rounded), text: 'Eventos'),
            Tab(icon: Icon(Icons.verified_user_rounded), text: 'Promoters'),
            Tab(icon: Icon(Icons.radar_rounded), text: 'Radar / Teasers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AdminOverviewTab(
            eventsStream: widget.eventsStream,
            usersStream: widget.usersStream,
          ),
          _AdminEventsTab(eventsStream: widget.eventsStream),
          _AdminPromotersTab(usersStream: widget.usersStream),
          const _AdminRadarTab(),
        ],
      ),
    );
  }
}

class _AdminOverviewTab extends StatelessWidget {
  const _AdminOverviewTab({this.eventsStream, this.usersStream});

  final Stream<List<EventsRecord>>? eventsStream;
  final Stream<List<UsersRecord>>? usersStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventsRecord>>(
      stream: eventsStream ?? queryEventsRecord(),
      builder: (context, eventsSnapshot) {
        return StreamBuilder<List<UsersRecord>>(
          stream: usersStream ?? queryUsersRecord(),
          builder: (context, usersSnapshot) {
            final events = eventsSnapshot.data ?? [];
            final users = usersSnapshot.data ?? [];
            final activeEvents = events.where((e) => !e.isArchived).toList();
            final featuredEvents = activeEvents
                .where((e) =>
                    e.isBoosted ||
                    e.snapshotData['featured'] == true ||
                    e.snapshotData['is_featured'] == true)
                .toList();
            final promoters =
                users.where((u) => u.isPromoter || u.isVerified).toList();
            final totalClicks = events.fold<int>(
              0,
              (sum, item) => sum + item.clickCount,
            );

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Métricas da Plataforma',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Eventos Ativos',
                        value: '${activeEvents.length}',
                        icon: Icons.event_available_rounded,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Em Destaque',
                        value: '${featuredEvents.length}',
                        icon: Icons.star_rounded,
                        color: const Color(0xFFFFC857),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Promoters',
                        value: '${promoters.length}',
                        icon: Icons.business_rounded,
                        color: const Color(0xFF64B5F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Interações',
                        value: '$totalClicks',
                        icon: Icons.touch_app_rounded,
                        color: const Color(0xFFFF5252),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Ações Rápidas de Moderação',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.cleaning_services_rounded,
                  title: 'Limpar eventos passados',
                  subtitle: 'Arquivar eventos que já terminaram',
                  onTap: () async {
                    unawaited(LotusProductFeedback.selection());
                    final now = DateTime.now();
                    var count = 0;
                    for (final event in events) {
                      final start = event.startDate;
                      if (start != null &&
                          start.isBefore(now.subtract(const Duration(days: 2))) &&
                          !event.isArchived) {
                        await event.reference.update({'is_archived': true});
                        count++;
                      }
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$count eventos antigos arquivados.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _surfaceBorder),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _accent, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
        onTap: onTap,
      ),
    );
  }
}

class _AdminEventsTab extends StatelessWidget {
  const _AdminEventsTab({this.eventsStream});

  final Stream<List<EventsRecord>>? eventsStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventsRecord>>(
      stream: eventsStream ?? queryEventsRecord(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _accent));
        }
        final events = snapshot.data!;
        if (events.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum evento registado.',
              style: TextStyle(color: _muted),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final event = events[index];
            final isFeatured = event.isBoosted ||
                event.snapshotData['featured'] == true ||
                event.snapshotData['is_featured'] == true;
            final isArchived = event.isArchived;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isFeatured ? _accent.withValues(alpha: 0.5) : _surfaceBorder,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: const Color(0xFF2B3542),
                      child: event.image.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: event.image,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.event_rounded,
                                color: _muted,
                              ),
                            )
                          : const Icon(Icons.event_rounded, color: _muted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.location.isNotEmpty
                              ? event.location
                              : 'Sem local indicado',
                          style: const TextStyle(color: _muted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: isFeatured ? 'Remover Destaque' : 'Destacar',
                    icon: Icon(
                      isFeatured ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isFeatured ? const Color(0xFFFFC857) : _muted,
                    ),
                    onPressed: () async {
                      unawaited(LotusProductFeedback.selection());
                      await event.reference.update({
                        'featured': !isFeatured,
                        'is_featured': !isFeatured,
                        'isBoosted': !isFeatured,
                      });
                    },
                  ),
                  IconButton(
                    tooltip: isArchived ? 'Restaurar' : 'Arquivar / Remover',
                    icon: Icon(
                      isArchived
                          ? Icons.unarchive_rounded
                          : Icons.archive_outlined,
                      color: isArchived ? _accent : const Color(0xFFFF5252),
                    ),
                    onPressed: () async {
                      unawaited(LotusProductFeedback.selection());
                      await event.reference.update({
                        'is_archived': !isArchived,
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminPromotersTab extends StatelessWidget {
  const _AdminPromotersTab({this.usersStream});

  final Stream<List<UsersRecord>>? usersStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UsersRecord>>(
      stream: usersStream ?? queryUsersRecord(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _accent));
        }
        final users = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final user = users[index];
            final isVerified = user.isVerified;
            final isBlocked = user.isBlocked;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _surfaceBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF2B3542),
                    backgroundImage: user.photoUrl.isNotEmpty
                        ? CachedNetworkImageProvider(user.photoUrl)
                        : null,
                    child: user.photoUrl.isEmpty
                        ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
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
                                user.displayName.isNotEmpty
                                    ? user.displayName
                                    : 'Utilizador',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                color: _accent,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email.isNotEmpty ? user.email : user.uid,
                          style: const TextStyle(color: _muted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: isVerified
                        ? 'Remover Verificação'
                        : 'Verificar Promoter',
                    icon: Icon(
                      isVerified
                          ? Icons.verified_user_rounded
                          : Icons.verified_user_outlined,
                      color: isVerified ? _accent : _muted,
                    ),
                    onPressed: () async {
                      unawaited(LotusProductFeedback.selection());
                      await user.reference.update({
                        'is_verified': !isVerified,
                      });
                    },
                  ),
                  IconButton(
                    tooltip: isBlocked ? 'Desbloquear' : 'Bloquear',
                    icon: Icon(
                      isBlocked
                          ? Icons.lock_open_rounded
                          : Icons.block_flipped,
                      color: isBlocked ? _muted : const Color(0xFFFF5252),
                    ),
                    onPressed: () async {
                      unawaited(LotusProductFeedback.selection());
                      await user.reference.update({
                        'is_blocked': !isBlocked,
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminRadarTab extends StatelessWidget {
  const _AdminRadarTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('teasers').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _accent));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum teaser registado no Radar.',
              style: TextStyle(color: _muted),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final title = data['title'] as String? ?? 'Teaser Sem Título';
            final status = data['status'] as String? ?? 'TEASER_ACTIVE';
            final isRevealed = status == 'REVEALED';

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isRevealed ? _accent.withValues(alpha: 0.4) : _surfaceBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRevealed ? Icons.lock_open_rounded : Icons.radar_rounded,
                      color: _accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isRevealed ? 'Revelado' : 'Em contagem decrescente',
                          style: TextStyle(
                            color: isRevealed ? _accent : const Color(0xFFFFC857),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isRevealed)
                    TextButton.icon(
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      label: const Text('Revelar'),
                      style: TextButton.styleFrom(
                        foregroundColor: _accent,
                      ),
                      onPressed: () async {
                        unawaited(LotusProductFeedback.selection());
                        await doc.reference.update({
                          'revealed': true,
                          'is_revealed': true,
                          'revealed_at': FieldValue.serverTimestamp(),
                        });
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
