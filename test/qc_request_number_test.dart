import 'dart:async';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/inventory/routes/qc_inspection.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

QCInspectionRequest _request(String? number) => QCInspectionRequest.fromJson({
      'id': 42,
      'number': number,
      'qcInspectionRequestItems': [
        {
          'id': 7,
          'qcRule': {'id': 8, 'name': 'QC_FG'},
          'qcInspectionRequestItemOptions': [
            {
              'id': 10,
              'qcInspectionResult': 'PENDING',
              'qcRuleItem': {
                'id': 9,
                'enabled': true,
                'checkPoint': 'Does appearance match the sample?',
                'qcRuleItemType': 'YESNO',
                'qcRuleItemComparator': 'EQUAL',
                'expectedValue': 'true',
              }
            }
          ]
        }
      ]
    });

Future<void> _open(WidgetTester t, QCInspectionRequest request,
    Future<QCInspectionRequest> prepared,
    {required Size size, Locale locale = const Locale('en')}) async {
  Global.currentFactory = null;
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('zh'), Locale('es')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      CWMSLocalizationsDelegate(),
    ],
    onGenerateRoute: (_) => MaterialPageRoute(
      settings: RouteSettings(arguments: request),
      builder: (_) => QCInspectionPage(prepare: (_) => prepared),
    ),
  ));
  await t.pump();
}

void main() {
  for (final size in [const Size(1366, 1024), const Size(430, 932)]) {
    testWidgets(
        'server-prepared QCR remains visible at $size and with keyboard',
        (t) async {
      final prepared = Completer<QCInspectionRequest>();
      await _open(t, _request('QCR-STALE'), prepared.future, size: size);
      expect(find.text('QCR-STALE'), findsNothing);
      prepared.complete(_request('QCR0000064508'));
      await t.pumpAndSettle();
      final number = find.byKey(const ValueKey('qc-request-number'));
      expect(t.widget<SelectableText>(number).data, 'QCR0000064508');
      expect(find.text('QCR Number'), findsOneWidget);
      expect(find.text('QC_FG'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('qc-yes-10')));
      await t.pumpAndSettle();
      expect(t.widget<SelectableText>(number).data, 'QCR0000064508');
      t.view.viewInsets = const FakeViewPadding(bottom: 250);
      await t.pumpAndSettle();
      expect(t.widget<SelectableText>(number).data, 'QCR0000064508');
      expect(t.takeException(), isNull);
    });
  }
  testWidgets(
      'missing request number is not fabricated from rule or database ID',
      (t) async {
    final request = _request('  ');
    await _open(t, request, Future.value(request),
        size: const Size(1366, 1024), locale: const Locale('es'));
    await t.pumpAndSettle();
    expect(find.text('Número QCR'), findsOneWidget);
    expect(
        t
            .widget<SelectableText>(
                find.byKey(const ValueKey('qc-request-number')))
            .data,
        'No disponible');
    expect(find.text('42'), findsNothing);
    expect(t.takeException(), isNull);
  });
}
