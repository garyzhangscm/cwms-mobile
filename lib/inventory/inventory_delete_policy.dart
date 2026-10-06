import 'package:cwms_mobile/inventory/models/inventory.dart';

Inventory requireSingleOutInventory(
    List<Inventory> inventories, String requestedLpn) {
  if (inventories.isEmpty) {
    throw StateError('No inventory found for $requestedLpn.');
  }
  if (inventories.length != 1) {
    throw StateError('Multiple inventory records found. Nothing was deleted.');
  }

  final inventory = inventories.single;
  if (inventory.lpn?.trim().toUpperCase() != requestedLpn.toUpperCase()) {
    throw StateError('The returned LPN does not match. Nothing was deleted.');
  }
  if (inventory.id == null ||
      inventory.location?.name?.trim().toLowerCase() != 'out') {
    throw StateError('Only inventory in location out can be deleted.');
  }

  return inventory;
}
