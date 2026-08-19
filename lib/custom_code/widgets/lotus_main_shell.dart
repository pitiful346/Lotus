import 'dart:async';

import 'package:flutter/material.dart';

import '/custom_code/product_quality/lotus_product_quality.dart';
import 'lotus_explore_tab.dart';
import 'lotus_favorites_tab.dart';
import 'lotus_home_experience.dart';
import 'lotus_profile_tab.dart';

class LotusMainShell extends StatefulWidget {
  const LotusMainShell({
    super.key,
    this.mapTab,
    this.exploreTab,
    this.favoritesTab,
    this.profileTab,
  });

  final Widget? mapTab;
  final Widget? exploreTab;
  final Widget? favoritesTab;
  final Widget? profileTab;

  @override
  State<LotusMainShell> createState() => _LotusMainShellState();
}

class _LotusMainShellState extends State<LotusMainShell> {
  static const _navigationClearance = 108.0;
  int _selectedIndex = 0;
  late final List<Widget?> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [widget.mapTab ?? const LotusHomeExperience(), null, null, null];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(4, (index) {
          final tab = _tabs[index] ?? const SizedBox.shrink();
          return index == 0
              ? tab
              : Padding(
                  padding: const EdgeInsets.only(bottom: _navigationClearance),
                  child: tab,
                );
        }),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          key: const Key('lotus-floating-navigation-surface'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xF2161C24),
                border: Border.all(color: const Color(0x292F3A48)),
                borderRadius: BorderRadius.circular(28),
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  height: 68,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  indicatorColor: lotusQualityAccent.withValues(alpha: 0.18),
                  indicatorShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    return IconThemeData(
                      color: states.contains(WidgetState.selected)
                          ? lotusQualityAccent
                          : const Color(0xFFC2CCD8),
                      size: states.contains(WidgetState.selected) ? 25 : 23,
                    );
                  }),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    return TextStyle(
                      color: states.contains(WidgetState.selected)
                          ? lotusQualityAccent
                          : const Color(0xFFC2CCD8),
                      fontSize: 12,
                      fontWeight: states.contains(WidgetState.selected)
                          ? FontWeight.w700
                          : FontWeight.w500,
                    );
                  }),
                ),
                child: NavigationBar(
                  key: const Key('lotus-main-navigation'),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectTab,
                  animationDuration: const Duration(milliseconds: 180),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  indicatorColor: lotusQualityAccent.withValues(alpha: 0.18),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map_rounded),
                      label: 'Mapa',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.explore_outlined),
                      selectedIcon: Icon(Icons.explore_rounded),
                      label: 'Explorar',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_border_rounded),
                      selectedIcon: Icon(Icons.favorite_rounded),
                      label: 'Favoritos',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'Perfil',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    unawaited(LotusProductFeedback.selection());
    setState(() {
      _tabs[index] ??= _buildTab(index);
      _selectedIndex = index;
    });
  }

  Widget _buildTab(int index) => switch (index) {
    0 => widget.mapTab ?? const LotusHomeExperience(),
    1 => widget.exploreTab ?? const LotusExploreTab(),
    2 => widget.favoritesTab ?? const LotusFavoritesTab(),
    3 =>
      widget.profileTab ??
          LotusProfileTab(onOpenFavorites: () => _selectTab(2)),
    _ => throw RangeError.index(index, _tabs),
  };
}
