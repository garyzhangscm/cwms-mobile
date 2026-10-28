import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/shared/scanning/rf_inventory_count_query.dart';

void main() {
  Response<dynamic> response(int status) => Response<dynamic>(
      requestOptions: RequestOptions(path: '/inventory/inventories/count'),
      statusCode: status,
      data: {'result': 0, 'data': 2});
  test(
      'simultaneous header and queue count reads send once; later count is fresh',
      () async {
    final gate = Completer<Response<dynamic>>();
    var sends = 0;
    Future<Response<dynamic>> send() {
      sends++;
      return gate.future;
    }

    final header = RfInventoryCountQuery.share('scope', send);
    final queue = RfInventoryCountQuery.share('scope', send);
    expect(sends, 1);
    gate.complete(response(200));
    expect(identical(await header, await queue), isTrue);
    await RfInventoryCountQuery.share('scope', () async {
      sends++;
      return response(200);
    });
    expect(sends, 2);
  });
  test('different factory warehouse or login scope never shares a read',
      () async {
    final gate = Completer<Response<dynamic>>();
    var sends = 0;
    Future<Response<dynamic>> send() {
      sends++;
      return gate.future;
    }

    final a = RfInventoryCountQuery.share('factoryA|warehouse1|sessionA', send);
    final b = RfInventoryCountQuery.share('factoryA|warehouse2|sessionA', send);
    final c = RfInventoryCountQuery.share('factoryA|warehouse1|sessionB', send);
    expect(sends, 3);
    gate.complete(response(200));
    await Future.wait([a, b, c]);
  });
  test('failed shared read is released and explicit retry sends again',
      () async {
    final gate = Completer<Response<dynamic>>();
    final a = RfInventoryCountQuery.share('failed', () => gate.future);
    final b = RfInventoryCountQuery.share(
        'failed', () => throw StateError('duplicate'));
    final checkA = expectLater(a, throwsA(isA<DioException>()));
    final checkB = expectLater(b, throwsA(isA<DioException>()));
    gate.completeError(DioException(
        requestOptions: RequestOptions(path: '/count'),
        type: DioExceptionType.connectionError));
    await Future.wait([checkA, checkB]);
    expect(
        (await RfInventoryCountQuery.share('failed', () async => response(200)))
            .statusCode,
        200);
  });
}
