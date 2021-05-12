import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

import 'inventory_movement.dart';
import 'inventory_status.dart';
import 'item.dart';
import 'item_package_type.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'inventory.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class Inventory{
  Inventory();

  int id;
  String lpn;

  int locationId;
  WarehouseLocation location;

  // if the inventory is picked, then
  // those 2 fields has the pick information
  int pickId;
  Pick pick;

  // setup when the inventory is received from
  // receipt or work order
  int receiptId;
  int receiptLineId;
  int workOrderId;
  int workOrderLineId;
  int workOrderByProductId;

  Item item;
  ItemPackageType itemPackageType;
  InventoryStatus inventoryStatus;

  int quantity;

  int warehouseId;
  Warehouse warehouse;

  List<InventoryMovement> inventoryMovements;


  WarehouseLocation getNextDepositLocaiton() {
    if (inventoryMovements == null || inventoryMovements.isEmpty) {
      return null;
    }


      inventoryMovements.sort((a, b) => a.sequence.compareTo(
          b.sequence
      ));
      return inventoryMovements[0].location;

  }



  //不同的类使用不同的mixin即可
  factory Inventory.fromJson(Map<String, dynamic> json) => _$InventoryFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryToJson(this);




}