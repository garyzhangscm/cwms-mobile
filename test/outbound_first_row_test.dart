import 'package:cwms_mobile/auth/models/menu.dart';
import 'package:cwms_mobile/auth/models/menu_sub_group.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/workspace_ui.dart';
import 'package:cwms_mobile/sub_menus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

void main() {
  testWidgets('Outbound opens with Wave then Manual Pick and collapses duplicate links', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('cwms_mobile/rfid'), (_) async => 'unsupported',
    );
    final group = MenuSubGroup()..text = 'Outbound';
    for (final link in ['pick_by_order', 'order_manual_pick', 'pick_by_wave', 'order_manual_pick']) {
      group.menus.add(Menu()..link = link..text = link);
    }
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      localizationsDelegates: const [CWMSLocalizationsDelegate()],
      home: const Scaffold(),
      routes: {
        'operations': (_) => SubMenus(),
        for (final menu in group.menus)
          menu.link!: (_) => Scaffold(body: Text('opened ${menu.link}')),
      },
    ));
    await tester.pumpAndSettle();
    key.currentState!.pushNamed('operations', arguments: group);
    await tester.pumpAndSettle();
    final tiles = find.byType(WorkspaceTile);
    expect(tester.widgetList<WorkspaceTile>(tiles).map((tile) => tile.title),
        ['Pick By Wave', 'Manual Pick', 'pick_by_order']);
    for (final index in [0, 1]) {
      await tester.tap(tiles.at(index));
      await tester.pumpAndSettle();
      expect(find.text('opened ${['pick_by_wave', 'order_manual_pick'][index]}'), findsOneWidget);
      key.currentState!.pop();
      await tester.pumpAndSettle();
    }
  });
}
