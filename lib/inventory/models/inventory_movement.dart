import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

import 'inventory_status.dart';
import 'item_package_type.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'inventory_movement.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class InventoryMovement{
  InventoryMovement();

  int id;



  int locationId;
  WarehouseLocation location;

  int sequence;

  int warehouseId;
  Warehouse warehouse;






  //不同的类使用不同的mixin即可
  factory InventoryMovement.fromJson(Map<String, dynamic> json) => _$InventoryMovementFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryMovementToJson(this);




}