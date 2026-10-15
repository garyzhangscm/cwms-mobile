import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request_item.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request_item_option.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/inventory/models/qc_rule_item.dart';
import 'package:cwms_mobile/inventory/models/qc_rule.dart';
import 'package:cwms_mobile/inventory/models/qc_rule_item_type.dart';
import 'package:cwms_mobile/inventory/models/qc_rule_item_comparator.dart';
import 'package:cwms_mobile/inventory/services/qc_failure_review.dart';
import 'package:cwms_mobile/inventory/widgets/qc_inspection_item_option_list_item.dart';

QCInspectionRequestItemOption option() => QCInspectionRequestItemOption()
  ..id = 10
  ..qcInspectionResult = QCInspectionResult.PENDING
  ..qcRuleItem = (QCRuleItem()
    ..id = 1
    ..enabled = true
    ..checkPoint = 'Packaging damaged?'
    ..qcRuleItemType = QCRuleItemType.YESNO
    ..qcRuleItemComparator = QCRuleItemComparator.EQUAL
    ..expectedValue = 'false');
void main() {
  test('No is an actual answer; missing is pending and wrong Yes fails', () {
    final o = option();
    expect(QCFailureReview.evaluate(o), QCInspectionResult.PENDING);
    o.booleanValue = false;
    expect(QCFailureReview.evaluate(o), QCInspectionResult.PASS);
    o.booleanValue = true;
    expect(QCFailureReview.evaluate(o), QCInspectionResult.FAIL);
  });
  test('numeric zero is answered, nonfinite and empty are pending', () {
    final o = option();
    o.qcRuleItem!
      ..qcRuleItemType = QCRuleItemType.NUMBER
      ..expectedValue = '0';
    o.doubleValue = 0;
    expect(QCFailureReview.evaluate(o), QCInspectionResult.PASS);
    o.doubleValue = double.nan;
    expect(QCFailureReview.evaluate(o), QCInspectionResult.PENDING);
  });
  test('notes required and bounded', () {
    final o = option();
    o.exceptionNotes = '  ';
    expect(QCFailureReview.validNotes(o), false);
    o.exceptionNotes = ' torn bag ';
    expect(QCFailureReview.validNotes(o), true);
    o.exceptionNotes = 'x' * 2001;
    expect(QCFailureReview.validNotes(o), false);
  });
  test(
      'submission trims failure notes without changing draft and serializes them',
      () {
    final o = option()
      ..booleanValue = true
      ..exceptionNotes = ' torn bag ';
    final r = QCInspectionRequest()
      ..id = 1
      ..qcInspectionResult = QCInspectionResult.PENDING
      ..qcInspectionRequestItems = [
        QCInspectionRequestItem()
          ..id = 2
          ..qcInspectionResult = QCInspectionResult.PENDING
          ..qcRule = (QCRule()..id = 3)
          ..qcInspectionRequestItemOptions = [o]
      ];
    final copy = QCFailureReview.submission(r);
    expect(copy.qcInspectionResult, QCInspectionResult.FAIL);
    expect(
        copy.qcInspectionRequestItems.first.qcInspectionRequestItemOptions.first
            .exceptionNotes,
        'torn bag');
    expect(o.exceptionNotes, ' torn bag ');
    expect(
        copy.qcInspectionRequestItems.first.qcInspectionRequestItemOptions.first
            .toJson()['exceptionNotes'],
        'torn bag');
  });
  testWidgets(
      'explicit answers show warning and required notes; correction preserves notes',
      (t) async {
    final o = option();
    final form = GlobalKey<FormState>();
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: Form(
                    key: form,
                    child: QCInspectionItemOptionListItem(
                        qcInspectionRequestItemOption: o))))));
    expect(
        t.widget<ChoiceChip>(find.byKey(const ValueKey('qc-no-10'))).selected,
        false);
    await t.tap(find.byKey(const ValueKey('qc-yes-10')));
    await t.pump();
    expect(find.byKey(const ValueKey('qc-notes-10')), findsOneWidget);
    expect(form.currentState!.validate(), false);
    await t.enterText(find.byKey(const ValueKey('qc-notes-10')), 'torn wrap');
    await t.pump();
    expect(form.currentState!.validate(), true);
    await t.tap(find.byKey(const ValueKey('qc-no-10')));
    await t.pump();
    expect(find.byKey(const ValueKey('qc-notes-10')), findsNothing);
    await t.tap(find.byKey(const ValueKey('qc-yes-10')));
    await t.pump();
    expect(find.text('torn wrap'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
