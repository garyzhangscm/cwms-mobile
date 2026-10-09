import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/workorder/models/work_order_produce_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Damaged preserves required and optional producing configuration', () {
    for (final required in [false, true]) {
      for (final optional in [false, true]) {
        final status = InventoryStatus.fromJson({
          'id': 9,
          'name': 'Damaged',
          'reasonRequiredWhenProducing': required,
          'reasonOptionalWhenProducing': optional,
        });
        expect(status.reasonRequiredWhenProducing, required);
        expect(status.reasonOptionalWhenProducing, optional);
      }
    }
  });

  test('missing producing reason configuration does not imply required', () {
    final status = InventoryStatus.fromJson({'id': 9, 'name': 'Damaged'});
    expect(status.reasonRequiredWhenProducing, false);
    expect(status.reasonOptionalWhenProducing, false);
  });

  test('produce request supports absent optional reason and selected reason ID', () {
    final transaction = WorkOrderProduceTransaction();
    expect(transaction.toJson()['reasonCodeId'], isNull);
    transaction.reasonCodeId = 42;
    expect(transaction.toJson()['reasonCodeId'], 42);
  });
}
