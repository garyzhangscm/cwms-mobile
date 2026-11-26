import 'dart:convert';
import 'dart:typed_data';

import 'package:cwms_mobile/outbound/models/wave.dart';
import 'package:cwms_mobile/outbound/routes/reserve_wave_pick.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaveAdapter implements HttpClientAdapter {
  WaveAdapter(this.pallets, {this.interruptSecond = false});

  final Map<String, int> pallets;
  final bool interruptSecond;
  final requests = <Map<String, dynamic>>[];
  final remaining = {301: 48, 302: 48};
  final completed = <String>{};
  final previewLimits = <int, int>{};
  final previews = <int>[];
  final picked = <Map<String, dynamic>>[];
  String inventoryLpn = 'PALLET48';
  int relabels = 0;
  bool loseRelabelReply = false;
  Map<String, dynamic> get sourceInventory => {
        'id': 55,
        'lpn': inventoryLpn,
        'locationId': 12,
        'item': {'id': 101},
        'quantity': pallets[inventoryLpn],
      };

  Map<String, dynamic> get state => {
        'managed': true,
        'state': 'READY',
        'lines': [
          for (final line in remaining.entries)
            {
              'item_id': 101,
              'shipment_line_id': line.key,
              'shipment_number': line.key == 301 ? 'TEST-SHIP-A' : 'TEST-SHIP-B',
              'wave_reserved': line.value,
            }
        ],
      };

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    dynamic data = state;
    if (options.path == 'outbound/picks') {
      data = [
        for (final lineId in remaining.keys)
          {'id': lineId, 'shipmentLineId': lineId}
      ];
    } else if (options.path.endsWith('inventory/inventory/55')) {
      data = sourceInventory;
    } else if (options.path.endsWith('/55/relabel')) {
      expect(options.queryParameters['mergeWithExistingInventory'], false);
      relabels++;
      final label = options.queryParameters['newLPN'] as String;
      pallets[label] = pallets.remove(inventoryLpn)!;
      inventoryLpn = label;
      if (loseRelabelReply) {
        throw DioException(
            requestOptions: options, type: DioExceptionType.receiveTimeout);
      }
      data = sourceInventory;
    } else if (options.path.endsWith('inventory/inventories')) {
      final lpn = options.queryParameters['lpn'];
      data = lpn == null
          ? picked.toList()
          : lpn == inventoryLpn && pallets.containsKey(lpn)
              ? [sourceInventory]
              : <Map<String, dynamic>>[];
    } else if (options.path.endsWith('/items/101')) {
      data = {
        'id': 101,
        'name': 'TEST-SKU',
        'defaultItemPackageType': {
          'id': 1,
          'stockItemUnitOfMeasure': {'id': 1, 'quantity': 1},
          'itemUnitOfMeasures': [
            {
              'id': 2,
              'quantity': 48,
              'unitOfMeasure': {'id': 2, 'name': 'PALLET'}
            }
          ]
        }
      };
    } else if (options.path.endsWith('/scan-preview')) {
      final lpn = options.queryParameters['sourceLpn'] as String;
      final line = options.queryParameters['shipmentLineId'] as int;
      previews.add(line);
      data = {
        'sourceQuantity': pallets[lpn],
        'pickableQuantity': previewLimits[line] ?? remaining[line]
      };
    } else if (options.path.endsWith('/scan')) {
      final request = Map<String, dynamic>.from(options.data as Map);
      requests.add(request);
      if (completed.add(request['requestId'] as String)) {
        final source = request['sourceLpn'] as String;
        final line = request['shipmentLineId'] as int;
        final qty = request['quantity'] as int;
        expect(pallets[source], request['expectedQuantity']);
        remaining[line] = remaining[line]! - qty;
        final newLpn = request['newLpn'] as String;
        picked.add({
          'pickId': line,
          'lpn': newLpn.isEmpty ? source : newLpn,
          'quantity': qty,
        });
        pallets[source] = pallets[source]! - qty;
        if (interruptSecond && requests.length == 2) {
          throw DioException(
              requestOptions: options, type: DioExceptionType.receiveTimeout);
        }
      }
      data = {'completed': true};
    }
    return ResponseBody.fromString(jsonEncode({'result': 0, 'data': data}), 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

Future<void> openWave(WidgetTester tester, WaveAdapter adapter) async {
  SharedPreferences.setMockInitialValues({});
  Global.currentServer = CWMSSiteInformation()
    ..url = 'http://example.test:4200/api/';
  Global.currentWarehouse = Warehouse()..id = 1;
  CWMSHttpClient.resetDio();
  CWMSHttpClient.getDio().httpClientAdapter = adapter;
  final wave = Wave()
    ..id = 17
    ..number = 'TEST-WAVE';
  await tester.pumpWidget(
      MaterialApp(home: ReserveWavePickPage(wave: wave, data: adapter.state)));
  await tester.pumpAndSettle();
  expect(find.text('TEST-SKU'), findsOneWidget);
  expect(
      find.text('${adapter.remaining.values.reduce((a, b) => a + b)} to pick'),
      findsOneWidget);
}

Future<void> scan(WidgetTester tester, String lpn) async {
  await tester.enterText(
      find.widgetWithText(TextField, 'Scan pallet LPN'), lpn);
  await tester.tap(find.byTooltip('Check pallet'));
  await tester.pumpAndSettle();
}

Future<void> confirm(WidgetTester tester) async {
  await tester.scrollUntilVisible(find.text('Confirm Pick'), 120,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Confirm Pick'));
  await tester.pumpAndSettle();
}

Future<void> submitLabel(
    WidgetTester tester, String field, String label) async {
  final input = find.widgetWithText(TextField, field);
  await tester.ensureVisible(input);
  await tester.enterText(input, label);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('full pallet goes to a later eligible line with original LPN',
      (tester) async {
    final adapter = WaveAdapter({'PALLET48': 48})
      ..remaining[301] = 15
      ..remaining[302] = 68;
    await openWave(tester, adapter);
    await scan(tester, 'PALLET48');
    expect(find.text('TEST-SHIP-B · 48 units'), findsOneWidget);
    expect(find.text('LPN PALLET48'), findsOneWidget);
    expect(find.text('Confirm Pick'), findsNothing);
    expect(
        find.widgetWithText(TextField, 'Scan new shipment LPN'), findsNothing);
    expect(adapter.previews, [302]);
    expect(adapter.requests.single['shipmentLineId'], 302);
    expect(adapter.requests.single['quantity'], 48);
    expect(adapter.requests.single['newLpn'], isEmpty);
  });

  testWidgets('refresh drops an unpicked LPN and retains the replacement',
      (tester) async {
    final adapter = WaveAdapter({'ORIGINAL': 48, 'REPLACEMENT': 48});
    await openWave(tester, adapter);
    await scan(tester, 'ORIGINAL');
    expect(find.text('LPN ORIGINAL'), findsOneWidget);

    adapter.picked.clear();
    adapter.remaining[301] = 48;
    await tester.tap(find.byTooltip('Refresh Wave'));
    await tester.pumpAndSettle();
    expect(find.text('LPN ORIGINAL'), findsNothing);
    expect(find.text('96 to pick'), findsOneWidget);

    await scan(tester, 'REPLACEMENT');
    expect(find.text('LPN ORIGINAL'), findsNothing);
    expect(find.text('LPN REPLACEMENT'), findsOneWidget);
  });

  testWidgets('splits when the later line cannot take the full pallet',
      (tester) async {
    final adapter = WaveAdapter({'PALLET48': 48})
      ..remaining[301] = 15
      ..remaining[302] = 68
      ..previewLimits[302] = 33;
    await openWave(tester, adapter);
    await scan(tester, 'PALLET48');
    expect(find.text('TEST-SHIP-A · 15 units'), findsOneWidget);
    expect(find.text('TEST-SHIP-B · 33 units'), findsNothing);
    expect(adapter.previews, [302, 301]);
    expect(adapter.requests, isEmpty);
    expect(find.widgetWithText(TextField, 'Scan new shipment LPN'),
        findsOneWidget);
  });

  testWidgets('88 units show one full pallet and 40 loose units',
      (tester) async {
    final adapter = WaveAdapter({})..remaining[302] = 40;
    await openWave(tester, adapter);
    expect(find.text('1 full pallet + 40 loose units'), findsOneWidget);
    expect(find.text('48 units per full pallet'), findsOneWidget);
  });

  testWidgets(
      'one pallet splits into two shipment LPNs and resumes exactly once',
      (tester) async {
    final adapter = WaveAdapter({'PALLET96': 96}, interruptSecond: true);
    await openWave(tester, adapter);
    await scan(tester, 'PALLET96');
    expect(find.text('Confirm Pick'), findsNothing);
    expect(adapter.requests, isEmpty);
    await submitLabel(tester, 'Scan new shipment LPN', 'LABEL001');
    expect(find.text('Scan new remainder LPN'), findsNothing);
    await confirm(tester);
    expect(find.text('Resume Pick'), findsOneWidget);
    expect(adapter.requests.map((r) => r['shipmentLineId']), [301, 302]);
    expect(adapter.requests.map((r) => r['quantity']), [48, 48]);
    expect(adapter.requests.map((r) => r['expectedQuantity']), [96, 48]);
    expect(adapter.requests.map((r) => r['newLpn']), ['LABEL001', '']);
    expect(adapter.requests.first['keepOriginal'], false);
    expect(adapter.requests.first['destination'], '@SHIP_STAGE');
    await tester.tap(find.text('Resume Pick'));
    await tester.pumpAndSettle();
    expect(adapter.requests.last, adapter.requests[1]);
    expect(adapter.completed, hasLength(2));
    expect(find.text('LPN LABEL001'), findsOneWidget);
    expect(find.text('LPN PALLET96'), findsOneWidget);
  });

  testWidgets('48 units split into 15, 5 and 20, relabels the last 8 once',
      (tester) async {
    final adapter = WaveAdapter({'PALLET48': 48})
      ..remaining[301] = 15
      ..remaining[302] = 5
      ..remaining[303] = 20
      ..loseRelabelReply = true;
    await openWave(tester, adapter);
    await scan(tester, 'PALLET48');
    expect(find.text('Original pallet · 48 units'), findsOneWidget);
    expect(find.text('40 to ship · 8 remaining'), findsOneWidget);
    expect(find.text('TEST-SHIP-A · 15 units'), findsOneWidget);
    expect(find.text('TEST-SHIP-B · 5 units'), findsNothing);
    await submitLabel(tester, 'Scan new shipment LPN', 'LABEL001');
    expect(find.text('TEST-SHIP-B · 5 units'), findsOneWidget);
    await submitLabel(tester, 'Scan new shipment LPN', 'LABEL001');
    expect(find.text('Use a different new LPN.'), findsOneWidget);
    await submitLabel(tester, 'Scan new shipment LPN', 'LABEL002');
    await submitLabel(tester, 'Scan new shipment LPN', 'LABEL003');
    expect(find.text('Remaining stock · 8 units'), findsOneWidget);
    await submitLabel(tester, 'Scan new remainder LPN', 'LABEL004');
    expect(adapter.requests, isEmpty);
    expect(adapter.relabels, 0);
    await confirm(tester);
    expect(adapter.requests.map((request) => request['quantity']), [15, 5, 20]);
    expect(adapter.pallets, {'LABEL004': 8});
    expect(find.text('Resume Pick'), findsOneWidget);
    await tester.tap(find.text('Resume Pick'));
    await tester.pumpAndSettle();
    expect(adapter.requests, hasLength(3));
    expect(adapter.relabels, 1);
    expect(find.text('Pick completed. Remaining stock: 8 units on LABEL004.'),
        findsOneWidget);
  });

  testWidgets('two pallets finish the same SKU task', (tester) async {
    final adapter = WaveAdapter({'PALLET01': 48, 'PALLET02': 48});
    await openWave(tester, adapter);
    await tester.enterText(
        find.widgetWithText(TextField, 'Scan pallet LPN'), 'PALLET01');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('48 to pick'), findsOneWidget);
    await scan(tester, 'PALLET02');
    expect(adapter.requests.map((r) => r['shipmentLineId']), [301, 302]);
    expect(
        find.text('No reserved quantities available to pick.'), findsOneWidget);
    expect(find.text('LPN PALLET01'), findsOneWidget);
    expect(find.text('LPN PALLET02'), findsOneWidget);
  });
}
