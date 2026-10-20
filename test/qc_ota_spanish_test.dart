import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/inventory/models/qc_rule_item.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request_item_option.dart';
import 'package:cwms_mobile/inventory/services/qc_failure_review.dart';

void main() {
  final rows = (jsonDecode(
              File('test/fixtures/qc_spanish_source_audit.json').readAsStringSync())['rows']
          as List)
      .cast<Map<String, dynamic>>();
  Map<String, dynamic> payload(Map<String, dynamic> row) => {
        'id': row['id'],
        'checkPoint': row['checkPoint'],
        'checkPointEs': row['checkPointEs'],
        'enabled': row['enabled'] == 1,
        'expectedValue': row['expectedValue'],
        'qcRuleItemType': row['type'],
        'qcRuleItemComparator': row['comparator']
      };
  test(
      'all 40 assigned questions preserve rules and round-trip contracts in both languages',
      () {
    expect(rows.length, 40);
    expect(rows.where((r) => r['enabled'] == 1).length, 30);
    for (final row in rows) {
      final full = QCRuleItem.fromJson(payload(row));
      final legacy = QCRuleItem.fromJson(payload(row)..remove('checkPointEs'));
      final before = jsonEncode(legacy.toJson());
      expect(full.displayCheckPoint('es-MX'), row['checkPointEs']);
      expect(legacy.displayCheckPoint('es_US'), row['checkPointEs']);
      expect(legacy.displayCheckPoint('en'), row['checkPoint']);
      expect(jsonEncode(legacy.toJson()), before);
      expect(legacy.toJson().containsKey('checkPointEs'), false);
      expect(
          QCRuleItem.fromJson(payload(row)..['checkPointEs'] = null)
              .displayCheckPoint('es'),
          row['checkPoint']);
      expect(
          QCRuleItem.fromJson(payload(row)..['checkPointEs'] = ' ')
              .displayCheckPoint('es'),
          row['checkPoint']);
      expect(
          QCRuleItem.fromJson((payload(row)..remove('checkPointEs'))
                ..['checkPoint'] = 'Edited')
              .displayCheckPoint('es'),
          'Edited');
      for (final answer in [true, false, null]) {
        final option = QCInspectionRequestItemOption()
          ..qcRuleItem = legacy
          ..booleanValue = answer;
        final expected = QCFailureReview.evaluate(option);
        legacy.displayCheckPoint('es');
        expect(QCFailureReview.evaluate(option), expected);
        legacy.displayCheckPoint('en');
        expect(QCFailureReview.evaluate(option), expected);
        expect(legacy.expectedValue, row['expectedValue']);
        expect(legacy.qcRuleItemComparator.toString().split('.').last,
            row['comparator']);
      }
    }
  });
}
