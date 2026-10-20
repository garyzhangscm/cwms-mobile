import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/shared/models/rf.dart';
import 'package:cwms_mobile/states/profile_change_notifier.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/workorder/routes/work_order_qc_sampling.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';

class SamplingAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
      RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    calls.add(o);
    Object data;
    if (o.path == 'workorder/production-line-assignments') {
      data = [
        {
          'id': 7,
          'productionLine': {'id': 8, 'name': 'TEST-LINE'},
          'workOrderId': 9,
          'workOrderNumber': 'TEST-WO'
        }
      ];
    } else if (o.path == 'workorder/qc-samples' && o.method == 'GET') {
      data = [];
    } else if (o.path == 'workorder/qc-samples' && o.method == 'PUT') {
      data = {
        ...jsonDecode(o.data as String) as Map<String, dynamic>,
        'id': 10
      };
    } else if (o.path == 'inventory/qc-inspection-requests') {
      data = [];
    } else if (o.path.endsWith('/matched')) {
      data = [
        {
          'id': 4,
          'qcQuantity': 1,
          'workOrderQCRuleConfigurationRules': [
            {'id': 6, 'qcRuleId': 5}
          ]
        }
      ];
    } else if (o.path == 'inventory/qc-inspection-requests/work-order') {
      data = {
        'id': 20,
        'number': 'QC-TEST',
        'warehouseId': 1,
        'workOrderQCSampleId': 10,
        'type': 'BY_WORK_ORDER_SAMPLING',
        'qcInspectionResult': 'PENDING',
        'qcInspectionRequestItems': []
      };
    } else {
      throw StateError('Unexpected API: ${o.method} ${o.path}');
    }
    return ResponseBody.fromString(jsonEncode({'result': 0, 'data': data}), 200,
        headers: {
          Headers.contentTypeHeader: ['application/json']
        });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets(
      'Sampling registers once, opens exact QC task, and resumes after back',
      (tester) async {
    Global.currentFactory = null;
    Global.currentWarehouse = Warehouse()..id = 1;
    Global.currentUser = User()
      ..username = 'QC-TEST'
      ..token = 'mock';
    Global.lastLoginRF = RF();
    Global.currentServer = CWMSSiteInformation()..url = 'https://example.test/';
    CWMSHttpClient.resetForServer();
    final adapter = SamplingAdapter();
    CWMSHttpClient.getDio().httpClientAdapter = adapter;
    await tester.pumpWidget(ChangeNotifierProvider<UserModel>(
      create: (_) => UserModel(),
      child: MaterialApp(
        localizationsDelegates: [
          CWMSLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        supportedLocales: const [Locale('en'), Locale('es')],
        home: WorkOrderQCSamplingPage(),
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: settings,
          builder: (context) {
            final task = settings.arguments as QCInspectionRequest;
            return Scaffold(
                body: Column(children: [
              Text('Task ${task.id} / sample ${task.workOrderQCSampleId}'),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'))
            ]));
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'TEST-LINE');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(find.text('TEST-WO'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, 'SAMPLE-TEST');
    // A scanner submit invokes the same number-field callback.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    final register = find.text('Register & start questionnaire');
    await tester.ensureVisible(register);
    await tester.tap(register);
    await tester.pumpAndSettle();
    expect(find.text('Task 20 / sample 10'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Continue questionnaire'), findsOneWidget);
    final fields =
        tester.widgetList<TextFormField>(find.byType(TextFormField)).toList();
    expect(fields.first.enabled, isFalse);
    await tester.tap(find.text('Continue questionnaire'));
    await tester.pumpAndSettle();
    expect(find.text('Task 20 / sample 10'), findsOneWidget);
    expect(
        adapter.calls.where(
            (c) => c.path == 'workorder/qc-samples' && c.method == 'PUT'),
        hasLength(1));
    expect(
        adapter.calls.where(
            (c) => c.path == 'inventory/qc-inspection-requests/work-order'),
        hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
