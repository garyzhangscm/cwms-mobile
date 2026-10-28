import 'dart:typed_data';
import 'dart:async';
import 'package:cwms_mobile/shared/scanning/rf_inventory_count_query.dart';
import 'package:cwms_mobile/shared/scanning/server_connection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/inventory/services/putaway_sync_gateway.dart';
import 'package:cwms_mobile/inventory/services/putaway_sync_queue.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.status);
  final int? status;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
      Future<void>? cancel) async {
    if (status == null)
      throw DioException(
          requestOptions: options, type: DioExceptionType.connectionError);
    return ResponseBody.fromString('{}', status!, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

class CountAdapter implements HttpClientAdapter {
  final gate = Completer<void>();
  int requests = 0;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
      Future<void>? cancel) async {
    requests++;
    await gate.future;
    return ResponseBody.fromString('{"result":0,"data":2}', 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() {
    Global.currentServer = CWMSSiteInformation()..url = 'http://test';
    Global.currentUser = User()
      ..username = 'user'
      ..token = 'test-token';
    Global.currentWarehouse = Warehouse()..id = 1;
    Global.lastLoginCompanyId = 1;
    Global.lastLoginRFCode = 'RF1';
  });
  for (final status in [401, 403, 500, null]) {
    test(
        'HTTP $status preserves session and classifies synchronization failure',
        () async {
      final gateway = PutawaySyncGateway('http://test', 1, 1, 'RF1', 'user',
          clientFactory: (options) =>
              Dio(options)..httpClientAdapter = FakeAdapter(status));
      try {
        await gateway.probe();
        fail('must fail');
      } on PutawaySyncFailure catch (error) {
        expect(error.loginRequired, status == 401);
        expect(error.retryable, status == 500 || status == null);
      }
      expect(Global.currentUser?.username, 'user');
      expect(Global.currentWarehouse?.id, 1);
    });
  }
  test(
      'queue and header share the same pending count and preserve count decoding',
      () async {
    final adapter = CountAdapter();
    final gateway = PutawaySyncGateway('http://test', 1, 1, 'RF1', 'user',
        clientFactory: (options) => Dio(options)..httpClientAdapter = adapter);
    final queue = gateway.probe();
    final header = RfInventoryCountQuery.share(
        const ConnectionProfile('http://test', 1, 1, 'RF1', 'test-token').scope,
        () => throw StateError('header must reuse queue read'));
    adapter.gate.complete();
    expect(await queue, 2);
    expect((await header).statusCode, 200);
    expect(adapter.requests, 1);
    // No cached inventory count: a later probe performs a fresh read.
    expect(await gateway.probe(), 2);
    expect(adapter.requests, 2);
  });
  test(
      'header-origin shared 401 keeps queue sign-in handling and sends no duplicate',
      () async {
    final gate = Completer<Response<dynamic>>();
    final header = RfInventoryCountQuery.share(
        const ConnectionProfile('http://test', 1, 1, 'RF1', 'test-token').scope,
        () => gate.future);
    final adapter = CountAdapter();
    final gateway = PutawaySyncGateway('http://test', 1, 1, 'RF1', 'user',
        clientFactory: (options) => Dio(options)..httpClientAdapter = adapter);
    final queueCheck = expectLater(
        gateway.probe(),
        throwsA(isA<PutawaySyncFailure>()
            .having((e) => e.loginRequired, 'loginRequired', true)));
    gate.complete(Response<dynamic>(
        requestOptions: RequestOptions(path: '/count'), statusCode: 401));
    expect((await header).statusCode, 401);
    await queueCheck;
    expect(adapter.requests, 0);
    expect(Global.currentUser?.username, 'user');
  });
  test('different warehouse or RF cannot send retained scans', () async {
    var requests = 0;
    final gateway = PutawaySyncGateway('http://test', 1, 1, 'RF1', 'user',
        clientFactory: (options) {
      requests++;
      return Dio(options);
    });
    Global.currentWarehouse = Warehouse()..id = 2;
    await expectLater(gateway.probe(), throwsA(isA<PutawaySyncFailure>()));
    expect(requests, 0);
    Global.currentWarehouse = Warehouse()..id = 1;
    Global.lastLoginRFCode = 'RF2';
    await expectLater(gateway.probe(), throwsA(isA<PutawaySyncFailure>()));
    expect(requests, 0);
  });
}
