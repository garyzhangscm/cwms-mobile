import 'dart:typed_data';
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
