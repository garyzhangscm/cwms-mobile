import 'dart:async';

import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/shared/models/factory_profile.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/workorder/routes/qc_production_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'queues rapid LPNs and retries uncertain results with the same ID',
      (tester) async {
    if (FactoryProfile.qcPreviewUrl.isEmpty) return;
    SharedPreferences.setMockInitialValues({});
    Global.currentServer = CWMSSiteInformation()
      ..url = FactoryProfile.qcPreviewUrl;
    Global.currentWarehouse = Warehouse()..id = 1;
    CWMSHttpClient.resetDio();
    final firstResponse = Completer<void>();
    final requests = <Map<String, dynamic>>[];
    final counted = <String>{};
    var timedOut = false;
    CWMSHttpClient.getDio().interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        Object data = {'enabled': true, 'actor': 'qc-test'};
        if (options.path.endsWith('/confirm')) {
          final scan = Map<String, dynamic>.from(options.data as Map);
          requests.add(scan);
          if (requests.length == 1) await firstResponse.future;
          if (scan['lpn'] == 'OLD1') {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {'result': 1, 'message': 'This LPN has only production from before QC confirmation was enabled; historical totals remain unchanged'},
            ));
            return;
          }
          if (scan['lpn'] == 'TEST2' && !timedOut) {
            timedOut = true;
            handler.reject(DioException(
              requestOptions: options,
              type: DioExceptionType.receiveTimeout,
            ));
            return;
          }
          data = {
            'requestId': scan['requestId'],
            'state': 'CONFIRMED',
            'outcome': counted.add(scan['lpn'] as String)
                ? 'CONFIRMED'
                : 'ALREADY_CONFIRMED',
          };
        }
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {'result': 0, 'data': data},
        ));
      },
    ));
    await tester.pumpWidget(const MaterialApp(
      home: QcProductionPage(withdraw: false),
    ));
    await tester.pumpAndSettle();

    for (final lpn in ['TEST1', 'TEST2', 'TEST1']) {
      await tester.enterText(find.byType(TextField), lpn);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }
    expect(requests.map((scan) => scan['lpn']), ['TEST1']);
    firstResponse.complete();
    await tester.pumpAndSettle();
    expect(requests.map((scan) => scan['lpn']), ['TEST1', 'TEST2', 'TEST1']);
    expect(find.text('Already confirmed · No duplicate count'), findsOneWidget);
    expect(find.text('TEST1'), findsOneWidget);
    expect(find.text('Production confirmed'), findsNothing);
    expect(find.textContaining('Result pending confirmation'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(requests.last['requestId'], requests[1]['requestId']);
    expect(counted, {'TEST1', 'TEST2'});
    expect(find.text('Retry'), findsNothing);

    await tester.enterText(find.byType(TextField), 'OLD1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('OLD1'), findsNothing);
    expect(find.textContaining('need attention'), findsNothing);
    expect(find.text('Retry'), findsNothing);
    expect(counted, {'TEST1', 'TEST2'});

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(
      home: QcProductionPage(withdraw: false),
    ));
    await tester.pumpAndSettle();
    expect(find.text('No scans yet'), findsOneWidget);
    expect(find.text('TEST1'), findsNothing);
    expect(find.text('TEST2'), findsNothing);
  });
}
