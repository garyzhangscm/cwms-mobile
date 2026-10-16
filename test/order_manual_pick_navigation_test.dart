import 'package:cwms_mobile/outbound/routes/order_manual_pick_legacy.dart';
import 'package:cwms_mobile/shared/models/factory_profile.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cwms_mobile/outbound/routes/order_manual_pick.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PickAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  Completer<void>? gate;
  bool fail = false;
  bool picked = false;
  bool confirmFails = false;
  Completer<void>? confirmGate;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
      Future<void>? cancel) async {
    calls.add(options);
    if (options.path.endsWith('/preprinted-manual-pick') &&
        options.method == 'GET') {
      return ResponseBody.fromString(
          jsonEncode({
            'result': 0,
            'data': {'sourceQuantity': 40, 'pickableQuantity': 40}
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    if (options.path.endsWith('/preprinted-manual-pick') &&
        options.method == 'POST') {
      await confirmGate?.future;
      picked = !confirmFails;
      return ResponseBody.fromString(
          jsonEncode({
            'result': confirmFails ? 1 : 0,
            'message': confirmFails ? 'Confirmation rejected' : '',
            'data': {'completed': !confirmFails}
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    if (options.path.endsWith('/generate-manual-pick')) {
      return ResponseBody.fromString(
          jsonEncode({
            'result': 0,
            'data': [
              {
                'id': 7,
                'number': 'TEST-PICK',
                'quantity': 40,
                'pickedQuantity': 0,
                'wholeLPNPick': true
              }
            ]
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    if (options.path.endsWith('/confirm')) {
      await confirmGate?.future;
      picked = !confirmFails;
      return ResponseBody.fromString(
          jsonEncode({
            'result': confirmFails ? 1 : 0,
            'message': confirmFails ? 'Confirmation rejected' : '',
            'data': null
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    if (options.path == 'outbound/orders') await gate?.future;
    final order = options.path == 'outbound/orders';
    return ResponseBody.fromString(
        jsonEncode({
          'result': order && fail ? 1 : 0,
          'message': order && fail ? 'Order lookup failed' : '',
          'data': order
              ? [
                  {
                    'id': 11,
                    'number': 'TEST-ORDER',
                    'allowForManualPick': true,
                    'orderLines': [
                      {'id': 1, 'number': '1', 'openQuantity': picked ? 0 : 40}
                    ]
                  }
                ]
              : []
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late PickAdapter adapter;
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Global.currentFactory = null;
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('PonnamKarthik/fluttertoast'),
            (_) async => true);
    Global.currentServer = CWMSSiteInformation()
      ..url = 'https://example.test/api/';
    Global.currentWarehouse = Warehouse()..id = 1;
    CWMSHttpClient.resetDio();
    adapter = PickAdapter();
    CWMSHttpClient.getDio().httpClientAdapter = adapter;
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.iOS),
      locale: const Locale('en', 'US'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        CWMSLocalizationsDelegate()
      ],
      home: OrderManualPickPage(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('Luggage retains its existing backend workflow', (tester) async {
    Global.currentFactory = FactoryProfile.byId('mira-loma-luggage');
    await open(tester);
    expect(find.byType(LegacyOrderManualPickPage), findsOneWidget);
    expect(
        adapter.calls.where((r) => r.path.contains('preprinted-manual-pick')),
        isEmpty);
    Global.currentFactory = null;
  });

  testWidgets('losing focus does not query a partially typed order',
      (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'CT');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(adapter.calls.where((r) => r.path == 'outbound/orders'), isEmpty);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.tap(find.text('Next Step'));
    await tester.pumpAndSettle();
    final calls = adapter.calls.where((r) => r.path == 'outbound/orders');
    expect(calls, hasLength(1));
    expect(calls.single.queryParameters['number'], 'TEST-ORDER');
    expect(tester.takeException(), isNull);
  });
  testWidgets('iPhone Go loads order once and focuses a usable LPN field',
      (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, ' TEST-ORDER ');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    final lpn = tester.widget<TextField>(find.byType(TextField).last);
    expect(lpn.focusNode!.hasFocus, true);
    expect(tester.testTextInput.isVisible, true);
    expect(
        adapter.calls.where((r) => r.path == 'outbound/orders'), hasLength(1));
    expect(
        adapter.calls
            .where((r) => r.path == 'outbound/orders')
            .single
            .queryParameters['number'],
        'TEST-ORDER');
    expect(adapter.calls.every((r) => r.method == 'GET'), true);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Next and keyboard events share pending lookup and clearing ignores stale response',
      (tester) async {
    await open(tester);
    adapter.gate = Completer<void>();
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.tap(find.text('Next Step'));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.go);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(
        adapter.calls.where((r) => r.path == 'outbound/orders'), hasLength(1));
    await tester.tap(find.byIcon(Icons.close).first);
    adapter.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('lookup error is visible, leaves page open and permits retry',
      (tester) async {
    await open(tester);
    adapter.fail = true;
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(find.textContaining('Order lookup failed'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    adapter.fail = false;
    await tester.tap(find.text('Next Step'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(adapter.calls.every((r) => r.method == 'GET'), true);
    expect(tester.takeException(), isNull);
  });
  for (final rejected in [false, true]) {
    testWidgets(
        'confirmation acknowledgement controls completion (rejected=$rejected)',
        (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();
      adapter.confirmGate = Completer<void>();
      adapter.confirmFails = rejected;
      await tester.enterText(find.byType(TextFormField).last, 'TEST-LPN');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm pick'));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(
          adapter.calls.where((r) =>
              r.path.endsWith('/preprinted-manual-pick') && r.method == 'POST'),
          hasLength(1));
      expect(adapter.calls.where((r) => r.path == 'outbound/orders'),
          hasLength(1));
      expect(find.text('Order picking complete'), findsNothing);
      adapter.confirmGate!.complete();
      await tester.pumpAndSettle();
      if (rejected) {
        expect(find.textContaining('Confirmation rejected'), findsOneWidget);
        expect(find.text('TEST-LPN'), findsOneWidget);
        expect(find.text('Order picking complete'), findsNothing);
      } else {
        expect(find.text('Order picking complete'), findsOneWidget);
        expect(find.text('Error'), findsNothing);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
