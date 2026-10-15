import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request_item.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request_item_option.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/inventory/models/qc_rule.dart';
import 'package:cwms_mobile/inventory/models/qc_rule_item.dart';
import 'package:cwms_mobile/inventory/routes/qc_inspection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final enabled in [false, true]) {
    testWidgets(
        'QC form with enabled=$enabled cannot submit an empty inspection',
        (tester) async {
      final options = List.generate(
          2,
          (i) => QCInspectionRequestItemOption()
            ..qcRuleItem = (QCRuleItem()
              ..id = i + 1
              ..enabled = enabled
              ..checkPoint = 'Check ${i + 1}')
            ..qcInspectionResult = QCInspectionResult.PENDING);
      final request = QCInspectionRequest()
        ..qcInspectionRequestItems = [
          QCInspectionRequestItem()
            ..qcRule = (QCRule()..name = 'QC RAW')
            ..qcInspectionRequestItemOptions = options
        ];
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          CWMSLocalizationsDelegate()
        ],
        onGenerateRoute: (_) => MaterialPageRoute(
            settings: RouteSettings(arguments: request),
            builder: (_) => QCInspectionPage()),
      ));
      await tester.pumpAndSettle();
      final confirm = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Confirm'));
      expect(confirm.onPressed != null, enabled);
      if (enabled) {
        expect(find.text('Check 1'), findsOneWidget);
        expect(find.text('Check 2'), findsOneWidget);
        expect(find.text('0 of 2 checks completed'), findsOneWidget);
      } else {
        expect(find.textContaining('No enabled inspection checks'),
            findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
