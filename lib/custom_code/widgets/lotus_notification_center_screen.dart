import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lotus_core/lotus_core.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/custom_code/notifications/firestore_notification_repository.dart';
import '/custom_code/notifications/lotus_deep_link_handler.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';

const _background = Color(0xFF080B10);
const _surface = Color(0xFF151B23);
const _surfaceBorder = Color(0xFF293342);
const _accent = Color(0xFFB7F34A);
const _muted = Color(0xFF9AA8B9);

class LotusNotificationCenterScreen extends StatefulWidget {
  const LotusNotificationCenterScreen({
    super.key,
    this.repository,
    this.userId,
    this.now,
  });

  static const routeName = 'LotusNotificationCenter';
  static const routePath = '/notifications';

  final NotificationRepository? repository;
  final String? userId;
  final DateTime Function()? now;

  @override
  State<LotusNotificationCenterScreen> createState() =>
      _LotusNotificationCenterScreenState();
}

class _LotusNotificationCenterScreenState
    extends State<LotusNotificationCenterScreen> {
  late final NotificationRepository _repo;
  bool _filterOnlyUnread = false;
  bool _isMarkingAll = false;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? FirestoreNotificationRepository();
  }

  DateTime get _currentTime => widget.now?.call() ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.userId ?? currentUserUid;

    if (currentUserId.isEmpty) {
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
          title: const Text(
            'Notificações',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: LotusStateView(
            kind: LotusStateKind.empty,
            title: 'Sessão necessária',
            message: 'Inicia sessão para veres o teu histórico de notificações.',
          ),
        ),
      );
    }

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
        title: const Text(
          'Notificações',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            key: const Key('notification-mark-all-btn'),
            tooltip: 'Marcar todas como lidas',
            icon: _isMarkingAll
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _accent,
                    ),
                  )
                : const Icon(Icons.done_all_rounded, color: _accent, size: 22),
            onPressed: _isMarkingAll ? null : () => _markAllAsRead(currentUserId),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: _repo.watchNotifications(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const LotusSkeletonList(itemCount: 5);
          }

          final all = snapshot.data ?? const <AppNotification>[];
          final notifications = _filterOnlyUnread
              ? all.where((n) => n.isUnread).toList()
              : all;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Todas (${all.length})',
                      isSelected: !_filterOnlyUnread,
                      onTap: () {
                        unawaited(LotusProductFeedback.selection());
                        setState(() => _filterOnlyUnread = false);
                      },
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Não lidas (${all.where((n) => n.isUnread).length})',
                      isSelected: _filterOnlyUnread,
                      onTap: () {
                        unawaited(LotusProductFeedback.selection());
                        setState(() => _filterOnlyUnread = true);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: LotusStateView(
                          kind: LotusStateKind.empty,
                          title: _filterOnlyUnread
                              ? 'Tudo em dia!'
                              : 'Sem notificações',
                          message: _filterOnlyUnread
                              ? 'Não tens notificações não lidas no momento.'
                              : 'Quando houver novidades dos teus promotores ou eventos favoritos, elas aparecerão aqui.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          return _NotificationCard(
                            notification: item,
                            now: _currentTime,
                            onTap: () => _handleNotificationTap(currentUserId, item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _markAllAsRead(String userId) async {
    setState(() => _isMarkingAll = true);
    unawaited(LotusProductFeedback.selection());
    try {
      await _repo.markAllAsRead(userId);
      unawaited(LotusProductFeedback.success());
    } catch (_) {
      unawaited(LotusProductFeedback.error());
    } finally {
      if (mounted) setState(() => _isMarkingAll = false);
    }
  }

  Future<void> _handleNotificationTap(
    String userId,
    AppNotification notification,
  ) async {
    unawaited(LotusProductFeedback.selection());
    if (notification.isUnread) {
      try {
        await _repo.markAsRead(
          userId: userId,
          notificationId: notification.id,
        );
      } catch (_) {}
    }

    if (!mounted) return;
    if (notification.deepLink != null && notification.deepLink!.isNotEmpty) {
      await LotusDeepLinkHandler.instance
          .handleUri(context, notification.deepLink);
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _accent : _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _accent : _surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF080B10) : Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.now,
    required this.onTap,
  });

  final AppNotification notification;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = notification.isUnread;
    final iconData = _iconForType(notification.type);
    final iconColor = _colorForType(notification.type);

    return Material(
      color: isUnread ? const Color(0xFF19212C) : _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isUnread
              ? _accent.withValues(alpha: 0.35)
              : _surfaceBorder.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: isUnread
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatRelativeTime(notification.createdAt, now),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) => switch (type.toLowerCase()) {
        'promoter_new_event' => Icons.campaign_rounded,
        'teaser_revealed' => Icons.radar_rounded,
        'favorite_cancelled' => Icons.event_busy_rounded,
        'favorite_changed' => Icons.update_rounded,
        'favorite_starting_soon' => Icons.timer_outlined,
        'recommendations_digest' => Icons.auto_awesome_rounded,
        _ => Icons.notifications_rounded,
      };

  Color _colorForType(String type) => switch (type.toLowerCase()) {
        'promoter_new_event' => const Color(0xFF60A5FA),
        'teaser_revealed' => _accent,
        'favorite_cancelled' => const Color(0xFFF87171),
        'favorite_changed' => const Color(0xFFFBBF24),
        'favorite_starting_soon' => const Color(0xFFA78BFA),
        _ => _accent,
      };

  String _formatRelativeTime(DateTime time, DateTime current) {
    final diff = current.difference(time);
    if (diff.inSeconds < 60) return 'Agora mesmo';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours} h';
    if (diff.inDays < 7) return 'Há ${diff.inDays} d';
    return DateFormat('dd/MM/yyyy').format(time.toLocal());
  }
}
