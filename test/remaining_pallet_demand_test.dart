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
  test('decomposes pallets, then cases, then remaining pieces exactly', () {
    final item = Item()
      ..defaultItemPackageType =
          (pack(120)..itemUnitOfMeasures.add(uom('CS', 4)));
    for (final quantity in [1, 3, 4, 9, 119, 120, 121, 2289]) {
      final row =
          RemainingPalletDemand.forOrder(orderWith(item), {10: quantity})
              .single;
      expect(row.fullPallets! * 120 + row.fullCases! * 4 + row.loosePieces,
          quantity);
      expect(row.loosePieces, lessThan(4));
    }
    final row =
        RemainingPalletDemand.forOrder(orderWith(item), {10: 2289}).single;
    expect(row.fullPallets, 19);
    expect(row.fullCases, 2);
    expect(row.loosePieces, 1);
    expect(row.looseQuantity, 9); // Existing pallet-remainder API is unchanged.
    expect(row.estimatedPallets, 20);
  });
  for (final name in ['CS', ' case ', 'CASES', 'CTN', 'Carton', 'CARTONS']) {
    test('recognizes explicit case unit $name', () {
      final item = Item()
        ..defaultItemPackageType =
            (pack(120)..itemUnitOfMeasures.add(uom(name, 6)));
      final row =
          RemainingPalletDemand.forOrder(orderWith(item), {10: 2289}).single;
      expect(row.fullCases, 1);
      expect(row.loosePieces, 3);
    });
  }
  test('does not depend on pallet size being a multiple of case size', () {
    final item = Item()
      ..defaultItemPackageType =
          (pack(10)..itemUnitOfMeasures.add(uom('CS', 4)));
    final row =
        RemainingPalletDemand.forOrder(orderWith(item), {10: 27}).single;
    expect(row.fullPallets, 2);
    expect(row.fullCases, 1);
    expect(row.loosePieces, 3);
  });
  test('can show cases and pieces when pallet size is missing', () {
    final item = Item()..defaultItemPackageType = (pack(6, palletName: 'CS'));
    final row =
        RemainingPalletDemand.forOrder(orderWith(item), {10: 15}).single;
    expect(row.unitsPerPallet, isNull);
    expect(row.fullCases, 2);
    expect(row.loosePieces, 3);
    expect(row.estimatedPallets, isNull);
  });
  test('invalid or conflicting case sizes preserve the exact PCS remainder',
      () {
    for (final cases in [
      <ItemUnitOfMeasure>[],
      [uom('CS', 0)],
      [uom('CS', -6)],
      [uom('CS', 121)],
      [uom('CS', 6)..quantity = null],
      [uom('CS', 6), uom('CTN', 12)],
      [uom('CS', 6), uom('CTN', 0)],
    ]) {
      final item = Item()
        ..defaultItemPackageType =
            (pack(120)..itemUnitOfMeasures.addAll(cases));
      final row =
          RemainingPalletDemand.forOrder(orderWith(item), {10: 2289}).single;
      expect(row.unitsPerCase, isNull);
      expect(row.fullCases, isNull);
      expect(row.loosePieces, 9);
    }
  });
  test('duplicate case aliases with the same size are unambiguous', () {
    final item = Item()
      ..defaultItemPackageType =
          (pack(120)..itemUnitOfMeasures.addAll([uom('CS', 6), uom('CTN', 6)]));
    final row =
        RemainingPalletDemand.forOrder(orderWith(item), {10: 2289}).single;
    expect(row.fullCases, 1);
    expect(row.loosePieces, 3);
  });
  test('cases come from the selected standard package, never another pack', () {
    final item = Item()
      ..defaultItemPackageType =
          (pack(120)..itemUnitOfMeasures.add(uom('CS', 4)))
      ..itemPackageTypes = [pack(144)..itemUnitOfMeasures.add(uom('CS', 6))];
    final row =
        RemainingPalletDemand.forOrder(orderWith(item), {10: 2289}).single;
    expect(row.unitsPerCase, 4);
  });
  test('weight, stock cases and unknown base conversions are not called pieces',
      () {
    for (final stock in [uom('LB', 1), uom('CS', 1), uom('PCS', 2)]) {
      final item = Item()
        ..defaultItemPackageType = (pack(120)
          ..stockItemUnitOfMeasure = stock
          ..itemUnitOfMeasures.add(uom('CS', 6)));
      final row =
          RemainingPalletDemand.forOrder(orderWith(item), {10: 2289}).single;
      expect(row.unitsPerCase, isNull);
      expect(row.unit, stock.unitOfMeasure!.name);
    }
  });
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
