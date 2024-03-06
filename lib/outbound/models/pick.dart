import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/work/models/work_task.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pick.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class Pick{
  Pick();

  Pick.clone(Pick anotherPick) {
    // this.id = anotherPick.id;
    this.number = anotherPick.number;
    this.sourceLocationId = anotherPick.sourceLocationId;
    this.sourceLocation = anotherPick.sourceLocation;
    this.destinationLocationId = anotherPick.destinationLocationId;
    this.destinationLocation = anotherPick.destinationLocation;
    this.itemId = anotherPick.itemId;
    this.item = anotherPick.item;
    this.quantity = anotherPick.quantity;
    this.pickedQuantity = anotherPick.pickedQuantity;
    this.warehouseId = anotherPick.warehouseId;
    this.inventoryStatusId = anotherPick.inventoryStatusId;
    this.inventoryStatus = anotherPick.inventoryStatus;
    this.confirmItemFlag = anotherPick.confirmItemFlag;
    this.confirmLocationFlag = anotherPick.confirmLocationFlag;
    this.confirmLocationCodeFlag = anotherPick.confirmLocationCodeFlag;
    this.confirmLpnFlag = anotherPick.confirmLpnFlag;
    this.color = anotherPick.color;
    this.productSize = anotherPick.productSize;
    this.style = anotherPick.style;
    this.allocateByReceiptNumber = anotherPick.allocateByReceiptNumber;
  }

  int id;
  String number;
  int sourceLocationId;
  WarehouseLocation sourceLocation;
  int destinationLocationId;
  WarehouseLocation destinationLocation;
  int itemId;
  Item item;
  int quantity;
  int batchPickQuantity;     // used by the client only when we want to batch pick from the same location.
  List<Pick> batchedPicks;   // picks from same location with same item and inventory attribute that can be complete together
  int pickedQuantity;
  int warehouseId;
  int inventoryStatusId;
  InventoryStatus inventoryStatus;
  bool confirmItemFlag;
  bool confirmLocationFlag;
  bool confirmLocationCodeFlag;
  bool confirmLpnFlag;
  bool wholeLPNPick;

  int skipCount = 0;

  int workTaskId;
  WorkTask workTask;

  String color;
  String productSize;
  String style;
  String allocateByReceiptNumber;

  //不同的类使用不同的mixin即可
  factory Pick.fromJson(Map<String, dynamic> json) => _$PickFromJson(json);
  Map<String, dynamic> toJson() => _$PickToJson(this);





}