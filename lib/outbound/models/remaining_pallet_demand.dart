import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'order.dart';

/// Quantities come from current shipment demand, never cached order openQuantity.
class RemainingPalletDemand {
  const RemainingPalletDemand({
    required this.itemName,
    required this.quantity,
    required this.unit,
    this.unitsPerPallet,
  });

  final String itemName;
  final int quantity;
  final String? unit;
  final int? unitsPerPallet;
  int? get fullPallets =>
      unitsPerPallet == null ? null : quantity ~/ unitsPerPallet!;
  int? get looseQuantity =>
      unitsPerPallet == null ? null : quantity % unitsPerPallet!;
  int? get estimatedPallets => unitsPerPallet == null
      ? null
      : (quantity + unitsPerPallet! - 1) ~/ unitsPerPallet!;

  static ItemPackageType? _standardPackage(Item? item) {
    if (item == null) return null;
    if (item.defaultItemPackageType != null) return item.defaultItemPackageType;
    final defaults =
        item.itemPackageTypes.where((p) => p.defaultFlag == true).toList();
    if (defaults.length == 1) return defaults.single;
    if (defaults.isEmpty && item.itemPackageTypes.length == 1) {
      return item.itemPackageTypes.single;
    }
    return null;
  }

  static bool _isPallet(String? value) => const {
        'PL',
        'PLT',
        'PALLET',
        'PALLETS'
      }.contains(value?.trim().toUpperCase());

  static List<RemainingPalletDemand> forOrder(
      Order order, Map<int, int> remaining) {
    return remaining.entries.where((e) => e.value > 0).map((entry) {
      final matching = order.orderLines.where((l) => l.id == entry.key);
      final item = matching.isEmpty ? null : matching.first.item;
      final pack = _standardPackage(item);
      final stock = pack?.stockItemUnitOfMeasure;
      final palletUnits = pack?.itemUnitOfMeasures
              .where((u) =>
                  _isPallet(u.unitOfMeasure?.name) ||
                  _isPallet(u.unitOfMeasure?.description))
              .toList() ??
          [];
      final sizes = palletUnits.map((u) => u.quantity).toSet();
      // Avoid guessing a base-unit conversion or choosing between conflicting packs.
      final size = stock?.quantity == 1 &&
              palletUnits.isNotEmpty &&
              sizes.length == 1 &&
              sizes.single != null &&
              sizes.single! > 0
          ? sizes.single
          : null;
      return RemainingPalletDemand(
        itemName: item?.name?.trim().isNotEmpty == true
            ? item!.name!
            : '#${entry.key}',
        quantity: entry.value,
        unit: stock?.unitOfMeasure?.name,
        unitsPerPallet: size,
      );
    }).toList(growable: false);
  }
}
