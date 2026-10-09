import 'package:cwms_mobile/auth/models/menu.dart';
import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/auth/models/menu_sub_group.dart';
import 'package:cwms_mobile/sub_menus.dart';
import 'package:cwms_mobile/workorder/routes/defective_machine_selection.dart';
import 'package:cwms_mobile/common/models/reason_code.dart';
import 'package:cwms_mobile/common/models/unit_of_measure.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/models/item_unit_of_measure.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/states/profile_change_notifier.dart';
import 'package:cwms_mobile/workorder/models/bill_of_material.dart';
import 'package:cwms_mobile/workorder/models/defective_production.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/routes/work_order_produce_inventory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

InventoryStatus status(String name,
        {String? description, bool required = false}) =>
    InventoryStatus()
      ..id = 9
      ..name = name
      ..description = description
      ..reasonRequiredWhenProducing = required
      ..availableStatusFlag = false;

Future<void> openForm(WidgetTester tester, List<InventoryStatus> statuses,
    {bool defective = true, bool autoPromptReason = false}) async {
  Global.currentUser = User()..username = 'TEST';
  final unit = ItemUnitOfMeasure()
    ..id = 1
    ..quantity = 1
    ..unitOfMeasure = (UnitOfMeasure()..name = 'PCS');
  final pallet = ItemUnitOfMeasure()
    ..id = 99
    ..quantity = 100
    ..unitOfMeasure = (UnitOfMeasure()..name = 'PL');
  final package = ItemPackageType()
    ..id = 2
    ..name = 'Main'
    ..description = 'Main'
    ..itemUnitOfMeasures = [pallet, unit]
    ..defaultWorkOrderReceivingUOM = pallet;
  final order = WorkOrder()
    ..id = 3
    ..number = 'TEST-ONLY'
    ..consumeByBom = BillOfMaterial()
    ..item = (Item()
      ..name = 'TEST-ITEM'
      ..description = 'Test item'
      ..itemPackageTypes = [package]);
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => UserModel(),
      child: MaterialApp(
        locale: const Locale('en', 'US'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          CWMSLocalizationsDelegate()
        ],
        onGenerateRoute: (_) => MaterialPageRoute(
          settings: RouteSettings(
              arguments: {'workOrder': order, 'productionLine': null}),
          builder: (_) => WorkOrderProduceInventoryPage(
              defective: defective,
              autoPromptReason: autoPromptReason,
              statusLoader: () async => statuses,
              reasonLoader: () async => [
                    ReasonCode()
                      ..id = 42
                      ..name = 'SHORT_SHOT'
                  ]),
        ),
      )));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Work Order menu opens the independent Defective flow',
      (tester) async {
    Global.currentUser = User()..username = 'TEST';
    final group = MenuSubGroup()
      ..name = 'Work Order'
      ..text = 'Work Order'
      ..menus = [
        Menu()
          ..link = 'work_order_produce'
          ..text = 'Produce'
      ];
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ChangeNotifierProvider(
        create: (_) => UserModel(),
        child: MaterialApp(
          locale: const Locale('en', 'US'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            CWMSLocalizationsDelegate()
          ],
          routes: {
            'work_order_produce': (_) => const Text('Produce route'),
            'work_order_defective': (_) =>
                DefectiveMachineSelectionPage(loader: () async => [])
          },
          onGenerateRoute: (_) => MaterialPageRoute(
              settings: RouteSettings(arguments: group),
              builder: (_) => SubMenus()),
        )));
    await tester.pumpAndSettle();
    expect(find.text('Produce'), findsOneWidget);
    await tester.tap(find.text('Defective'));
    await tester.pumpAndSettle();
    expect(find.byType(DefectiveMachineSelectionPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('Defective inherits Produce access and does not mutate server menus',
      () {
    final original = [
      Menu()..link = 'work_order_produce',
      Menu()..link = 'work_order_qc'
    ];
    final menus = withDefectiveProductionMenu(original);
    expect(menus.map((m) => m.link),
        ['work_order_produce', 'work_order_defective', 'work_order_qc']);
    expect(original.length, 2);
    expect(withDefectiveProductionMenu(menus).length, 3);
    expect(withDefectiveProductionMenu([Menu()..link = 'work_order_qc']).length,
        1);
  });
  test('DMG and Damaged use exact warehouse status, never Available', () {
    for (final damaged in [
      status('DMG', description: 'Damaged'),
      status('Damaged')
    ]) {
      expect(findDefectiveInventoryStatus([status('Available'), damaged]),
          same(damaged));
    }
    expect(findDefectiveInventoryStatus([status('Available')]), isNull);
    expect(findDefectiveInventoryStatus([status('DMG'), status('Damaged')]),
        isNull);
    expect(
        findDefectiveInventoryStatus(
            [status('DMG')..availableStatusFlag = true]),
        isNull);
  });
  testWidgets(
      'Defective locks DMG, allows quantity input and displays required reasons',
      (tester) async {
    await openForm(tester, [
      status('Available'),
      status('DMG', description: 'Damaged', required: true)
    ]);
    expect(find.text('DMG · Damaged'), findsOneWidget);
    expect(find.byType(DropdownButton<InventoryStatus>), findsNothing);
    expect(find.byKey(const Key('defective-reason-picker')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('defective-quantity')), '5');
    expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('defective-quantity')))
            .controller!
            .text,
        '5');
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Confirm Defective'));
    await tester.tap(find.text('Confirm Defective'));
    await tester.pumpAndSettle();
    // Empty LPN validation blocks submission without any network request.
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Defective prompts for a reason even when DMG flags are N/A and defaults to PCS',
      (tester) async {
    await openForm(tester, [status('DMG')], autoPromptReason: true);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('SHORT_SHOT'), findsOneWidget);
    await tester.tap(find.text('SHORT_SHOT'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'SHORT_SHOT'), findsOneWidget);
    final selected = tester
        .widget<DropdownButton<ItemUnitOfMeasure>>(
            find.byKey(const Key('defective-unit')))
        .value;
    expect(selected!.unitOfMeasure!.name, 'PCS');
    expect(selected.quantity, 1);
    await tester.enterText(find.byKey(const Key('defective-quantity')), '7');
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.byKey(const Key('defective-reason-picker')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('Pieces default uses configured conversion and never fabricates a unit',
      () {
    final pl = ItemUnitOfMeasure()
      ..quantity = 100
      ..unitOfMeasure = (UnitOfMeasure()..name = 'PL');
    final pieces = ItemUnitOfMeasure()
      ..quantity = 1
      ..unitOfMeasure = (UnitOfMeasure()..name = 'Pieces');
    expect(findDefectivePiecesUnit([pl, pieces]), same(pieces));
    expect(findDefectivePiecesUnit([pl]), isNull);
    expect(findDefectivePiecesUnit([pieces..quantity = 0]), isNull);
  });
  testWidgets('missing damaged configuration blocks confirmation',
      (tester) async {
    await openForm(tester, [status('Available')]);
    expect(find.textContaining('A unique DMG'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Confirm Defective'));
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('required reason blocks submission even with quantity and LPN',
      (tester) async {
    await openForm(tester, [status('DMG', required: true)]);
    await tester.enterText(find.byKey(const Key('defective-quantity')), '5');
    await tester.enterText(find.byType(TextFormField).last, 'TEST-LPN');
    await tester.ensureVisible(find.text('Confirm Defective'));
    await tester.tap(find.text('Confirm Defective'));
    await tester.pumpAndSettle();
    expect(find.textContaining('is required, please choose the reason'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('existing produce request retains DMG, quantity and reason ID',
      (tester) async {
    final damaged = status('DMG');
    await openForm(tester, [damaged]);
    final dynamic state =
        tester.state(find.byType(WorkOrderProduceInventoryPage));
    final package = ItemPackageType()..id = 2;
    final reason = ReasonCode()..id = 42;
    final transaction = state.generateWorkOrderProduceTransaction(
        'TEST-LPN', damaged, package, 5, reason);
    expect(transaction.workOrder.number, 'TEST-ONLY');
    expect(
        transaction.workOrderProducedInventories.single.inventoryStatusId, 9);
    expect(transaction.workOrderProducedInventories.single.quantity, 5);
    expect(transaction.toJson()['reasonCodeId'], 42);
    expect(tester.takeException(), isNull);
  });
  testWidgets('normal Produce still provides status selection', (tester) async {
    await openForm(tester, [status('Available'), status('DMG')],
        defective: false);
    expect(find.byType(DropdownButton<InventoryStatus>), findsOneWidget);
    expect(find.byKey(const Key('defective-quantity')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('blank defective quantity validates without a parsing crash',
      (tester) async {
    await openForm(tester, [status('DMG')]);
    await tester.ensureVisible(find.text('Confirm Defective'));
    await tester.tap(find.text('Confirm Defective'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a quantity greater than zero'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Confirm Defective'))
            .onPressed,
        isNotNull);
  });
}
