import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/workorder/services/work_order_qc.dart';

class LatestAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  List<dynamic> rows = [
    {'id': 12, 'number': 'TEST-QC', 'warehouseId': 3, 'imageUrls': 'test.png'}
  ];
  int? latestStatus;
  bool timeout = false;
  int result = 0;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? data,
      Future<void>? cancel) async {
    calls.add(options);
    expect(options.method, 'GET');
    expect(options.queryParameters,
        {'productionLineAssignmentId': 7, 'warehouseId': 3});
    if (timeout)
      throw DioException.connectionTimeout(
          requestOptions: options, timeout: const Duration(seconds: 1));
    final status = options.path.endsWith('/latest') ? latestStatus ?? 200 : 200;
    return ResponseBody.fromString(
        jsonEncode({'result': result, 'message': 'TEST error', 'data': rows}),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late LatestAdapter adapter;
  setUp(() {
    adapter = LatestAdapter();
    dio = Dio()..httpClientAdapter = adapter;
  });
  Future<dynamic> load() =>
      WorkOrderQCService.getWorkOrderQCSampleByProductionLineAssignment(7,
          client: dio, warehouseId: 3);
  test(
      'new endpoint receives scope and preserves selected sample and image URLs',
      () async {
    final sample = await load();
    expect(adapter.calls.single.path, 'workorder/qc-samples/assignment/latest');
    expect(sample.id, 12);
    expect(sample.number, 'TEST-QC');
    expect(sample.imageUrls, 'test.png');
  });
  test('empty latest response returns null for normal new sample flow',
      () async {
    adapter.rows = [];
    expect(await load(), isNull);
    expect(adapter.calls.length, 1);
  });
  test(
      'only 404 falls back; future lookup on same server skips absent endpoint',
      () async {
    adapter.latestStatus = 404;
    adapter.rows
        .add({'id': 'bad historical record that must not be deserialized'});
    expect((await load()).id, 12);
    expect(adapter.calls.map((r) => r.path),
        ['workorder/qc-samples/assignment/latest', 'workorder/qc-samples']);
    expect((await load()).id, 12);
    expect(adapter.calls.last.path, 'workorder/qc-samples');
    expect(adapter.calls.length, 3);
  });
  test('legacy fallback cache is isolated per server client', () async {
    adapter.latestStatus = 404;
    await load();
    final otherAdapter = LatestAdapter();
    final otherClient = Dio()..httpClientAdapter = otherAdapter;
    await WorkOrderQCService.getWorkOrderQCSampleByProductionLineAssignment(7,
        client: otherClient, warehouseId: 3);
    expect(otherAdapter.calls.single.path,
        'workorder/qc-samples/assignment/latest');
  });
  for (final status in [401, 403, 500]) {
    test('HTTP $status never triggers full history fallback', () async {
      adapter.latestStatus = status;
      await expectLater(load(), throwsA(isA<DioException>()));
      expect(adapter.calls.length, 1);
    });
  }
  test('timeout never triggers full history fallback', () async {
    adapter.timeout = true;
    await expectLater(load(), throwsA(isA<DioException>()));
    expect(adapter.calls.length, 1);
  });
  test('business error never triggers full history fallback', () async {
    adapter.result = 500;
    await expectLater(load(), throwsA(isA<WebAPICallException>()));
    expect(adapter.calls.length, 1);
  });
  test('new latest endpoint rejects an unbounded response', () async {
    adapter.rows.add({'id': 11});
    await expectLater(load(), throwsA(isA<WebAPICallException>()));
    expect(adapter.calls.length, 1);
  });
  test('invalid identity makes no request', () async {
    await expectLater(
        WorkOrderQCService.getWorkOrderQCSampleByProductionLineAssignment(0,
            client: dio, warehouseId: 3),
        throwsArgumentError);
    expect(adapter.calls, isEmpty);
  });
}
