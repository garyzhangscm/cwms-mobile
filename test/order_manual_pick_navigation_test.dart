import 'package:cwms_mobile/outbound/services/preprinted_manual_pick.dart';
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
  bool duplicate = false;
  bool missingLpn = false;
  bool wrongItem = false;
  bool failItemDetails = false;
  bool diagnosticLookupFails = false;
  bool queued = false;
  bool queueReadFails = false;
  final queueRows = <Map<String, dynamic>>[];
  int currentPicked = 40;
  bool currentPickFails = false;
  bool picked = false;
  bool planned = false;
  bool availabilityFails = false;
  bool reservationRequired = false;
  bool allowManual = true;
  bool failRefreshAfterPick = false;
  bool get availabilityError =>
      availabilityFails || (picked && failRefreshAfterPick);
  String orderNumber = 'TEST-ORDER';
  int orderId = 11;
  int lineId = 1;
  int sourceQuantity = 40;
  int remainingQuantity = 40;
  int remainingAfterPick = 0;
  int? palletSize;
  int get remaining => picked ? remainingAfterPick : remainingQuantity;
  int pickableQuantity = 40;
  bool previewFails = false;
  String previewError = 'Invalid source LPN scope';
  bool confirmFails = false;
  Completer<void>? confirmGate;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? body,
      Future<void>? cancel) async {
    calls.add(options);
    if (duplicate) {
      dynamic data; String? message;
      if (options.path.endsWith('/preprinted-manual-pick')) message='LPN TEST-LPN is not pickable.';
      if (options.path == 'inventory/inventories' && options.queryParameters['lpn'] == 'TEST-LPN') data=[{'lpn':'TEST-LPN','quantity':40,'pickId':42}];
      if (options.path == 'outbound/picks/42') data={'id':42,'warehouseId':1,'orderNumber':'TEST-ORDER','pickedQuantity':40,'status':'PENDING'};
      if (options.path.endsWith('/manual-pick-queue')) data=[];
      if (data != null || message != null) return ResponseBody.fromString(jsonEncode({'result':message == null ? 0 : 1,'message':message,'data':data}),200,headers:{Headers.contentTypeHeader:['application/json']});
    }

    if (wrongItem && options.path == 'inventory/items/2') {
      return ResponseBody.fromString(jsonEncode({'result': failItemDetails ? 1 : 0, 'data':
        {'id': 2, 'warehouseId': 1, 'name': 'WRONG-ITEM', 'description': 'Scanned blue container'}
      }), 200, headers: {Headers.contentTypeHeader: ['application/json']});
    }
    if (options.path == 'inventory/inventories') {
      if (wrongItem && options.queryParameters.containsKey('lpn')) {
        return ResponseBody.fromString(jsonEncode({'result': 0, 'data': [
          {'lpn': options.queryParameters['lpn'], 'quantity': 40, 'itemId': 2}
        ]}), 200, headers: {Headers.contentTypeHeader: ['application/json']});
      }

      if (options.queryParameters.containsKey('lpn') && (missingLpn || diagnosticLookupFails)) {
        return ResponseBody.fromString(jsonEncode({
          'result': diagnosticLookupFails ? 1 : 0,
          'message': diagnosticLookupFails ? 'Lookup unavailable' : '',
          'data': []
        }), 200, headers: {Headers.contentTypeHeader: ['application/json']});
      }

      return ResponseBody.fromString(
          jsonEncode({
            'result': 0,
            'data': [
              {'id': 101, 'lpn': 'NEW-SPLIT-LPN', 'quantity': 25, 'pickId': 1},
              {'id': 102, 'lpn': 'WHOLE-LPN', 'quantity': 15, 'pickId': 1},
              {'id': 103, 'lpn': 'UNPICKED', 'quantity': 30, 'pickId': null}
            ]
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    if (options.path.endsWith('/picks')) {
      return ResponseBody.fromString(
          jsonEncode({
            'result': currentPickFails ? 1 : 0,
            'data': [
              {'id': 1, 'itemId': 1, 'pickedQuantity': currentPicked}
            ]
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    if (options.path.endsWith('/manual-pick-queue/capabilities')) {
      return ResponseBody.fromString(
          jsonEncode({
            'result': 0,
            'data': {'schema': 'manual-pick-queue-v1', 'enabled': queued}
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    if (options.path.endsWith('/manual-pick-queue')) {
      if (options.method == 'POST') {
        final row = {
          'requestId': options.queryParameters['requestId'],
          'sourceLpn': options.queryParameters['sourceLpn'],
          'quantity': options.queryParameters['quantity'],
          'state': 'QUEUED'
        };
        queueRows.add(row);
        return ResponseBody.fromString(
            jsonEncode({'result': 0, 'data': row}), 200,
            headers: {
              Headers.contentTypeHeader: ['application/json']
            });
      }
      if (queueReadFails)
        throw DioException(
            requestOptions: options, type: DioExceptionType.connectionTimeout);
      return ResponseBody.fromString(
          jsonEncode({'result': 0, 'data': queueRows}), 200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    if (options.path.endsWith('/manual-pick-availability')) {
      return ResponseBody.fromString(
          jsonEncode({
            'result': availabilityError ? 1 : 0,
            'message': availabilityError ? 'Availability unavailable' : '',
            'data': {
              'orderId': orderId,
              'reservationRequired': reservationRequired,
              'allocationMode': reservationRequired
                  ? 'RESERVATION_REQUIRED'
                  : queued
                      ? 'ITEM_QUANTITY'
                      : 'CLASSIC',
              'remainingQuantity': remaining,
              'canPick': remaining > 0,
              'lines': [
                {
                  'orderLineId': lineId,
                  'number': '1',
                  'remainingQuantity': remaining
                }
              ]
            }
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    if (options.path.endsWith('/preprinted-manual-pick') &&
        options.method == 'GET') {
      return ResponseBody.fromString(
          jsonEncode({
            'result': previewFails ? 1 : 0,
            'message': previewFails ? previewError : '',
            'data': {
              'sourceQuantity': sourceQuantity,
              'pickableQuantity': picked ? 0 : pickableQuantity
            }
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
                    'id': orderId,
                    'number': orderNumber,
                    'allowForManualPick': allowManual,
                    'orderLines': [
                      {
                        'id': lineId,
                        'number': '1',
                        'openQuantity': planned || picked ? 0 : 40,
                        'expectedQuantity': 40,
                        'item': {
                          'id': 1,
                          'name': 'DEMO-ITEM',
                          if (palletSize != null)
                            'defaultItemPackageType': {
                              'id': 21,
                              'name': 'Main',
                              'stockItemUnitOfMeasure': {
                                'id': 31,
                                'quantity': 1,
                                'unitOfMeasure': {'id': 1, 'name': 'PCS'}
                              },
                              'itemUnitOfMeasures': [
                                {
                                  'id': 32,
                                  'quantity': palletSize,
                                  'unitOfMeasure': {'id': 4, 'name': 'PL'}
                                }
                              ]
                            }
                        }
                      }
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

  testWidgets('duplicate explanation returns focus to empty LPN without submitting', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    adapter.duplicate=true;
    await tester.enterText(find.byType(TextFormField).last, 'TEST-LPN');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('LPN already picked'), findsOneWidget);
    await tester.tap(find.text('Scan next pallet'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    final field=tester.widget<TextFormField>(find.byType(TextFormField).last);
    expect(field.controller!.text, isEmpty);
    expect(tester.widget<EditableText>(find.byType(EditableText).last).focusNode.hasFocus, isTrue);
    expect(adapter.calls.where((r)=>r.method=='POST'), isEmpty);
    expect(tester.takeException(), isNull);
  });


  testWidgets('unknown LPN has actionable message and returns scanner focus without POST', (tester) async {
    adapter.previewFails = true;
    adapter.missingLpn = true;
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'MISSING-LPN');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('LPN not found'), findsOneWidget);
    expect(find.textContaining('was not found in this warehouse'), findsOneWidget);
    expect(find.textContaining('Invalid source LPN scope'), findsNothing);
    await tester.tap(find.text('Scan another pallet'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextFormField>(find.byType(TextFormField).last);
    expect(field.controller!.text, isEmpty);
    expect(tester.widget<EditableText>(find.byType(EditableText).last).focusNode.hasFocus, isTrue);
    expect(adapter.calls.where((r) => r.method == 'POST'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final queued in [false, true]) {
    testWidgets('successful pallet resumes editable focused LPN after submit (queued=$queued)', (tester) async {
      adapter.queued = queued;
      adapter.remainingQuantity = 80;
      adapter.remainingAfterPick = 40;
      await open(tester);
      await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'TEST-LPN');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byType(TextField).last);
      expect(field.controller!.text, isEmpty);
      expect(field.readOnly, isFalse);
      expect(field.focusNode!.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }


  for (final unavailable in [false, true]) {
    testWidgets('wrong item explains actual and required items and resumes scanning (detailsUnavailable=$unavailable)', (tester) async {
      adapter.previewFails = true;
      adapter.previewError = "Can't find any order line from order to match with the LPN";
      adapter.wrongItem = true;
      adapter.failItemDetails = unavailable;
      await open(tester);
      await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'TEST-LPN');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Item does not match this order'), findsOneWidget);
      expect(find.textContaining('DEMO-ITEM'), findsWidgets);
      expect(find.textContaining(unavailable ? 'Item details unavailable' : 'WRONG-ITEM — Scanned blue container'), findsOneWidget);
      expect(find.textContaining("Can't find any order line"), findsNothing);
      await tester.tap(find.text('Scan another pallet'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextFormField>(find.byType(TextFormField).last);
      expect(field.controller!.text, isEmpty);
      expect(tester.widget<EditableText>(find.byType(EditableText).last).focusNode.hasFocus, isTrue);
      expect(adapter.calls.where((r) => r.method == 'POST'), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final useStage in [true, false]) {
    testWidgets(
        'ship stage defaults checked and RF remains optional ($useStage)',
        (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      if (!useStage) {
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      }
      await tester.enterText(find.byType(TextFormField).last, 'TEST-LPN');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      final submitted = adapter.calls.singleWhere((r) =>
          r.path.endsWith('/preprinted-manual-pick') && r.method == 'POST');
      expect(submitted.queryParameters['destination'],
          useStage ? '@SHIP_STAGE' : Global.getLastLoginRFCode());
      expect(tester.takeException(), isNull);
    });
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
  testWidgets('new unreserved order explains Allocate and cannot start a Pick',
      (tester) async {
    adapter.reservationRequired = true;
    adapter.allowManual = false;
    adapter.remainingQuantity = 0;
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Reserve quantity before picking'), findsOneWidget);
    expect(adapter.calls.every((r) => r.method == 'GET'), true);
    expect(
        adapter.calls.where((r) => r.path.endsWith('/preprinted-manual-pick')),
        isEmpty);
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
      expect(find.text('Confirm pallet pick'), findsNothing);
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
      // Keyboard callbacks must not replace the active order during a pick.
      tester
          .widget<TextField>(find.byType(TextField).first)
          .onSubmitted
          ?.call('TEST-ORDER');
      await tester.pump();
      expect(adapter.calls.where((r) => r.path == 'outbound/orders'),
          hasLength(1));
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
      adapter.confirmGate!.complete();
      await tester.pumpAndSettle();
      if (rejected) {
        expect(find.textContaining('Confirmation rejected'), findsOneWidget);
        expect(find.text('TEST-LPN'), findsOneWidget);
        expect(find.text('Order picking complete'), findsNothing);
      } else {
        expect(adapter.calls.where((r) => r.path == 'outbound/orders'),
            hasLength(1));
        expect(find.text('Order picking complete'), findsOneWidget);
        expect(find.text('Error'), findsNothing);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.byType(TextFormField), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('confirmed pick with failed refresh hides old pallet counts',
      (tester) async {
    adapter.palletSize = 36;
    adapter.sourceQuantity = 36;
    adapter.pickableQuantity = 36;
    adapter.remainingQuantity = 84;
    adapter.failRefreshAfterPick = true;
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(find.text('Estimated: 3 pallets'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, 'L000000001');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining(
            'Pick confirmed, but the order could not be refreshed'),
        findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reload the order to see'), findsOneWidget);
    expect(find.textContaining('Estimated:'), findsNothing);
    expect(find.text('84 PCS remaining'), findsNothing);
  });
  testWidgets(
      'remaining pallets update after confirmed pick without package or order reload',
      (tester) async {
    adapter.palletSize = 36;
    adapter.sourceQuantity = 36;
    adapter.pickableQuantity = 36;
    adapter.remainingQuantity = 84;
    adapter.remainingAfterPick = 48;
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(find.text('Estimated: 3 pallets'), findsOneWidget);
    expect(find.text('84 PCS remaining'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, 'L000000001');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Estimated: 2 pallets'), findsOneWidget);
    expect(find.text('48 PCS remaining'), findsOneWidget);
    expect(find.text('1 full pallet + 12 PCS'), findsOneWidget);
    expect(
        adapter.calls.where((r) => r.path == 'outbound/orders'), hasLength(1));
    expect(adapter.calls.where((r) => r.path.contains('itemPackageTypes')),
        isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'full pallet below order demand submits its exact source quantity',
      (tester) async {
    adapter.sourceQuantity = 20;
    adapter.pickableQuantity = 20;
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'L000000001');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm pallet pick'), findsNothing);
    final post = adapter.calls.singleWhere((r) =>
        r.method == 'POST' && r.path.endsWith('/preprinted-manual-pick'));
    expect(post.queryParameters['quantity'], 20);
    expect(post.queryParameters['expectedQuantity'], 20);
    expect(post.queryParameters['newLpn'], '');
    expect(
        adapter.calls.where((r) => r.path == 'outbound/orders'), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  for (final quantity in [0, -1, 41]) {
    testWidgets(
        'invalid preview quantity $quantity never submits automatically',
        (tester) async {
      adapter.pickableQuantity = quantity;
      await open(tester);
      await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).last, 'L000000001');
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No valid picking quantity'), findsOneWidget);
      expect(adapter.calls.where((r) => r.method == 'POST'), isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'DEMO-REPICK-40 cancellation leaves shipment demand 40: reopen and cap split to 40',
      (tester) async {
    adapter.planned = true;
    adapter.orderNumber = 'DEMO-REPICK-40';
    adapter.orderId = 111;
    adapter.lineId = 222;
    adapter.sourceQuantity = 325;
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'DEMO-REPICK-40');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.textContaining("no open quantity left"), findsNothing);
    expect(
        adapter.calls
            .where((r) => r.path.endsWith('/manual-pick-availability')),
        hasLength(1));
    await tester.enterText(find.byType(TextFormField).last, 'L000000001');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Maximum to pick: 40'), findsOneWidget);
    final dialogFields = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextFormField));
    expect(dialogFields, findsNWidgets(2));
    // A 325-unit source cannot be submitted as a full-pallet pick against 40 units of demand.
    await tester.enterText(dialogFields.first, '325');
    await tester.tap(find.text('Confirm pick'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a quantity within the remaining demand'),
        findsOneWidget);
    expect(adapter.calls.where((r) => r.method == 'POST'), isEmpty);
    await tester.enterText(dialogFields.first, '40');
    await tester.pump();
    await tester.enterText(dialogFields.last, 'L000000002');
    await tester.tap(find.text('Confirm pick'));
    await tester.pumpAndSettle();
    final submissions = adapter.calls.where((r) =>
        r.method == 'POST' && r.path.endsWith('/preprinted-manual-pick'));
    expect(submissions, hasLength(1));
    expect(submissions.single.queryParameters['quantity'], 40);
    expect(submissions.single.queryParameters['expectedQuantity'], 325);
    expect(find.text('Order picking complete'), findsOneWidget);
    expect(
        adapter.calls
            .where((r) => r.path.endsWith('/manual-pick-availability')),
        hasLength(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'availability error blocks picking instead of trusting cached order demand',
      (tester) async {
    adapter.availabilityFails = true;
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(find.textContaining('Availability unavailable'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(adapter.calls.where((r) => r.method == 'POST'), isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'preview error closes once and focus changes do not resubmit the same LPN',
      (tester) async {
    adapter.previewFails = true;
    adapter.diagnosticLookupFails = true;
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.tap(find.text('Next Step'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'W100000237376');
    await tester.tap(find.text('Confirm').first);
    await tester.pumpAndSettle();
    int previews() => adapter.calls
        .where((r) =>
            r.method == 'GET' && r.path.endsWith('/preprinted-manual-pick'))
        .length;
    expect(previews(), 1);
    expect(find.textContaining('Invalid source LPN scope'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    final input = tester.widget<TextField>(find.byType(TextField).last);
    for (var i = 0; i < 3; i++) {
      input.focusNode!.requestFocus();
      await tester.pump();
      input.controller!.selection = const TextSelection.collapsed(offset: 2);
      input.focusNode!.unfocus();
      await tester.pumpAndSettle();
    }
    expect(previews(), 1);
    expect(find.byType(AlertDialog), findsNothing);
    expect(adapter.calls.where((r) => r.method == 'POST'), isEmpty);
    // An explicit Confirm is a deliberate retry, even without editing the value.
    await tester.tap(find.text('Confirm').first);
    await tester.pumpAndSettle();
    expect(previews(), 2);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // Editing the barcode rearms automatic blur submission once.
    await tester.enterText(find.byType(TextFormField).last, 'W10000237376');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(previews(), 3);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(previews(), 3);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('picked pallet view shows individual LPNs and matched submitter',
      (tester) async {
    adapter.queued = true;
    adapter.remainingQuantity = 0;
    adapter.queueRows.add({
      'requestId': 'a',
      'state': 'COMPLETED',
      'sourceLpn': 'OLD-SOURCE',
      'pickId': 1,
      'quantity': 40,
      'submittedBy': 'louise'
    });
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(find.text('click to see the item to be picked'), findsNothing);
    await tester.ensureVisible(find.text('View Picked Pallets'));
    await tester.tap(find.text('View Picked Pallets'));
    await tester.pumpAndSettle();
    expect(find.text('NEW-SPLIT-LPN'), findsOneWidget);
    expect(find.text('WHOLE-LPN'), findsOneWidget);
    expect(find.text('UNPICKED'), findsNothing);
    expect(find.text('Qty: 25'), findsOneWidget);
    expect(find.text('Submitted by louise'), findsNWidgets(2));
    expect(
        adapter.calls.any((r) => r.path.contains('picked-inventory-summary')),
        isFalse);
    final query =
        adapter.calls.firstWhere((r) => r.path == 'inventory/inventories');
    expect(query.queryParameters['pickIds'], '1');
    expect(query.queryParameters['includeDetails'], false);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'picked summary and details available before completion; unpick refreshes summary',
      (tester) async {
    adapter.queued = true;
    adapter.remainingQuantity = 20;
    adapter.currentPicked = 20;
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(find.text('DEMO-ITEM: 20 picked'), findsOneWidget);
    expect(find.text('View Picked Pallets'), findsOneWidget);
    expect(
        adapter.calls.any((r) => r.path == 'inventory/inventories'), isFalse);
    adapter.currentPicked = 0;
    adapter.remainingQuantity = 40;
    await tester.pump(const Duration(seconds: 12));
    await tester.pumpAndSettle();
    expect(find.text('DEMO-ITEM: 0 picked'), findsOneWidget);
    expect(find.text('View Picked Pallets'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('verified rejection explains location and returns to scanning without a write', (tester) async {
    adapter.previewFails = true;
    adapter.previewError = 'Order Operation Exception-PICK_REJECTION_V1:${jsonEncode({'title':'Pallet unavailable for picking','lpn':'L0000281044','location':'TRANS_SHIPPING','reason':'This pallet is already in the transfer shipping area.','nextAction':'Scan another pallet.'})}';
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first,'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last,'L0000281044');
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Pallet unavailable for picking'), findsOneWidget);
    expect(find.text('Current location: TRANS_SHIPPING'), findsOneWidget);
    await tester.tap(find.text('Scan next pallet'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.widget<TextFormField>(find.byType(TextFormField).last).controller!.text,isEmpty);
    expect(adapter.calls.where((r) => r.method == 'POST'),isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  test('no current picks never queries unfiltered inventory', () async {
    adapter.currentPicked = 0;
    expect(await PreprintedManualPickService.pickedPallets(11), isEmpty);
    expect(
        adapter.calls.any((r) => r.path == 'inventory/inventories'), isFalse);
  });

  testWidgets(
      'another operator updates quantities without an interrupting dialog',
      (tester) async {
    adapter.queued = true;
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(find.textContaining('Remaining to pick —'), findsNothing);
    adapter.remainingQuantity = 15;
    adapter.queueRows.add({
      'requestId': 'other',
      'sourceLpn': 'TEAM-PALLET',
      'quantity': 25,
      'state': 'QUEUED',
      'submittedBy': 'louise'
    });
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.textContaining('Submitted by louise'), findsOneWidget);
    expect(
        find.textContaining('louise submitted another pallet'), findsOneWidget);
    expect(find.textContaining('DEMO-ITEM: 15'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(adapter.calls.where((r) => r.method == 'POST'), isEmpty);
    // The next identical snapshot does not create another banner.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.textContaining('Remaining to pick —'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'zero remaining waits for worker then completes; next order clears inputs',
      (tester) async {
    adapter.queued = true;
    adapter.remainingQuantity = 0;
    adapter.queueRows.add({
      'requestId': 'test',
      'state': 'QUEUED',
      'sourceLpn': 'PALLET',
      'quantity': 40
    });
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(find.text('All quantities submitted'), findsOneWidget);
    expect(find.text('Picking complete'), findsNothing);
    adapter.queueRows.first['state'] = 'COMPLETED';
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Picking complete'), findsOneWidget);
    expect(find.text('Pick history'), findsNothing);
    expect(find.text('PALLET · 40'), findsNothing);
    await tester.ensureVisible(find.text('Next Order'));
    await tester.tap(find.text('Next Order'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        isEmpty);
    expect(find.text('Picking complete'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'zero reservation does not imply complete; unpick restores scanner',
      (tester) async {
    adapter.queued = true;
    adapter.remainingQuantity = 0;
    adapter.currentPicked = 10;
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(find.text('Picking complete'), findsNothing);
    adapter.currentPicked = 40;
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }
    expect(find.text('Picking complete'), findsOneWidget);
    adapter.remainingQuantity = 40;
    adapter.currentPicked = 0;
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }
    expect(find.text('Picking complete'), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'accept first pallet and scan second while both are still processing',
      (tester) async {
    adapter.queued = true;
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    for (final lpn in ['L000000001', 'L000000002']) {
      await tester.enterText(find.byType(TextFormField).last, lpn);
      await tester.ensureVisible(find.text('Confirm'));
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
    }
    expect(adapter.queueRows.length, 2);
    expect(adapter.queueRows.every((r) => r['state'] == 'QUEUED'), isTrue);
    expect(
        adapter.calls.where((r) =>
            r.path.endsWith('/preprinted-manual-pick') && r.method == 'POST'),
        isEmpty);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).last)
            .controller!
            .text,
        isEmpty);
    expect(find.text('Completed'), findsNothing);
    adapter.queueRows.first['state'] = 'COMPLETED';
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await open(tester);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'TEST-ORDER');
    expect(find.text('Completed'), findsNothing);
    expect(
        adapter.calls
            .where((r) =>
                r.path.endsWith('/manual-pick-queue') && r.method == 'POST')
            .length,
        2);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets(
      'reopened order restores server tasks and blocks scanning when a task needs review',
      (tester) async {
    adapter.queued = true;
    adapter.queueRows.add({
      'requestId': 'saved',
      'sourceLpn': 'L000000001',
      'quantity': 40,
      'state': 'NEEDS_REVIEW'
    });
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'TEST-ORDER');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(find.text('Retry saved task'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, 'L000000002');
    await tester.ensureVisible(find.text('Confirm'));
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(adapter.calls.where((r) => r.method == 'POST'), isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
