import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lotus/custom_code/widgets/lotus_main_shell.dart';

void main() {
  testWidgets('main navigation exposes four persistent destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LotusMainShell(
          mapTab: _StatefulTab('map-content'),
          exploreTab: _StatefulTab('explore-content'),
          favoritesTab: _StatefulTab('favorites-content'),
          profileTab: _StatefulTab('profile-content'),
        ),
      ),
    );

    expect(find.text('map-content:0').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Mapa'));
    await tester.tap(find.byKey(const Key('map-content-increment')));
    await tester.pump();
    expect(find.text('map-content:1').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Explorar'));
    await tester.pump();
    expect(find.text('explore-content:0').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Favoritos'));
    await tester.pump();
    expect(find.text('favorites-content:0').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Perfil'));
    await tester.pump();
    expect(find.text('profile-content:0').hitTestable(), findsOneWidget);

    await tester.tap(find.text('Mapa'));
    await tester.pump();
    expect(find.text('map-content:1').hitTestable(), findsOneWidget);
  });

  testWidgets('main navigation uses the floating dark capsule treatment', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LotusMainShell(
          mapTab: _StatefulTab('map-content'),
          exploreTab: _StatefulTab('explore-content'),
          favoritesTab: _StatefulTab('favorites-content'),
          profileTab: _StatefulTab('profile-content'),
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.extendBody, isTrue);
    expect(
      find.byKey(const Key('lotus-floating-navigation-surface')),
      findsOne,
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('lotus-main-navigation')),
        matching: find.byType(SafeArea),
      ),
      findsOneWidget,
    );

    final navigation = tester.widget<NavigationBar>(
      find.byKey(const Key('lotus-main-navigation')),
    );
    expect(navigation.destinations, hasLength(4));
    expect(navigation.backgroundColor, Colors.transparent);

    final navigationTheme = tester.widget<NavigationBarTheme>(
      find.byType(NavigationBarTheme),
    );
    final selectedIcon = navigationTheme.data.iconTheme!.resolve({
      WidgetState.selected,
    });
    final inactiveIcon = navigationTheme.data.iconTheme!.resolve({});
    expect(selectedIcon!.color, const Color(0xFFB7F34A));
    expect(inactiveIcon!.color, const Color(0xFFC2CCD8));
  });
}

class _StatefulTab extends StatefulWidget {
  const _StatefulTab(this.label);

  final String label;

  @override
  State<_StatefulTab> createState() => _StatefulTabState();
}

class _StatefulTabState extends State<_StatefulTab> {
  var _value = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${widget.label}:$_value'),
        IconButton(
          key: Key('${widget.label}-increment'),
          onPressed: () => setState(() => _value += 1),
          icon: const Icon(Icons.add),
        ),
      ],
    ),
  );
}
