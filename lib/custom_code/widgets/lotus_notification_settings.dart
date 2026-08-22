import '/auth/firebase_auth/auth_util.dart';
import '/custom_code/notifications/firebase_notification_coordinator.dart';
import '/custom_code/notifications/firestore_notification_preferences_repository.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';
import 'dart:async';

class LotusNotificationSettings extends StatefulWidget {
  const LotusNotificationSettings({super.key});

  @override
  State<LotusNotificationSettings> createState() =>
      _LotusNotificationSettingsState();
}

class _LotusNotificationSettingsState extends State<LotusNotificationSettings> {
  final _repository = FirestoreNotificationPreferencesRepository();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final userId = currentUserUid;
    if (userId.isEmpty) {
      return const _NotificationMessage(
        message: 'Inicia sessão para configurar notificações.',
      );
    }

    return StreamBuilder<NotificationPreferences>(
      stream: _repository.watch(userId),
      initialData: const NotificationPreferences(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 220,
            child: LotusSkeletonList(itemCount: 3, compact: true),
          );
        }
        if (snapshot.hasError) {
          return const LotusStateView(
            compact: true,
            kind: LotusStateKind.offline,
            title: 'Definições indisponíveis',
            message: 'Verifica a ligação para alterar as notificações.',
          );
        }
        final preferences = snapshot.data ?? const NotificationPreferences();
        return Container(
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(
              FlutterFlowTheme.of(context).designToken.radius.lg,
            ),
          ),
          padding: EdgeInsets.all(
            FlutterFlowTheme.of(context).designToken.spacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NotificationToggle(
                icon: Icons.campaign_outlined,
                title: 'Promotores seguidos',
                subtitle: 'Novos eventos publicados por promotores que segues',
                value: preferences.followedPromoters,
                enabled: !_saving,
                onChanged: (value) => _save(
                  userId,
                  preferences.copyWith(followedPromoters: value),
                ),
              ),
              const Divider(),
              _NotificationToggle(
                icon: Icons.radar_outlined,
                title: 'Radar & Reveals',
                subtitle: 'Avisos quando os teasers que acompanhas forem revelados',
                value: preferences.radarReveals,
                enabled: !_saving,
                onChanged: (value) => _save(
                  userId,
                  preferences.copyWith(radarReveals: value),
                ),
              ),
              const Divider(),
              _NotificationToggle(
                icon: Icons.favorite_outline_rounded,
                title: 'Alterações nos favoritos',
                subtitle: 'Mudanças de data, local ou cancelamento',
                value: preferences.favoriteEventUpdates,
                enabled: !_saving,
                onChanged: (value) => _save(
                  userId,
                  preferences.copyWith(favoriteEventUpdates: value),
                ),
              ),
              const Divider(),
              _NotificationToggle(
                icon: Icons.event_available_rounded,
                title: 'Eventos próximos',
                subtitle: 'Um lembrete 24 horas antes dos teus favoritos',
                value: preferences.upcomingFavoriteEvents,
                enabled: !_saving,
                onChanged: (value) => _save(
                  userId,
                  preferences.copyWith(upcomingFavoriteEvents: value),
                ),
              ),
              const Divider(),
              _NotificationToggle(
                icon: Icons.auto_awesome_outlined,
                title: 'Recomendações',
                subtitle: 'No máximo um resumo por semana',
                value: preferences.recommendations,
                enabled: !_saving,
                onChanged: (value) =>
                    _save(userId, preferences.copyWith(recommendations: value)),
              ),
              const Divider(),
              _NotificationToggle(
                icon: Icons.notifications_none_rounded,
                title: 'Marketing e Novidades',
                subtitle: 'Novidades exclusivas sobre o ecossistema Lotus',
                value: preferences.marketing,
                enabled: !_saving,
                onChanged: (value) =>
                    _save(userId, preferences.copyWith(marketing: value)),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.bedtime_outlined,
                    size: 16,
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Silêncio entre as 22:00 e as 08:00 · máximo de 3 por dia',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save(String userId, NotificationPreferences preferences) async {
    setState(() => _saving = true);
    try {
      await _repository.save(userId: userId, preferences: preferences);
      if (preferences.hasAnySubscription) {
        final authorized = await FirebaseNotificationCoordinator.instance
            .requestAuthorizationAndRegister(userId);
        if (!authorized && mounted) {
          _showMessage(
            'Preferências guardadas. Ativa as notificações nas definições do dispositivo.',
          );
        }
      } else {
        await FirebaseNotificationCoordinator.instance.unregisterCurrentDevice(
          userId,
        );
      }
      unawaited(LotusProductFeedback.success());
    } catch (_) {
      unawaited(LotusProductFeedback.error());
      if (mounted) {
        _showMessage('Não foi possível guardar esta preferência.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _NotificationToggle extends StatelessWidget {
  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      toggled: value,
      enabled: enabled,
      label: '$title. $subtitle',
      onTap: enabled ? () => onChanged(!value) : null,
      child: ExcludeSemantics(
        child: Row(
          children: [
            Icon(icon, color: FlutterFlowTheme.of(context).primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: FlutterFlowTheme.of(context).labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                      color: FlutterFlowTheme.of(context).secondaryText,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: FlutterFlowTheme.of(context).primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationMessage extends StatelessWidget {
  const _NotificationMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, style: FlutterFlowTheme.of(context).bodyMedium),
    );
  }
}
