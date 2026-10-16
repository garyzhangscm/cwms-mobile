import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/qc_rule_item.dart';
import 'package:cwms_mobile/inventory/models/qc_rule.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request_item.dart';
import 'package:cwms_mobile/inventory/routes/qc_inspection.dart';
import 'package:cwms_mobile/inventory/models/qc_rule_item_type.dart';
import 'package:cwms_mobile/inventory/models/qc_rule_item_comparator.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request_item_option.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/inventory/widgets/qc_inspection_item_option_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('old payload works and Spanish round-trips without changing standards',
      () {
    final old = QCRuleItem.fromJson({
      'id': 4,
      'checkPoint': 'Does it meet the standard?',
      'expectedValue': 'true',
      'qcRuleItemType': 'YESNO',
      'qcRuleItemComparator': 'EQUAL'
    });
    expect(old.displayCheckPoint('es'), old.checkPoint);
    expect(old.toJson().containsKey('checkPointEs'), false);
    old.checkPointEs = '¿Cumple con el estándar?';
    final copy = QCRuleItem.fromJson(old.toJson());
    expect(copy.displayCheckPoint('es-MX'), '¿Cumple con el estándar?');
    expect(copy.displayCheckPoint('en'), old.checkPoint);
    expect(copy.displayCheckPoint('zh'), old.checkPoint);
    expect(copy.expectedValue, 'true');
    expect(copy.id, 4);
    copy.checkPointEs = '  ';
    expect(copy.displayCheckPoint('es_US'), old.checkPoint);
  });

  testWidgets(
      'Spanish question, Yes/No and warnings retain original result contract',
      (tester) async {
    final option = QCInspectionRequestItemOption()
      ..id = 20
      ..qcInspectionResult = QCInspectionResult.PENDING
      ..qcRuleItem = (QCRuleItem()
        ..id = 4
        ..checkPoint = 'Does it meet the standard?'
        ..checkPointEs = '¿Cumple con el estándar?'
        ..qcRuleItemType = QCRuleItemType.YESNO
        ..qcRuleItemComparator = QCRuleItemComparator.EQUAL
        ..expectedValue = 'true'
        ..enabled = true);
    Widget app(Locale locale) => MaterialApp(
          locale: locale,
          supportedLocales: const [Locale('en', 'US'), Locale('es', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            CWMSLocalizationsDelegate(),
          ],
          home: Scaffold(
              body: SingleChildScrollView(
                  child: QCInspectionItemOptionListItem(
                      qcInspectionRequestItemOption: option))),
        );
    await tester.pumpWidget(app(const Locale('es', 'US')));
    await tester.pumpAndSettle();
    expect(find.text('¿Cumple con el estándar?'), findsOneWidget);
    expect(find.text('Sí'), findsOneWidget);
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(option.qcInspectionResult, QCInspectionResult.FAIL);
    expect(find.textContaining('Esta respuesta no cumple'), findsOneWidget);
    expect(find.textContaining('Notas de la incidencia'), findsOneWidget);
    await tester.pumpWidget(app(const Locale('en', 'US')));
    await tester.pumpAndSettle();
    expect(find.text('Does it meet the standard?'), findsOneWidget);
    expect(option.qcInspectionResult, QCInspectionResult.FAIL);
    expect(option.booleanValue, false);
    expect(option.qcRuleItem!.expectedValue, 'true');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Spanish locale uses translated common buttons', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es', 'US'),
      supportedLocales: const [Locale('es', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        CWMSLocalizationsDelegate()
      ],
      home: Builder(
          builder: (context) => Text(
              '${CWMSLocalizations.of(context).confirm} / ${CWMSLocalizations.of(context).cancel} / ${CWMSLocalizations.of(context).language}')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Confirmar / Cancelar / Idioma'), findsOneWidget);
  });
  for (final width in [320.0, 430.0, 1024.0]) {
    testWidgets('Spanish QC question fits width $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final option = QCInspectionRequestItemOption()
        ..id = 20
        ..qcInspectionResult = QCInspectionResult.PENDING
        ..qcRuleItem = (QCRuleItem()
          ..id = 4
          ..enabled = true
          ..checkPoint = 'Does it meet the standard?'
          ..checkPointEs =
              '¿El producto cumple con el estándar de calidad establecido?'
          ..qcRuleItemType = QCRuleItemType.YESNO
          ..qcRuleItemComparator = QCRuleItemComparator.EQUAL
          ..expectedValue = 'true');
      final request = QCInspectionRequest()
        ..qcInspectionRequestItems = [
          QCInspectionRequestItem()
            ..qcRule = (QCRule()..name = 'QC_RAW')
            ..qcInspectionRequestItemOptions = [option]
        ];
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('es', 'US'),
        supportedLocales: const [Locale('es', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          CWMSLocalizationsDelegate()
        ],
        onGenerateRoute: (_) => MaterialPageRoute(
            settings: RouteSettings(arguments: request),
            builder: (_) => QCInspectionPage()),
      ));
      await tester.pumpAndSettle();
      expect(
          find.text(
              '¿El producto cumple con el estándar de calidad establecido?'),
          findsOneWidget);
      expect(find.text('0 de 1 puntos completados'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
