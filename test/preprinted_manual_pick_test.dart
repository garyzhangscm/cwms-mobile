import 'package:cwms_mobile/shared/scanning/scan_feedback.dart';
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
  bool queued = false;
  bool completed = true;
  bool allowCancel = false;
  bool completedBeforeCancel = false;
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
            'data': {
              'cancelled': allowCancel,
              'completed': completedBeforeCancel
            }
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
          'data': queued
              ? {'requestId': o.queryParameters['requestId'], 'state': 'QUEUED'}
              : {'completed': completed}
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

class GuidedSplitAdapter extends SplitAdapter {
  var picked = false;
  var relabeled = false;

  Map<String, dynamic> get stock => {
        'id': picked ? 42 : 41,
        'locationId': 3,
        'item': {'id': 5},
        'quantity': picked ? 8 : 48,
        'lpn': relabeled ? 'L000000003' : 'L000000001',
      };

  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? body, Future<void>? cancel) async {
    calls.add(o);
    Object data;
    if (o.path.endsWith('/preprinted-manual-pick')) {
      expect(o.queryParameters['quantity'], 40);
      expect(o.queryParameters['newLpn'], 'L000000002');
      expect(o.queryParameters.containsKey('remainderLpn'), isFalse);
      expect(picked, isFalse);
      picked = true;
      data = {'completed': true};
    } else if (o.path.endsWith('/preprinted-lpns/validate')) {
      expect(o.method, 'GET');
      expect(o.queryParameters['warehouseId'], 1);
      final label = o.queryParameters['lpn'];
      if (label == 'L000000007') {
        throw DioException(
            requestOptions: o, type: DioExceptionType.receiveTimeout);
      }
      data = {
        'issued': label != 'L000000004',
        'reservedFor': label == 'L000000005' ? 'another-pick' : '',
      };
    } else if (o.path.endsWith('/inventories')) {
      final label = o.queryParameters['lpn'];
      data = switch (label) {
        'L000000001' => [stock],
        'L000000006' => [
            {...stock, 'lpn': label}
          ],
        _ => [],
      };
    } else if (o.path.endsWith('/inventory/42')) {
      data = stock;
    } else if (o.path.endsWith('/inventories/42/relabel')) {
      expect(o.queryParameters['newLPN'], 'L000000003');
      expect(o.queryParameters['mergeWithExistingInventory'], isFalse);
      expect(relabeled, isFalse);
      relabeled = true;
      throw DioException(
          requestOptions: o, type: DioExceptionType.receiveTimeout);
    } else {
      throw StateError('Unexpected request ${o.path}');
    }
    return ResponseBody.fromString(jsonEncode({'result': 0, 'data': data}), 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }
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

  testWidgets('both split steps reject unavailable labels before confirmation',
      (tester) async {
    final adapter = GuidedSplitAdapter();
    CWMSHttpClient.getDio().httpClientAdapter = adapter;
    Map<String, dynamic>? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (_) => const GuidedManualPickSplitDialog(
                        sourceLpn: 'L000000001',
                        sourceQuantity: 48,
                        pickableQuantity: 40,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              )),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    Future<void> scan(String label) async {
      await tester.enterText(find.byType(TextField), label);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    for (final step in ['New picked LPN', 'New remainder LPN']) {
      expect(find.text(step), findsOneWidget);
      for (final (label, error) in [
        (
          'L000000004',
          'This LPN was not issued by this warehouse. Scan another label.'
        ),
        (
          'L000000005',
          'This LPN is already reserved or used. Scan another label.'
        ),
        ('L000000006', 'This LPN is already in use. Scan another label.'),
        ('L000000007', 'Could not verify this LPN. Scan again.'),
      ]) {
        await scan(label);
        expect(find.text(error), findsOneWidget);
        expect(find.text(step), findsOneWidget);
        expect(find.text('Confirm Pick'), findsNothing);
        final input = tester.widget<TextField>(find.byType(TextField));
        expect(input.controller!.text, isEmpty);
        expect(input.focusNode!.hasFocus, isTrue);
      }
      if (step == 'New remainder LPN') {
        await scan('L000000002');
        expect(find.text('Scan a different preprinted LPN.'), findsOneWidget);
      }
      await scan(step == 'New picked LPN' ? 'L000000002' : 'L000000003');
    }
    expect(adapter.calls, isNotEmpty);
    expect(adapter.calls.every((r) => r.method == 'GET'), isTrue);
    expect(find.textContaining('Keep 8 units at the original location'),
        findsOneWidget);
    expect(result, isNull);
    await tester.tap(find.text('Confirm Pick'));
    await tester.pumpAndSettle();
    expect(result, {
      'quantity': 40,
      'newLpn': 'L000000002',
      'remainderLpn': 'L000000003',
      'keepOriginal': false,
    });
  });

  test('48 -> 40 + 8 recovers lost relabel response without repeating pick',
      () async {
    final adapter = GuidedSplitAdapter();
    CWMSHttpClient.getDio().httpClientAdapter = adapter;
    final request = {
      ...details,
      'expectedQuantity': 48,
      'remainderLpn': 'L000000003'
    };
    await expectLater(PreprintedManualPickService.submit(request),
        throwsA(isA<DioException>()));
    final pending = await PreprintedManualPickService.pending();
    expect(pending?['pickConfirmed'], isTrue);
    expect(pending?['remainderInventoryId'], 42);
    await PreprintedManualPickService.submit(request);
    expect(await PreprintedManualPickService.pending(), isNull);
    expect(adapter.calls.where((r) => r.method == 'POST'), hasLength(2));
    expect(adapter.stock['quantity'], 8);
    expect(adapter.stock['locationId'], 3);
  });

  test(
      'queue acceptance frees scanner and timeout retry retains queue endpoint and UUID',
      () async {
    final adapter = SplitAdapter()
      ..queued = true
      ..timeout = true;
    CWMSHttpClient.getDio().httpClientAdapter = adapter;
    await expectLater(
        PreprintedManualPickService.submit({...details, 'queued': true}),
        throwsA(isA<DioException>()));
    expect((await PreprintedManualPickService.pending())!['queued'], true);
    adapter.timeout = false;
    await PreprintedManualPickService.submit(details);
    expect(adapter.calls.every((r) => r.path.endsWith('/manual-pick-queue')),
        isTrue);
    expect(adapter.calls[0].queryParameters, adapter.calls[1].queryParameters);
    expect(await PreprintedManualPickService.pending(), isNull);
    await PreprintedManualPickService.submit(
        {...details, 'queued': true, 'sourceLpn': 'L000000003'});
    expect(adapter.calls.last.queryParameters['requestId'],
        isNot(adapter.calls.first.queryParameters['requestId']));
  });
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
  test('server accepted but not completed is pending and silent', () async {
    var alarms = 0;
    ScanFeedback.failurePlayer = () async {
      alarms++;
    };
    addTearDown(() {
      ScanFeedback.failurePlayer = null;
    });
    final adapter = SplitAdapter()..completed = false;
    CWMSHttpClient.getDio().httpClientAdapter = adapter;
    await ScanFeedback.run(() async {
      try {
        await PreprintedManualPickService.submit(details);
        fail('Expected a pending result');
      } catch (error) {
        expect(ScanFeedback.reportError(error.toString()), isTrue);
      }
    });
    expect(await PreprintedManualPickService.pending(), isNotNull);
    expect(alarms, 0);
    expect(adapter.calls, hasLength(1));
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
  test('split can rescan only when server confirms cancellation', () async {
    final pending = {
      ...details,
      'requestId': 'existing-request',
      'remainderLpn': 'L000000003',
    };
    SharedPreferences.setMockInitialValues({
      'manual-pick-pending:https://example.test/api/:1:${Global.currentUser?.username}':
          jsonEncode(pending),
    });
    final adapter = SplitAdapter();
    CWMSHttpClient.getDio().httpClientAdapter = adapter;
    expect(await PreprintedManualPickService.cancelUnstarted(), isFalse);
    expect(await PreprintedManualPickService.pending(), pending);

    adapter.completedBeforeCancel = true;
    expect(await PreprintedManualPickService.cancelUnstarted(), isFalse);
    expect(await PreprintedManualPickService.pending(), pending);

    adapter.completedBeforeCancel = false;
    adapter.allowCancel = true;
    expect(await PreprintedManualPickService.cancelUnstarted(), isTrue);
    expect(await PreprintedManualPickService.pending(), isNull);
    expect(
        adapter.calls.every((r) =>
            r.path.endsWith('/cancel-unstarted') &&
            r.queryParameters['requestId'] == pending['requestId']),
        isTrue);
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
