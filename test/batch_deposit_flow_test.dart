import 'package:cwms_mobile/shared/scanning/scan_feedback.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/routes/inventory_batch_deposit.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';

Map<String, dynamic> stock(int id, String lpn, int? destination) => {
      'id': id,
      'lpn': lpn,
      'quantity': 36,
      'locationId': 99,
      'item': {'id': 1, 'name': 'DEMO-ITEM'},
      'inventoryStatus': {'id': 1, 'name': 'AVAILABLE'},
      'inventoryMovements': [
        if (destination != null)
          {'id': id + 100, 'locationId': destination, 'sequence': 1}
      ],
    };

class DepositAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  List<Map<String, dynamic>> inventory = [
    stock(1, 'L000000001', 55),
    stock(2, 'L000000002', 55)
  ];
  Completer<void>? locationGate, moveGate;
  bool locationFails = false, moveTimeout = false, rejectMove = false;
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? body, Future<void>? cancel) async {
    calls.add(o);
    dynamic data;
    var result = 0;
    if (o.path == '/inventory/inventories') {
      data = inventory;
    } else if (o.path == '/layout/locations') {
      data = [
        {'id': 99, 'name': o.queryParameters['name'], 'enabled': true}
      ];
    } else if (o.path.startsWith('/layout/locations/')) {
      await locationGate?.future;
      result = locationFails ? 1 : 0;
      final id = int.parse(o.path.split('/').last);
      data = {'id': id, 'name': 'STAGE-$id', 'enabled': true};
    } else if (o.path == '/inventory/inventory/move') {
      await moveGate?.future;
      if (moveTimeout)
        throw DioException(
            requestOptions: o, type: DioExceptionType.receiveTimeout);
      result = rejectMove ? 1 : 0;
      data = [];
    } else {
      throw StateError('Unexpected request ${o.path}');
    }
    return ResponseBody.fromString(
        jsonEncode({
          'result': result,
          'message': result == 0 ? '' : 'Location unavailable',
          'data': data
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late DepositAdapter adapter;
  setUp(() {
    Global.currentWarehouse = Warehouse()..id = 1;
    Global.currentServer = CWMSSiteInformation()
      ..url = 'https://example.test/api/';
    Global.lastLoginRFCode = 'RF-TEST';
    CWMSHttpClient.resetDio();
    adapter = DepositAdapter();
    CWMSHttpClient.getDio().httpClientAdapter = adapter;
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en', 'US'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          CWMSLocalizationsDelegate()
        ],
        home: InventoryBatchDepositPage()));
  }

  Iterable<RequestOptions> moves() =>
      adapter.calls.where((o) => o.method == 'POST');
  testWidgets(
      'awaits and deduplicates destinations; Deposit All cannot be started twice',
      (tester) async {
    adapter.locationGate = Completer<void>();
    await open(tester);
    for (var n = 0; n < 12; n++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Deposit All'))
            .onPressed,
        isNull);
    expect(adapter.calls.where((o) => o.path == '/layout/locations/55'),
        hasLength(1));
    adapter.locationGate!.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('STAGE-55'), findsNWidgets(2));
    adapter.moveGate = Completer<void>();
    await tester.tap(find.text('Deposit All'));
    for (var n = 0; n < 12; n++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(moves(), hasLength(2));
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Deposit All'))
            .onPressed,
        isNull);
    await tester.tap(find.text('Deposit All'));
    expect(moves(), hasLength(2));
    adapter.moveGate!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('selected deposit moves only checked LPN', (tester) async {
    await open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile).first);
    await tester.pump();
    await tester.tap(find.text('Deposit Selected LPN'));
    await tester.pumpAndSettle();
    expect(moves(), hasLength(1));
    expect(moves().single.queryParameters['inventoryId'], 1);
    expect(find.byType(CheckboxListTile), findsOneWidget);
  });
  testWidgets('same LPN with different assigned destinations keeps each target',
      (tester) async {
    adapter.inventory = [
      stock(1, 'L000000001', 55),
      stock(2, 'L000000001', 56)
    ];
    await open(tester);
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsOneWidget);
    await tester.tap(find.text('Deposit All'));
    await tester.pumpAndSettle();
    expect(moves(), hasLength(2));
    expect(moves().map((m) => jsonDecode(m.data as String)['id']), [55, 56]);
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing destination asks once; cancelling makes no movement',
      (tester) async {
    adapter.inventory = [stock(1, 'L000000001', null)];
    await open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deposit All'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(moves(), isEmpty);
    await tester.tap(find
        .descendant(
            of: find.byType(AlertDialog), matching: find.byType(ElevatedButton))
        .first);
    await tester.pumpAndSettle();
    expect(moves(), isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'destination lookup failure is visible and blocks deposits until reloaded',
      (tester) async {
    adapter.locationFails = true;
    await open(tester);
    await tester.pumpAndSettle();
    expect(find.text('Could not load deposit inventory. Tap to retry.'),
        findsOneWidget);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Deposit All'))
            .onPressed,
        isNull);
    expect(moves(), isEmpty);
    adapter.locationFails = false;
    await tester
        .tap(find.text('Could not load deposit inventory. Tap to retry.'));
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
  });
  testWidgets(
      'two rejected LPNs turn red and alarm twice, rebuild stays silent',
      (tester) async {
    var alarms = 0;
    ScanFeedback.failurePlayer = () async {
      alarms++;
    };
    addTearDown(() {
      ScanFeedback.failurePlayer = null;
    });
    adapter.rejectMove = true;
    await open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deposit All'));
    await tester.pumpAndSettle();
    expect(alarms, 2);
    expect(moves(), hasLength(2));
    final failures = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .where((tile) => tile.tileColor == Colors.red.shade50);
    expect(failures.length, 2);
    await tester.pump();
    await tester.pump();
    expect(alarms, 2);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'uncertain move is visible, never automatically retried or left spinning',
      (tester) async {
    adapter.inventory = [stock(1, 'L000000001', 55)];
    adapter.moveTimeout = true;
    var alarms = 0;
    ScanFeedback.failurePlayer = () async {
      alarms++;
    };
    addTearDown(() {
      ScanFeedback.failurePlayer = null;
    });
    await open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deposit All'));
    await tester.pumpAndSettle();
    expect(moves(), hasLength(1));
    expect(find.textContaining('Pending confirmation'), findsOneWidget);
    expect(alarms, 0);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'leaving during destination hydration does not update disposed page',
      (tester) async {
    adapter.locationGate = Completer<void>();
    await open(tester);
    for (var n = 0; n < 12; n++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpWidget(const SizedBox());
    adapter.locationGate!.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
