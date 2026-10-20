import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_sample.dart';
import 'package:cwms_mobile/workorder/services/work_order_qc.dart';

class RegistrationAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
      Future<void>? cancelFuture) async {
    calls.add(options);
    return ResponseBody.fromString(jsonEncode({
      'result': 0,
      'data': {'id': 123, 'number': 'SAMPLE-TEST', 'warehouseId': 1}
    }), 200, headers: {Headers.contentTypeHeader: ['application/json']});
  }
  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio client;
  late RegistrationAdapter adapter;
  setUp(() {
    adapter = RegistrationAdapter();
    client = Dio(BaseOptions(baseUrl: 'http://test.invalid/api/'))
      ..httpClientAdapter = adapter;
    Global.currentWarehouse = Warehouse()..id = 1;
    Global.currentUser = User()..username = 'LYDIA';
  });
  tearDown(() {
    client.close();
    Global.currentUser = null;
    Global.currentWarehouse = null;
  });
  test('registration records current account without changing sample payload', () async {
    final sample = WorkOrderQCSample()
      ..number = 'SAMPLE-TEST'
      ..warehouseId = 1
      ..imageUrls = 'existing-photo.jpg';
    final before = jsonEncode(sample.toJson());
    final result = await WorkOrderQCService.addWorkOrderQCSample(sample, client: client);
    final request = adapter.calls.single;
    expect(request.method, 'PUT');
    expect(request.uri.path, '/api/workorder/qc-samples');
    expect(request.queryParameters, {'warehouseId': 1});
    expect(request.headers['username'], 'LYDIA');
    expect(jsonDecode(request.data as String), jsonDecode(before));
    expect(jsonEncode(sample.toJson()), before);
    expect(result.id, 123);
  });
  test('shared scanner resolves the new account on every submission', () async {
    final sample = WorkOrderQCSample()..number = 'SAMPLE-TEST';
    await WorkOrderQCService.addWorkOrderQCSample(sample, client: client);
    Global.currentUser = User()..username = ' Blanca ';
    await WorkOrderQCService.addWorkOrderQCSample(sample, client: client);
    expect(adapter.calls.map((x) => x.headers['username']).toList(), ['LYDIA', 'Blanca']);
  });
  for (final username in [null, '', '   ']) {
    test('missing identity $username prevents an unidentified registration', () async {
      Global.currentUser = username == null ? null : (User()..username = username);
      await expectLater(
        WorkOrderQCService.addWorkOrderQCSample(WorkOrderQCSample(), client: client),
        throwsA(isA<WebAPICallException>()));
      expect(adapter.calls, isEmpty);
    });
  }
}
