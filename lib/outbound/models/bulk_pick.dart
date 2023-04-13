import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bulk_pick.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class BulkPick{
  BulkPick();

  int id;
  String number;
  String waveNumber;

  int sourceLocationId;
  WarehouseLocation sourceLocation;

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
  String color;
  String productSize;
  String style;






  //不同的类使用不同的mixin即可
  factory BulkPick.fromJson(Map<String, dynamic> json) => _$BulkPickFromJson(json);
  Map<String, dynamic> toJson() => _$BulkPickToJson(this);





}