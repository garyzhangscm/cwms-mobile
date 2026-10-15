import 'dart:convert';

import '../models/qc_inspection_request.dart';
import '../models/qc_inspection_request_item_option.dart';
import '../models/qc_inspection_result.dart';
import '../models/qc_rule_item_comparator.dart';
import '../models/qc_rule_item_type.dart';

/// Client preview only. The confirmed API evaluates trusted persisted rules.
class QCFailureReview {
  static const maxNotesLength = 2000;
  static List<QCInspectionRequestItemOption> enabledOptions(
    QCInspectionRequest r,
  ) =>
      r.qcInspectionRequestItems
          .expand((g) => g.qcInspectionRequestItemOptions)
          .where((o) => o.qcRuleItem?.enabled == true)
          .toList();

  static QCInspectionResult evaluate(QCInspectionRequestItemOption o) {
    final rule = o.qcRuleItem, kind = rule?.qcRuleItemType;
    final expected = rule?.expectedValue,
        comparator = rule?.qcRuleItemComparator;
    if (expected == null || comparator == null)
      return QCInspectionResult.PENDING;
    bool pass;
    switch (kind) {
      case QCRuleItemType.YESNO:
        if (o.booleanValue == null ||
            comparator != QCRuleItemComparator.EQUAL ||
            !['true', 'false'].contains(expected.toLowerCase()))
          return QCInspectionResult.PENDING;
        pass = o.booleanValue == (expected.toLowerCase() == 'true');
        break;
      case QCRuleItemType.NUMBER:
        final target = double.tryParse(expected), actual = o.doubleValue;
        if (target == null ||
            !target.isFinite ||
            actual == null ||
            !actual.isFinite) return QCInspectionResult.PENDING;
        switch (comparator) {
          case QCRuleItemComparator.EQUAL:
            pass = actual == target;
            break;
          case QCRuleItemComparator.GREAT_THAN:
            pass = actual > target;
            break;
          case QCRuleItemComparator.LESS_THAN:
            pass = actual < target;
            break;
          case QCRuleItemComparator.GREAT_OR_EQUAL:
            pass = actual >= target;
            break;
          case QCRuleItemComparator.LESS_OR_EQUAL:
            pass = actual <= target;
            break;
          default:
            return QCInspectionResult.PENDING;
        }
        break;
      case QCRuleItemType.STRING:
        final actual = o.stringValue;
        if (actual == null || actual.trim().isEmpty)
          return QCInspectionResult.PENDING;
        if (comparator == QCRuleItemComparator.EQUAL)
          pass = actual == expected;
        else if (comparator == QCRuleItemComparator.LIKE)
          pass = expected.trim().toLowerCase().contains(
                actual.trim().toLowerCase(),
              );
        else
          return QCInspectionResult.PENDING;
        break;
      default:
        return QCInspectionResult.PENDING;
    }
    return pass ? QCInspectionResult.PASS : QCInspectionResult.FAIL;
  }

  static QCInspectionResult aggregate(Iterable<QCInspectionResult?> values) {
    final results = values.toList();
    if (results.contains(QCInspectionResult.FAIL))
      return QCInspectionResult.FAIL;
    if (results.isEmpty ||
        results.contains(null) ||
        results.contains(QCInspectionResult.PENDING))
      return QCInspectionResult.PENDING;
    return QCInspectionResult.PASS;
  }

  static List<QCInspectionRequestItemOption> failures(QCInspectionRequest r) =>
      enabledOptions(r)
          .where((o) => evaluate(o) == QCInspectionResult.FAIL)
          .toList();
  static bool validNotes(QCInspectionRequestItemOption o) {
    final notes = o.exceptionNotes?.trim() ?? '';
    return notes.isNotEmpty && notes.length <= maxNotesLength;
  }

  static bool complete(QCInspectionRequest r) =>
      enabledOptions(r).isNotEmpty &&
      enabledOptions(r).every((o) => evaluate(o) != QCInspectionResult.PENDING);

  /// Copy before normalizing; returning to the form retains every draft value.
  static QCInspectionRequest submission(QCInspectionRequest r) {
    final copy = QCInspectionRequest.fromJson(
      jsonDecode(jsonEncode(r)) as Map<String, dynamic>,
    );
    for (final group in copy.qcInspectionRequestItems) {
      for (final option in group.qcInspectionRequestItemOptions) {
        option.qcInspectionResult = option.qcRuleItem?.enabled == true
            ? evaluate(option)
            : QCInspectionResult.NOT_APPLY;
        option.exceptionNotes =
            option.qcInspectionResult == QCInspectionResult.FAIL
                ? option.exceptionNotes?.trim()
                : null;
      }
      group.qcInspectionResult = aggregate(
        group.qcInspectionRequestItemOptions.map((o) => o.qcInspectionResult),
      );
    }
    copy.qcInspectionResult = aggregate(
      copy.qcInspectionRequestItems.map((g) => g.qcInspectionResult),
    );
    return copy;
  }
}
