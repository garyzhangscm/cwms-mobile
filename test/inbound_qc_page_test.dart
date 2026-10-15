import 'dart:async';
import 'package:cwms_mobile/inbound/routes/inbound_qc.dart';
import 'package:cwms_mobile/inbound/services/inbound_qc_service.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request_item.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request_item_option.dart';
import 'package:cwms_mobile/inventory/models/qc_rule_item.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Inventory stock(int id, String item) => Inventory()
  ..id = id
  ..lpn = 'TEST-LPN'
  ..quantity = 5
  ..inboundQCRequired = true
  ..item = (Item()..name = item);

Future<void> openPage(
    WidgetTester tester, Future<List<Inventory>> Function(String) load,
    {Future<InboundQCRequests> Function(Inventory)? requests,
    void Function(QCInspectionRequest)? opened}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en', 'US'),
    supportedLocales: const [Locale('en', 'US')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      CWMSLocalizationsDelegate(),
    ],
    home: InboundQCPage(inventoryLoader: load, requestLoader: requests),
    routes: {
      'qc_inspection': (context) {
        opened?.call(
            ModalRoute.of(context)!.settings.arguments as QCInspectionRequest);
        return const Scaffold(body: Text('Inspection checkpoints'));
      }
    },
  ));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField), ' TEST-LPN ');
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

void main() {
  testWidgets('waits for selected inventory and honors cancellation',
      (tester) async {
    await openPage(
        tester, (_) async => [stock(1, 'ITEM-A'), stock(2, 'ITEM-B')]);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Select inventory for QC'), findsOneWidget);
    await tester.tap(find.text('cancel'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Start QC'))
            .onPressed,
        isNull);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('ITEM-B'));
    await tester.tap(find.widgetWithText(TextButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('ITEM-B'), findsOneWidget);
    expect(find.text('ITEM-A'), findsNothing);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Start QC'))
            .onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scan and focus change cannot start overlapping lookups',
      (tester) async {
    final lookup = Completer<List<Inventory>>();
    var calls = 0;
    await openPage(tester, (lpn) {
      expect(lpn, 'TEST-LPN');
      calls++;
      return lookup.future;
    });
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(calls, 1);
    lookup.complete([stock(1, 'ITEM-A')]);
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('ITEM-A'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing LPN has visible feedback', (tester) async {
    await openPage(tester, (_) async => []);
    await tester.pumpAndSettle();
    expect(find.text('No inventory found for LPN TEST-LPN.'), findsOneWidget);
  });

  testWidgets('empty task explains missing rules instead of silently clearing',
      (tester) async {
    await openPage(tester, (_) async => [stock(1, 'ITEM-A')],
        requests: (_) async => InboundQCRequests([QCInspectionRequest()]));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start QC'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no enabled inspection checks'), findsOneWidget);
    expect(find.text('ITEM-A'), findsOneWidget);
  });

  testWidgets('legacy warning is acknowledged before entering checkpoints',
      (tester) async {
    var opened = false;
    final request = QCInspectionRequest()
      ..qcInspectionRequestItems = [
        QCInspectionRequestItem()
          ..qcInspectionRequestItemOptions = [
            QCInspectionRequestItemOption()
              ..qcRuleItem = (QCRuleItem()..enabled = true)
          ]
      ];
    await openPage(tester, (_) async => [stock(1, 'ITEM-A')],
        requests: (_) async =>
            InboundQCRequests([request], recoveredLegacy: true),
        opened: (_) => opened = true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start QC'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Unfinished QC task'), findsOneWidget);
    expect(opened, false);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(opened, true);
    expect(find.text('Inspection checkpoints'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
