import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cwms_mobile/outbound/widgets/manual_pick_split_dialog.dart';
import 'package:cwms_mobile/outbound/services/preprinted_manual_pick.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplitAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  bool timeout = false;
  bool allowCancel = false;
  Completer<void>? gate;
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? body, Future<void>? cancel) async {
    calls.add(o);
    await gate?.future;
    if (o.path.endsWith('/cancel-unstarted'))
      return ResponseBody.fromString(
          jsonEncode({
            'result': 0,
            'data': {'cancelled': allowCancel, 'completed': false}
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    if (timeout)
      throw DioException(
          requestOptions: o, type: DioExceptionType.receiveTimeout);
    return ResponseBody.fromString(
        jsonEncode({
          'result': 0,
          'data': {'completed': true}
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
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Global.currentServer = CWMSSiteInformation()
      ..url = 'https://example.test/api/';
    Global.currentWarehouse = Warehouse()..id = 1;
    CWMSHttpClient.resetDio();
  });
  final details = {
    'orderId': 11,
    'orderNumber': 'TEST-ORDER',
    'sourceLpn': 'L000000001',
    'quantity': 40,
    'expectedQuantity': 325,
    'newLpn': 'L000000002',
    'keepOriginal': false,
    'destination': 'RF-TEST'
  };
  test(
      'timeout keeps exact request ID and LPN roles; retry acknowledgement clears it',
      () async {
    final adapter = SplitAdapter()..timeout = true;
    CWMSHttpClient.getDio().httpClientAdapter = adapter;
    await expectLater(PreprintedManualPickService.submit(details),
        throwsA(isA<DioException>()));
    final pending = await PreprintedManualPickService.pending();
    expect(pending, isNotNull);
    expect(pending!['quantity'], 40);
    expect(pending['newLpn'], 'L000000002');
    adapter.timeout = false;
    await PreprintedManualPickService.submit({...details, 'quantity': 325});
    expect(adapter.calls, hasLength(2));
    expect(adapter.calls[0].queryParameters, adapter.calls[1].queryParameters);
    expect(await PreprintedManualPickService.pending(), isNull);
  });
  test('simultaneous confirmations share one request', () async {
    final adapter = SplitAdapter()..gate = Completer<void>();
    CWMSHttpClient.getDio().httpClientAdapter = adapter;
    final first = PreprintedManualPickService.submit(details);
    final second = PreprintedManualPickService.submit(details);
    adapter.gate!.complete();
    await Future.wait([first, second]);
    expect(adapter.calls, hasLength(1));
  });
  test('only acknowledged unstarted cancellation clears a pending request',
      () async {
    final adapter = SplitAdapter()..timeout = true;
    CWMSHttpClient.getDio().httpClientAdapter = adapter;
    await expectLater(PreprintedManualPickService.submit(details),
        throwsA(isA<DioException>()));
    adapter.timeout = false;
    expect(await PreprintedManualPickService.cancelUnstarted(), false);
    expect(await PreprintedManualPickService.pending(), isNotNull);
    adapter.allowCancel = true;
    expect(await PreprintedManualPickService.cancelUnstarted(), true);
    expect(await PreprintedManualPickService.pending(), isNull);
  });
  for (final originalForOrder in [false, true]) {
    testWidgets(
        'partial pallet 325 -> 40 + 285 supports originalForOrder=$originalForOrder',
        (tester) async {
      Map<String, dynamic>? selected;
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () async {
                        selected = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (_) => const ManualPickSplitDialog(
                                sourceLpn: 'L000000001',
                                sourceQuantity: 325,
                                pickableQuantity: 40));
                      },
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      if (originalForOrder) {
        await tester.tap(find.text('Original LPN goes with this order'));
        await tester.pumpAndSettle();
      }
      await tester.enterText(find.byType(TextFormField).last, 'L000000002');
      await tester.ensureVisible(find.text('Confirm pick'));
      await tester.tap(find.text('Confirm pick'));
      await tester.pumpAndSettle();
      expect(selected, {
        'quantity': 40,
        'newLpn': 'L000000002',
        'keepOriginal': originalForOrder
      });
    });
  }
  testWidgets(
      'overpick and original/DE target LPN are rejected; cancel returns no action',
      (tester) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await showDialog<Map<String, dynamic>>(
                          context: context,
                          builder: (_) => const ManualPickSplitDialog(
                              sourceLpn: 'L000000001',
                              sourceQuantity: 325,
                              pickableQuantity: 40));
                    },
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '41');
    await tester.enterText(find.byType(TextFormField).last, 'L000000001');
    await tester.ensureVisible(find.text('Confirm pick'));
    await tester.tap(find.text('Confirm pick'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a quantity within the remaining demand'),
        findsOneWidget);
    expect(
        find.text('Scan a different ordinary preprinted LPN'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
  testWidgets('camera scan fills new label without confirming the pick',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        routes: {
          'qr_code_view': (context) => Scaffold(
              body: TextButton(
                  onPressed: () => Navigator.pop(context, 'L000000002'),
                  child: const Text('Scanned result')))
        },
        home: const Scaffold(
            body: ManualPickSplitDialog(
                sourceLpn: 'L000000001',
                sourceQuantity: 325,
                pickableQuantity: 40))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Scan label'));
    await tester.tap(find.byTooltip('Scan label'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scanned result'));
    await tester.pumpAndSettle();
    expect(find.text('L000000002'), findsOneWidget);
    expect(find.text('Confirm pick'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
