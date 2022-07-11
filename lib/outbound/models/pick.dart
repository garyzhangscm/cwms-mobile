import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pick.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class Pick{
  Pick();

  int id;
  String number;
  int sourceLocationId;
  WarehouseLocation sourceLocation;
  WarehouseLocation destinationLocation;
  Item item;
  int quantity;
  int pickedQuantity;
  int warehouseId;
  InventoryStatus inventoryStatus;
  bool confirmItemFlag;
  bool confirmLocationFlag;
  bool confirmLocationCodeFlag;
  bool confirmLpnFlag;

  int skipCount = 0;






  //不同的类使用不同的mixin即可
  factory Pick.fromJson(Map<String, dynamic> json) => _$PickFromJson(json);
  Map<String, dynamic> toJson() => _$PickToJson(this);





}