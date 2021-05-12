import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

import 'inventory.dart';
import 'inventory_movement.dart';
import 'inventory_status.dart';
import 'item.dart';
import 'item_package_type.dart';



///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

// Inventory Deposit Request
// when we have multiple LPN / Items
// that needs to be deposit into the same location, we
// can group them together in the same deposit request
// Currently we will only group items in the same LPN,
// but not multiple LPNs
class InventoryDepositRequest{
  InventoryDepositRequest() {

    lpn = "";

    nextLocation = null;
    nextLocationId = -1;

    itemName = "";
    itemDescription = "";

    multipleItemFlag = false;

    inventoryStatusName = "";
    inventoryStatusDescription = "";
    multipleInventoryStatusFlag = false;

    quantity = 0;
    inventoryIdList = new List<int>();
  }


  InventoryDepositRequest.fromInventory(Inventory inventory) {
    lpn = inventory.lpn;
    if (inventory.inventoryMovements != null &&
        inventory.inventoryMovements.isNotEmpty) {
      nextLocation = inventory.inventoryMovements[0].location;
      nextLocationId = nextLocation.id;
    }
    itemName = inventory.item.name;
    itemDescription = inventory.item.description;

    multipleItemFlag = false;

    inventoryStatusName = inventory.inventoryStatus.name;
    inventoryStatusDescription = inventory.inventoryStatus.description;
    multipleInventoryStatusFlag = false;

    quantity = inventory.quantity;


    inventoryIdList = new List<int>();
    inventoryIdList.add(inventory.id);

  }

  // add a inventory to the existing deposit request
  // we will assume the new inventory has the same LPN and next hop
  addInventory(Inventory inventory) {
    if (itemName != inventory.item.name) {
      itemName = "==MIXED ITEM==";
      itemDescription = "==MIXED ITEM==";
      multipleItemFlag = true;
    }
    if (inventoryStatusName != inventory.inventoryStatus.name) {
      inventoryStatusName = "==MIXED STATUS==";
      inventoryStatusDescription = "==MIXED STATUS==";
      multipleInventoryStatusFlag = true;
    }

    quantity += inventory.quantity;
    inventoryIdList.add(inventory.id);



  }

  String lpn;

  int nextLocationId;
  WarehouseLocation nextLocation;

  String itemName;
  String itemDescription;
  bool multipleItemFlag;

  String inventoryStatusName;
  String inventoryStatusDescription;
  bool multipleInventoryStatusFlag;

  int quantity;

  List<int> inventoryIdList;




}