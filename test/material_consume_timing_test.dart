import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/material-consume-timing.dart';
import 'package:cwms_mobile/workorder/services/bill_of_material.dart';

void main() {
  for (final timing in MaterialConsumeTiming.values) {
    test('explicit $timing needs no configuration request', () async {
      final dio = Dio();
      var calls = 0;
      dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
        calls++;
        h.reject(DioException(requestOptions: r));
      }));
      final order = WorkOrder()..materialConsumeTiming = timing;
      expect(
          await BillOfMaterialService.consumesAtReporting(order, client: dio),
          timing == MaterialConsumeTiming.BY_TRANSACTION);
      expect(calls, 0);
    });
    test('missing order timing resolves effective server $timing', () async {
      final dio = Dio();
      final paths = <String>[];
      dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
        paths.add(r.path);
        if (r.path.endsWith('configuration')) {
          expect(r.queryParameters, {'companyId': 7, 'warehouseId': 8});
        }
        h.resolve(Response(requestOptions: r, data: {
          'result': 0,
          'data': {
            'materialConsumeTiming':
                r.path.endsWith('configuration') ? timing.name : null,
          }
        }));
      }));
      expect(
          await BillOfMaterialService.consumesAtReporting(WorkOrder()..id = 3,
              client: dio, companyId: 7, warehouseId: 8),
          timing == MaterialConsumeTiming.BY_TRANSACTION);
      expect(paths,
          ['workorder/work-orders/3', 'workorder/work-order-configuration']);
    });
  }
  test('unknown timing fails instead of silently skipping consumption',
      () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (r, h) {
      h.resolve(Response(requestOptions: r, data: {
        'result': 0,
        'data': {'materialConsumeTiming': 'UNKNOWN'}
      }));
    }));
    await expectLater(
        BillOfMaterialService.consumesAtReporting(WorkOrder()..id = 3,
            client: dio),
        throwsA(isA<StateError>()));
  });
}
