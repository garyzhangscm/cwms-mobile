

import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

import 'inventory.dart';



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
    newLpn = "";

    nextLocation = null;
    nextLocationId = null;
    nextLocationName = "";
    multipleNextLocationFlag = false;

    currentLocationName = "";

    itemName = "";
    itemDescription = "";

    multipleItemFlag = false;

    inventoryStatusName = "";
    inventoryStatusDescription = "";
    multipleInventoryStatusFlag = false;

    quantity = 0;
    inventoryIdList = {};

    requestInProcess = false;
    requestResult = false;
    result = "";
  }


  InventoryDepositRequest.fromInventory(Inventory inventory) {
    lpn = inventory.lpn;
    newLpn = inventory.lpn;
    if (inventory.inventoryMovements != null &&
        inventory.inventoryMovements.isNotEmpty) {
      nextLocation = inventory.inventoryMovements[0].location;
      nextLocationName = nextLocation!.name;
      nextLocationId = nextLocation!.id;
    }
    else {

      nextLocation = null;
      nextLocationName = "";
      nextLocationId = null;
    }
    multipleNextLocationFlag = false;


    currentLocationName = inventory.location?.name;

    itemName = inventory.item!.name;
    itemDescription = inventory.item!.description;

    multipleItemFlag = false;

    inventoryStatusName = inventory.inventoryStatus!.name;
    inventoryStatusDescription = inventory.inventoryStatus!.description;
    multipleInventoryStatusFlag = false;

    quantity = inventory.quantity;


    inventoryIdList = {};
    inventoryIdList.add(inventory.id!);


    requestInProcess = false;
    requestResult = false;
    result = "";

  }

  // add a inventory to the existing deposit request
  // we will assume the new inventory has the same LPN and next hop
  addInventory(Inventory inventory) {
    if (itemName != inventory.item!.name) {
      itemName = "==MIXED ITEM==";
      itemDescription = "==MIXED ITEM==";
      multipleItemFlag = true;
    }
    if (inventoryStatusName != inventory.inventoryStatus!.name) {
      inventoryStatusName = "==MIXED STATUS==";
      inventoryStatusDescription = "==MIXED STATUS==";
      multipleInventoryStatusFlag = true;
    }


    // see if we have multiple locations

    int? newInventoryNextLocationId;
    if (inventory.inventoryMovements != null &&
        inventory.inventoryMovements.isNotEmpty) {
      newInventoryNextLocationId = nextLocation!.id;
    }
    if (newInventoryNextLocationId != nextLocationId) {

      nextLocationName = "==MIXED Destination==";
      multipleNextLocationFlag = true;
      nextLocationId = null;
      nextLocation = null;
    }
    if (currentLocationName != inventory.location?.name) {

      nextLocationName = "==MIXED Location==";
    }

    quantity = quantity! + inventory.quantity!;
    inventoryIdList.add(inventory.id!);



  }

  String? lpn;
  String? newLpn;

  int? nextLocationId;
  WarehouseLocation? nextLocation;
  String? nextLocationName;
  bool? multipleNextLocationFlag;

  String? currentLocationName;

  String? itemName;
  String? itemDescription;
  bool? multipleItemFlag;

  String? inventoryStatusName;
  String? inventoryStatusDescription;
  bool? multipleInventoryStatusFlag;

  int? quantity;

  Set<int> inventoryIdList = new Set();

  bool? requestInProcess;
  bool? requestResult;
  String? result;




}