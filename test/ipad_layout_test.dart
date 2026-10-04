import 'package:cwms_mobile/shared/adaptive_layout.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/workspace_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('window resize switches panels without losing scanned input',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1194, 834);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: TabletContent(
      child: SingleChildScrollView(
          child: AdaptiveSections(
        primary: TextField(key: const Key('scan'), controller: controller),
        secondary: const Text('Destination', key: Key('destination')),
        footer: Builder(
            builder: (context) => buildTwoButtonRow(
                context,
                ElevatedButton(onPressed: () {}, child: const Text('Confirm')),
                ElevatedButton(onPressed: () {}, child: const Text('Clear')))),
      )),
    ))));
    await tester.enterText(find.byKey(const Key('scan')), 'L0000000186');
    final scan = tester.getTopLeft(find.byKey(const Key('scan')));
    final destination = tester.getTopLeft(find.byKey(const Key('destination')));
    expect(destination.dx, greaterThan(scan.dx));
    expect(tester.takeException(), isNull);
    // iPad split screen has phone-like constraints; keep the same controllers.
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const Key('destination'))).dy,
        greaterThan(tester.getTopLeft(find.byKey(const Key('scan'))).dy));
    expect(controller.text, 'L0000000186');
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet sidebar is accessible and collapses in split screen',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1194, 834);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: WorkspaceNavigation(
      title: 'Workspace',
      destinations: [
        ListTile(title: const Text('Receiving'), onTap: () => opened = true)
      ],
      child: const Text('Operations'),
    ))));
    await tester.tap(find.text('Receiving'));
    expect(opened, isTrue);
    tester.view.physicalSize = const Size(600, 900);
    await tester.pumpAndSettle();
    expect(find.text('Receiving'), findsNothing);
    expect(find.text('Operations'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
