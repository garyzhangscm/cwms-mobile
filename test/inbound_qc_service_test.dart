import 'dart:convert';
import 'dart:typed_data';
import 'package:cwms_mobile/inbound/services/inbound_qc_service.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class QCAdapter implements HttpClientAdapter {
  QCAdapter(this.pending, this.history, {this.rule});
  final Map<String, dynamic>? rule;
  final List<Map<String, dynamic>> pending, history;
  final calls = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
      Future<void>? cancel) async {
    calls.add(options);
    return ResponseBody.fromString(
        jsonEncode({
          'result': 0,
          'data': options.path.contains('/qc-rules/')
              ? rule
              : options.path.endsWith('/pending')
                  ? pending
                  : history,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> legacy() => {
      'id': 27,
      'warehouseId': 1,
      'number': 'QCR-TEST',
      'type': 'BY_INVENTORY',
      'inventory': {'id': 7},
      'qcInspectionResult': 'PASS',
      'qcTime': null,
      'qcUsername': null,
      'qcInspectionRequestItems': [
        {
          'id': 30,
          'qcInspectionResult': 'PENDING',
          'qcInspectionRequestItemOptions': [
            {
              'id': 40,
              'qcInspectionResult': 'PENDING',
            }
          ],
        }
      ],
    };

void main() {
  late Inventory inventory;
  setUp(() {
    Global.currentWarehouse = Warehouse()..id = 1;
    inventory = Inventory()
      ..id = 7
      ..inboundQCRequired = true;
  });
  Future<InboundQCRequests> load(QCAdapter adapter) =>
      InboundQCService.loadRequests(inventory,
          client: Dio(BaseOptions(baseUrl: 'https://example.test'))
            ..httpClientAdapter = adapter);

  test('loads genuine pending task without a second query', () async {
    final row = legacy()..['qcInspectionResult'] = 'PENDING';
    final adapter = QCAdapter([row], []);
    final result = await load(adapter);
    expect(result.requests.single.id, 27);
    expect(result.recoveredLegacy, false);
    expect(adapter.calls.length, 1);
  });

  test('recovers untouched legacy header only in memory, never posts',
      () async {
    final row = legacy();
    final adapter = QCAdapter([], [row]);
    final result = await load(adapter);
    expect(result.recoveredLegacy, true);
    expect(
        result.requests.single.qcInspectionResult, QCInspectionResult.PENDING);
    expect(result.requests.single.toJson()['type'], 'BY_INVENTORY');
    expect(row['qcInspectionResult'], 'PASS');
    expect(adapter.calls, hasLength(2));
    for (final call in adapter.calls) {
      expect(call.method, 'GET');
      expect(call.queryParameters, {'warehouseId': 1, 'inventoryId': 7});
    }
  });

  for (final change in [
    'time',
    'user',
    'checkpoint',
    'rule',
    'fail',
    'other inventory',
    'other warehouse',
    'other type',
    'empty'
  ]) {
    test('does not reopen completed or unrelated task: $change', () async {
      final row = legacy();
      switch (change) {
        case 'time':
          row['qcTime'] = '2026-10-15T12:00:00Z';
          break;
        case 'user':
          row['qcUsername'] = 'inspector';
          break;
        case 'checkpoint':
          row['qcInspectionRequestItems'][0]['qcInspectionRequestItemOptions']
              [0]['qcInspectionResult'] = 'PASS';
          break;
        case 'rule':
          row['qcInspectionRequestItems'][0]['qcInspectionResult'] = 'PASS';
          break;
        case 'fail':
          row['qcInspectionResult'] = 'FAIL';
          break;
        case 'other inventory':
          row['inventory'] = {'id': 8};
          break;
        case 'other warehouse':
          row['warehouseId'] = 2;
          break;
        case 'other type':
          row['type'] = 'BY_WORK_ORDER_SAMPLING';
          break;
        case 'empty':
          row['qcInspectionRequestItems'] = [];
          break;
      }
      final result = await load(QCAdapter([], [row]));
      expect(result.requests, isEmpty);
      expect(result.recoveredLegacy, false);
    });
  }
  test(
      'old task loads newly enabled checkpoints without reviving disabled ones',
      () async {
    final row = legacy();
    row['qcInspectionRequestItems'][0]['qcRule'] = {'id': 6, 'name': 'RAW'};
    row['qcInspectionRequestItems'][0]['qcInspectionRequestItemOptions'][0]
        ['qcRuleItem'] = {
      'id': 23,
      'checkPoint': 'Old question',
      'enabled': false,
    };
    final adapter = QCAdapter([], [
      row
    ], rule: {
      'id': 6,
      'name': 'RAW',
      'qcRuleItems': [
        {'id': 23, 'checkPoint': 'Old question', 'enabled': false},
        {
          'id': 342,
          'checkPoint': 'Current standard check',
          'enabled': true,
          'qcRuleItemType': 'YESNO',
          'expectedValue': 'true'
        },
      ],
    });
    final result = await load(adapter);
    final options = result.requests.single.qcInspectionRequestItems.single
        .qcInspectionRequestItemOptions;
    expect(options, hasLength(2));
    expect(options.first.id, 40);
    expect(options.first.qcRuleItem!.enabled, false);
    expect(options.last.id, isNull);
    expect(options.last.qcRuleItem!.id, 342);
    expect(options.last.qcInspectionResult, QCInspectionResult.PENDING);
    expect(adapter.calls.map((call) => call.method), everyElement('GET'));
    expect(adapter.calls.last.path, '/inventory/qc-rules/6');
    expect(options.last.toJson()['id'], isNull);
  });

  test('does not recover inventory already QCed or no longer requiring QC',
      () async {
    for (final completed in [false, true]) {
      inventory.inboundQCRequired = completed;
      inventory.lastQCTime = completed ? DateTime(2026) : null;
      final adapter = QCAdapter([], [legacy()]);
      expect((await load(adapter)).requests, isEmpty);
      expect(adapter.calls, hasLength(1));
    }
  });
}
