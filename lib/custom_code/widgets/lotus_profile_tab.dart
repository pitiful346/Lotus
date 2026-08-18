import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lotus_core/lotus_core.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/custom_code/auth/lotus_account_actions.dart';
import '/custom_code/event_mapping/firestore_favorite_repository.dart';
import '/custom_code/onboarding/lotus_onboarding_repository.dart';
import '/custom_code/product_quality/lotus_product_quality.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/edit_profile/edit_profile_widget.dart';
import '/pages/saved/saved_widget.dart';
import '/pages/settings/settings_widget.dart';
import 'lotus_event_tiles.dart';

const _profileCities = ['Porto', 'Lisboa', 'Braga', 'Coimbra', 'Aveiro'];

class LotusProfileTab extends StatefulWidget {
  const LotusProfileTab({
    super.key,
    required this.onOpenFavorites,
    this.favoriteRepository,
    this.cityRepository,
    this.userId,
  });

  final VoidCallback onOpenFavorites;
  final FavoriteRepository? favoriteRepository;
  final LotusInitialCityRepository? cityRepository;
  final String? userId;

  @override
  State<LotusProfileTab> createState() => _LotusProfileTabState();
}

class _LotusProfileTabState extends State<LotusProfileTab> {
  late final FavoriteRepository _favorites;
  late final LotusInitialCityRepository _cities;

  @override
  void initState() {
    super.initState();
    _favorites = widget.favoriteRepository ?? FirestoreFavoriteRepository();
    _cities = widget.cityRepository ?? FirestoreLotusOnboardingRepository();
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId ?? currentUserUid;
    return SafeArea(
      bottom: false,
      child: ListView(
        key: const PageStorageKey('lotus-profile-scroll'),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Perfil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Definições',
                onPressed: () => context.pushNamed(SettingsWidget.routeName),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AuthUserStreamWidget(
            builder: (context) => _ProfileIdentity(
              name: currentUserDisplayName,
              email: currentUserEmail,
              photoUrl: currentUserPhoto,
            ),
          ),
          const SizedBox(height: 26),
          _ProfileAction(
            icon: Icons.edit_outlined,
            title: 'Editar perfil',
            subtitle: 'Foto, nome e dados pessoais',
            onTap: () => context.pushNamed(EditProfileWidget.routeName),
          ),
          _ProfileAction(
            icon: Icons.auto_awesome_outlined,
            title: 'Interesses',
            subtitle: 'Categorias usadas nas recomendações',
            onTap: () => context.pushNamed(SavedWidget.routeName),
          ),
          if (userId.isNotEmpty)
            StreamBuilder<String>(
              stream: _cities.watchInitialCity(userId),
              initialData: 'Porto',
              builder: (context, snapshot) => _ProfileAction(
                icon: Icons.location_city_outlined,
                title: 'Cidade inicial',
                subtitle: snapshot.data ?? 'Porto',
                onTap: () => _chooseCity(userId, snapshot.data ?? 'Porto'),
              ),
            ),
          if (userId.isNotEmpty)
            StreamBuilder<Set<String>>(
              stream: _favorites.watchFavoriteEventIds(userId),
              builder: (context, snapshot) => _ProfileAction(
                icon: Icons.favorite_border_rounded,
                title: 'Eventos favoritos',
                subtitle: snapshot.hasData
                    ? '${snapshot.data!.length} guardados'
                    : 'A carregar…',
                onTap: widget.onOpenFavorites,
              ),
            ),
          const SizedBox(height: 14),
          const _ProfileSectionTitle('Definições e privacidade'),
          _ProfileAction(
            icon: Icons.notifications_outlined,
            title: 'Notificações',
            subtitle: 'Preferências e frequência',
            onTap: () => context.pushNamed(SettingsWidget.routeName),
          ),
          _ProfileAction(
            icon: Icons.shield_outlined,
            title: 'Privacidade, termos e localização',
            subtitle: 'Controlos separados do perfil público',
            onTap: () => context.pushNamed(SettingsWidget.routeName),
          ),
          const SizedBox(height: 20),
          const LotusAccountActions(),
        ],
      ),
    );
  }

  Future<void> _chooseCity(String userId, String current) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: lotusSurface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cidade inicial',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              RadioGroup<String>(
                groupValue: current,
                onChanged: (value) => Navigator.pop(context, value),
                child: Column(
                  children: [
                    for (final city in _profileCities)
                      RadioListTile<String>(value: city, title: Text(city)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || selected == current) return;
    try {
      await _cities.updateInitialCity(userId, selected);
      unawaited(LotusProductFeedback.success());
    } catch (_) {
      unawaited(LotusProductFeedback.error());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível alterar a cidade.')),
        );
      }
    }
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
    required this.name,
    required this.email,
    required this.photoUrl,
  });

  final String name;
  final String email;
  final String photoUrl;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Semantics(
        image: photoUrl.isNotEmpty,
        label: 'Foto de perfil',
        child: CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFF25303C),
          backgroundImage: photoUrl.isEmpty
              ? null
              : CachedNetworkImageProvider(photoUrl),
          child: photoUrl.isEmpty
              ? Text(
                  _initials(name, email),
                  style: const TextStyle(
                    color: lotusQualityAccent,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : null,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        name.trim().isEmpty ? 'Utilizador Lotus' : name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 23,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 4),
      Text(email, style: const TextStyle(color: lotusQualityMuted)),
    ],
  );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
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
  Widget build(BuildContext context) => Card(
    color: lotusSurface,
    margin: const EdgeInsets.only(bottom: 9),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: lotusBorder),
    ),
    child: ListTile(
      minTileHeight: 64,
      onTap: onTap,
      leading: Icon(icon, color: lotusQualityAccent),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: lotusQualityMuted),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
    child: Text(
      title,
      style: const TextStyle(
        color: lotusQualityMuted,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

String _initials(String name, String email) {
  final source = name.trim().isEmpty ? email.split('@').first : name;
  final words = source
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  if (words.isEmpty) return 'L';
  return words.take(2).map((word) => word[0].toUpperCase()).join();
}
