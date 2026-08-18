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
