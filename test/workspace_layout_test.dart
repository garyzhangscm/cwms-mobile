import 'package:cwms_mobile/shared/workspace_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0, 1024.0]) {
    testWidgets('Workspace supports width $width and large text',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: MediaQuery(
        data: MediaQueryData(
            size: Size(width, 900), textScaler: TextScaler.linear(1.5)),
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const WorkspaceHeader(
                title: 'Ready for the work ahead.',
                subtitle: 'Choose an operation to get started.'),
            WorkspaceGrid(children: [
              WorkspaceTile(
                  title: 'Production line check in',
                  identity: 'production',
                  index: 0,
                  onTap: () => tapped = true),
              WorkspaceTile(
                  title: 'Inventory management',
                  identity: 'inventory',
                  index: 1,
                  onTap: () {}),
            ]),
          ]),
        )),
      ))));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Production line check in'));
      await tester.tap(find.text('Production line check in'));
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
