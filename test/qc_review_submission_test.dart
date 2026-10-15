import 'package:cwms_mobile/shared/models/factory_profile.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/inventory/services/qc_inspection.dart';
import 'package:cwms_mobile/inventory/routes/qc_inspection.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';

QCInspectionRequest fixture() => QCInspectionRequest.fromJson({
      'id': 1,
      'warehouseId': 1,
      'number': 'QC-TEST',
      'qcInspectionResult': 'PENDING',
      'qcInspectionRequestItems': [
        {
          'id': 2,
          'qcRule': {'id': 3, 'name': 'Packaging'},
          'qcInspectionResult': 'PENDING',
          'qcInspectionRequestItemOptions': [
            {
              'id': 10,
              'qcInspectionResult': 'PENDING',
              'qcRuleItem': {
                'id': 4,
                'enabled': true,
                'checkPoint': 'Packaging damaged?',
                'qcRuleItemType': 'YESNO',
                'qcRuleItemComparator': 'EQUAL',
                'expectedValue': 'false'
              }
            }
          ]
        }
      ]
    });

class Adapter implements HttpClientAdapter {
  Adapter(this.reply);
  final Future<ResponseBody> Function(RequestOptions) reply;
  final calls = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? s, Future<void>? c) {
    calls.add(o);
    return reply(o);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() {
    Global.currentWarehouse = Warehouse()..id = 1;
    Global.currentFactory = null;
  });
  test(
      'confirmed contract includes acknowledgement and notes; no legacy fallback',
      () async {
    final a = Adapter((o) async => ResponseBody.fromString(
            jsonEncode({
              'result': 0,
              'data': [fixture().toJson()]
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json']
            }));
    final d = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = a;
    final r = fixture();
    r.qcInspectionRequestItems.first.qcInspectionRequestItemOptions.first
        .exceptionNotes = 'damaged';
    await QCInspectionService.saveQCInspectionRequest([r],
        failureAcknowledged: true, client: d);
    expect(a.calls.single.path, '/inventory/qc-inspection-requests/confirmed');
    expect(a.calls.single.queryParameters['warehouseId'], 1);
    expect(a.calls.single.queryParameters['failureAcknowledged'], true);
    expect(a.calls.single.data, contains('damaged'));
  });
  for (final status in [404, 500]) {
    test('HTTP $status never retries or falls back', () async {
      final a = Adapter((o) async => ResponseBody.fromString('{}', status));
      final d = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = a;
      await expectLater(
          QCInspectionService.saveQCInspectionRequest([fixture()], client: d),
          throwsA(isA<QCSubmissionException>()
              .having((e) => e.outcomeUnknown, 'uncertain', status == 500)));
      expect(a.calls, hasLength(1));
    });
  }
  Future<void> page(WidgetTester t, QCReviewSubmitter submit,
      {Future<QCInspectionRequest> Function(int)? checkStatus}) async {
    t.view.physicalSize = const Size(430, 932);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          CWMSLocalizationsDelegate()
        ],
        onGenerateRoute: (_) => MaterialPageRoute(
            settings: RouteSettings(arguments: fixture()),
            builder: (_) => QCInspectionPage(
                submit: submit,
                prepare: (r) async => r,
                checkStatus: checkStatus))));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
  }

  testWidgets(
      'missing notes blocks submit and final confirmation can return without losing draft',
      (t) async {
    int calls = 0;
    await page(t, (r, {required failureAcknowledged}) async {
      calls++;
      return r;
    });
    await t.tap(find.byKey(const ValueKey('qc-yes-10')));
    await t.pump();
    await t.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(calls, 0);
    await t.tap(find.text('OK'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    await t.enterText(find.byKey(const ValueKey('qc-notes-10')), 'torn bag');
    await t.pump();
    await t.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('torn bag'), findsWidgets);
    expect(calls, 0);
    await t.tap(find.text('Return to inspection'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('torn bag'), findsOneWidget);
    expect(calls, 0);
  });
  testWidgets(
      'explicit failure confirmation sends notes and acknowledgement once',
      (t) async {
    int calls = 0;
    bool ack = false;
    QCInspectionRequest? sent;
    await page(t, (r, {required failureAcknowledged}) async {
      calls++;
      ack = failureAcknowledged;
      sent = r.single;
      return r;
    });
    await t.tap(find.byKey(const ValueKey('qc-yes-10')));
    await t.pump();
    await t.enterText(find.byKey(const ValueKey('qc-notes-10')), 'torn bag');
    await t.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('Confirm and submit Fail'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(calls, 1);
    expect(ack, true);
    expect(sent!.qcInspectionResult, QCInspectionResult.FAIL);
    expect(
        sent!.qcInspectionRequestItems.first.qcInspectionRequestItemOptions
            .first.exceptionNotes,
        'torn bag');
    expect(t.takeException(), isNull);
  });
  testWidgets('expected No passes without failure confirmation', (t) async {
    int calls = 0;
    await page(t, (r, {required failureAcknowledged}) async {
      calls++;
      expect(failureAcknowledged, false);
      expect(r.single.qcInspectionResult, QCInspectionResult.PASS);
      return r;
    });
    await t.tap(find.byKey(const ValueKey('qc-no-10')));
    await t.pump();
    await t.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(calls, 1);
    expect(t.takeException(), isNull);
  });
  testWidgets('unknown submission requires status check before any retry',
      (t) async {
    int calls = 0, checks = 0;
    await page(t, (r, {required failureAcknowledged}) async {
      calls++;
      throw QCSubmissionException('Connection lost', outcomeUnknown: true);
    }, checkStatus: (id) async {
      checks++;
      return fixture();
    });
    await t.tap(find.byKey(const ValueKey('qc-no-10')));
    await t.pump();
    await t.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('OK'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(calls, 1);
    expect(find.text('Check submission status'), findsOneWidget);
    await t.tap(find.text('Check submission status'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(checks, 1);
    expect(calls, 1);
    await t.tap(find.text('OK'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Confirm'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  test(
      'only Luggage may use the legacy contract, without unsupported notes fields',
      () async {
    Global.currentFactory = FactoryProfile.byId('mira-loma-luggage');
    final a = Adapter((o) async => ResponseBody.fromString(
            jsonEncode({
              'result': 0,
              'data': [fixture().toJson()]
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json']
            }));
    final d = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = a;
    final r = fixture();
    r.qcInspectionRequestItems.first.qcInspectionRequestItemOptions.first
        .exceptionNotes = 'not supported';
    await QCInspectionService.saveLegacyQCInspectionRequest([r], client: d);
    expect(a.calls.single.path, '/inventory/qc-inspection-requests');
    expect(a.calls.single.queryParameters.containsKey('failureAcknowledged'),
        false);
    expect(a.calls.single.data, isNot(contains('exceptionNotes')));
    Global.currentFactory = FactoryProfile.byId('colton-injection');
    await expectLater(
        QCInspectionService.saveLegacyQCInspectionRequest([r], client: d),
        throwsA(isA<QCSubmissionException>()));
    expect(a.calls, hasLength(1));
  });
  testWidgets(
      'Luggage retains legacy QC without calling prepare or requiring new notes',
      (t) async {
    Global.currentFactory = FactoryProfile.byId('mira-loma-luggage');
    int calls = 0;
    await page(t, (r, {required failureAcknowledged}) async {
      calls++;
      expect(failureAcknowledged, false);
      return r;
    });
    await t.tap(find.byKey(const ValueKey('qc-yes-10')));
    await t.pump();
    expect(find.byKey(const ValueKey('qc-notes-10')), findsNothing);
    await t.tap(find.widgetWithText(ElevatedButton, 'Confirm'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(calls, 1);
    expect(find.text('Confirm and submit Fail'), findsNothing);
    expect(t.takeException(), isNull);
  });
}
