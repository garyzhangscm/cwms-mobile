import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/shared/models/rf.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_rule_configuration.dart';
import 'package:cwms_mobile/workorder/services/work_order_qc.dart';

class QueryAdapter implements HttpClientAdapter {
  RequestOptions? last;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancel) async {
    last = options;
    expect(options.method, 'GET');
    return ResponseBody.fromString(jsonEncode({'result': 0, 'data': []}), 200,
        headers: {Headers.contentTypeHeader: ['application/json']});
  }
  @override
  void close({bool force = false}) {}
}

void main() {
  test('query uses server pending filter and preserves warehouse/sample/type', () async {
    Global.currentServer = CWMSSiteInformation()..url = 'https://example.test/';
    Global.currentWarehouse = Warehouse()..id = 1;
    Global.currentUser = User()..token = 'mock';
    Global.lastLoginRF = RF();
    CWMSHttpClient.resetForServer();
    final adapter = QueryAdapter();
    CWMSHttpClient.getDio().httpClientAdapter = adapter;
    await WorkOrderQCService.getSampleInspectionRequests('SAMPLE-TEST');
    expect(adapter.last!.path, 'inventory/qc-inspection-requests');
    expect(adapter.last!.queryParameters, {
      'warehouseId': 1, 'workOrderQCSampleNumber': 'SAMPLE-TEST',
      'type': 'BY_WORK_ORDER_SAMPLING', 'qcInspectionResult': 'PENDING',
    });
  });

  test('summary retains exact configuration ids, rule ids, quantities and nulls', () {
    final rows = [
      {'id': 4, 'warehouseId': 1, 'qcQuantity': 0,
       'workOrderQCRuleConfigurationRules': [
         {'id': 6, 'qcRuleId': 5}, {'id': 7, 'qcRuleId': 5},
       ]},
      {'id': 8, 'warehouseId': 1, 'qcQuantity': 10,
       'workOrderQCRuleConfigurationRules': [{'id': 9, 'qcRuleId': 3}]},
      {'id': 10, 'warehouseId': 1, 'qcQuantity': null},
    ];
    final before = rows.map((r) => WorkOrderQCRuleConfiguration.fromJson(r)).toList();
    final after = WorkOrderQCService.parseSamplingConfigurations(rows);
    for (var n = 0; n < before.length; n++) {
      expect(after[n].id, before[n].id);
      expect(after[n].warehouseId, before[n].warehouseId);
      expect(after[n].qcQuantity, before[n].qcQuantity);
      expect(after[n].workOrderQCRuleConfigurationRules.map((r) => r.qcRuleId),
          before[n].workOrderQCRuleConfigurationRules.map((r) => r.qcRuleId));
    }
  });
}
