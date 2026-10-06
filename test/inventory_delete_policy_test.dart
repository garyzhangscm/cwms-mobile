import 'package:cwms_mobile/inventory/inventory_delete_policy.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:flutter_test/flutter_test.dart';

Inventory inventory(String lpn, String locationName) {
  final result = Inventory()
    ..id = 42
    ..lpn = lpn
    ..quantity = 10;
  result.location = WarehouseLocation()..name = locationName;
  return result;
}

void main() {
  test('allows exactly one matching LPN in out', () {
    final candidate = inventory('R10000212016', 'OUT');
    expect(requireSingleOutInventory([candidate], 'R10000212016'), candidate);
  });

  test('rejects missing, multiple, mismatched and non-out inventory', () {
    final candidate = inventory('R10000212016', 'out');
    expect(
        () => requireSingleOutInventory([], 'R10000212016'), throwsStateError);
    expect(
        () => requireSingleOutInventory([candidate, candidate], 'R10000212016'),
        throwsStateError);
    expect(() => requireSingleOutInventory([candidate], 'OTHER'),
        throwsStateError);
    expect(
        () => requireSingleOutInventory(
            [inventory('R10000212016', 'STORAGE')], 'R10000212016'),
        throwsStateError);
  });

  test('rejects records without an id or a verified location', () {
    final missingId = inventory('R10000212016', 'out')..id = null;
    final missingLocation = inventory('R10000212016', 'out')..location = null;
    expect(() => requireSingleOutInventory([missingId], 'R10000212016'),
        throwsStateError);
    expect(() => requireSingleOutInventory([missingLocation], 'R10000212016'),
        throwsStateError);
  });
}
