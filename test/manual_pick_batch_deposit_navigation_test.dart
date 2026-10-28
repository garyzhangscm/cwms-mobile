import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cwms_mobile/outbound/routes/order_manual_pick.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'order_manual_pick_navigation_test.dart' as fixtures;
import 'batch_deposit_flow_test.dart' show stock;

class RouteAdapter extends fixtures.PickAdapter {
  bool empty = false;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
      Future<void>? cancel) async {
    if (options.path != '/inventory/inventories')
      return super.fetch(options, body, cancel);
    calls.add(options);
    return ResponseBody.fromString(
        jsonEncode({
          'result': 0,
          'data': empty ? [] : [stock(1, 'L000000001', 55)]
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }
}

void main() {
  testWidgets(
      'Manual Pick opens existing batch route and refreshes RF badge on return',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    Global.currentFactory = null;
    Global.currentServer = CWMSSiteInformation()
      ..url = 'https://example.test/api/';
    Global.currentWarehouse = Warehouse()..id = 1;
    CWMSHttpClient.resetDio();
    final adapter = RouteAdapter();
    CWMSHttpClient.getDio().httpClientAdapter = adapter;
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('en', 'US'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          CWMSLocalizationsDelegate()
        ],
        routes: {
          'inventory_batch_deposit': (context) => Scaffold(
              appBar: AppBar(title: const Text('Batch destination')),
              body: TextButton(
                  onPressed: () {
                    adapter.empty = true;
                    Navigator.pop(context);
                  },
                  child: const Text('Return'))),
          'inventory_deposit': (_) => const Scaffold(body: Text('Wrong route')),
        },
        home: OrderManualPickPage()));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    await tester.tap(find.text('Deposit'));
    await tester.pumpAndSettle();
    expect(find.text('Batch destination'), findsOneWidget);
    expect(find.text('Wrong route'), findsNothing);
    await tester.tap(find.text('Return'));
    await tester.pumpAndSettle();
    expect(adapter.calls.where((r) => r.path == '/inventory/inventories'),
        hasLength(2));
    expect(find.text('0'), findsOneWidget);
    expect(
        tester
            .widget<ElevatedButton>(
                find.widgetWithText(ElevatedButton, 'Deposit'))
            .onPressed,
        isNull);
    expect(tester.takeException(), isNull);
  });
}
