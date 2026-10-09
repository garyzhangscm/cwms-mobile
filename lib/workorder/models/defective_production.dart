import '../../inventory/models/item_unit_of_measure.dart';
import '../../auth/models/menu.dart';
import '../../inventory/models/inventory_status.dart';

/// Defective reporting inherits access to Produce; it uses the same API.
List<Menu> withDefectiveProductionMenu(List<Menu> menus) {
  if (!menus.any((m) => m.link == 'work_order_produce') ||
      menus.any((m) => m.link == 'work_order_defective')) {
    return List.of(menus);
  }
  final result = List<Menu>.of(menus);
  result.insert(
      result.indexWhere((m) => m.link == 'work_order_produce') + 1,
      Menu()
        ..name = 'Defective'
        ..text = 'Defective'
        ..link = 'work_order_defective');
  return result;
}

InventoryStatus? findDefectiveInventoryStatus(List<InventoryStatus> statuses) {
  final matches = statuses.where((status) {
    final name = (status.name ?? '').trim().toLowerCase();
    final description = (status.description ?? '').trim().toLowerCase();
    return status.id != null &&
        status.availableStatusFlag != true &&
        (name == 'dmg' || name == 'damaged' || description == 'damaged');
  }).toList();
  // Never guess or fall back to Available when configuration is ambiguous.
  return matches.length == 1 ? matches.single : null;
}

ItemUnitOfMeasure? findDefectivePiecesUnit(List<ItemUnitOfMeasure> units) {
  const piecesNames = {'pieces', 'piece', 'pcs', 'pc', '个', '件'};
  const eachNames = {'each', 'ea'};
  for (final names in [piecesNames, eachNames]) {
    final matches = units
        .where((unit) =>
            (unit.quantity ?? 0) > 0 &&
            (names.contains(
                    (unit.unitOfMeasure?.name ?? '').trim().toLowerCase()) ||
                names.contains((unit.unitOfMeasure?.description ?? '')
                    .trim()
                    .toLowerCase())))
        .toList();
    for (final unit in matches) {
      if (unit.quantity == 1) return unit;
    }
    if (matches.isNotEmpty) return matches.first;
  }
  return null;
}
