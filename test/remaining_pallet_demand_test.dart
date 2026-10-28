import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/common/models/unit_of_measure.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/models/item_unit_of_measure.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/order_line.dart';
import 'package:cwms_mobile/outbound/models/remaining_pallet_demand.dart';

ItemUnitOfMeasure uom(String name, int quantity) => ItemUnitOfMeasure()
  ..quantity = quantity
  ..unitOfMeasure = (UnitOfMeasure()..name = name);
ItemPackageType pack(int quantity, {String palletName = 'PL'}) =>
    ItemPackageType()
      ..stockItemUnitOfMeasure = uom('PCS', 1)
      ..itemUnitOfMeasures = [uom('PCS', 1), uom(palletName, quantity)];
Order orderWith(Item item) => Order()
  ..orderLines = [
    OrderLine()
      ..id = 10
      ..item = item
  ];
void main() {
  test(
      'remaining demand, full pallets and loose units use standard PL quantities',
      () {
    final item = Item()
      ..name = 'DEMO'
      ..defaultItemPackageType = pack(36);
    final row =
        RemainingPalletDemand.forOrder(orderWith(item), {10: 84}).single;
    expect(row.quantity, 84);
    expect(row.fullPallets, 2);
    expect(row.looseQuantity, 12);
    expect(row.estimatedPallets, 3);
    expect(
        RemainingPalletDemand.forOrder(orderWith(item), {10: 72})
            .single
            .estimatedPallets,
        2);
  });
  test('explicit default wins; unique default or single package can be used',
      () {
    final item = Item()
      ..itemPackageTypes = [pack(36), pack(48)..defaultFlag = true];
    expect(
        RemainingPalletDemand.forOrder(orderWith(item), {10: 96})
            .single
            .unitsPerPallet,
        48);
    item.defaultItemPackageType = pack(24);
    expect(
        RemainingPalletDemand.forOrder(orderWith(item), {10: 96})
            .single
            .unitsPerPallet,
        24);
    item.defaultItemPackageType = null;
    item.itemPackageTypes = [pack(36)];
    expect(
        RemainingPalletDemand.forOrder(orderWith(item), {10: 96})
            .single
            .unitsPerPallet,
        36);
  });
  for (final name in ['PL', ' plt ', 'Pallet', 'PALLETS']) {
    test('recognizes explicit pallet unit $name', () {
      final item = Item()..defaultItemPackageType = pack(36, palletName: name);
      expect(
          RemainingPalletDemand.forOrder(orderWith(item), {10: 40})
              .single
              .estimatedPallets,
          2);
    });
  }
  test(
      'ambiguous packages, carton units and missing base conversion do not guess',
      () {
    final item = Item()..itemPackageTypes = [pack(36), pack(48)];
    expect(
        RemainingPalletDemand.forOrder(orderWith(item), {10: 40})
            .single
            .unitsPerPallet,
        isNull);
    item.defaultItemPackageType = pack(36, palletName: 'CS');
    expect(
        RemainingPalletDemand.forOrder(orderWith(item), {10: 40})
            .single
            .unitsPerPallet,
        isNull);
    item.defaultItemPackageType = pack(36)
      ..stockItemUnitOfMeasure = uom('PCS', 2);
    expect(
        RemainingPalletDemand.forOrder(orderWith(item), {10: 40})
            .single
            .unitsPerPallet,
        isNull);
  });
  test('invalid or conflicting pallet sizes are not estimated', () {
    final item = Item()..defaultItemPackageType = pack(0);
    expect(
        RemainingPalletDemand.forOrder(orderWith(item), {10: 40})
            .single
            .unitsPerPallet,
        isNull);
    item.defaultItemPackageType = pack(36)
      ..itemUnitOfMeasures.add(uom('PLT', 48));
    expect(
        RemainingPalletDemand.forOrder(orderWith(item), {10: 40})
            .single
            .unitsPerPallet,
        isNull);
  });
  test(
      'unrecognized demand lines are not silently omitted; completed lines are hidden',
      () {
    final rows = RemainingPalletDemand.forOrder(Order(), {10: 40, 11: 0});
    expect(rows, hasLength(1));
    expect(rows.single.quantity, 40);
    expect(rows.single.unitsPerPallet, isNull);
  });
}
