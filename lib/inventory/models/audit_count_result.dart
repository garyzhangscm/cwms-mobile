import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

import 'item.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'audit_count_result.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class AuditCountResult{
  AuditCountResult();

  int id;
  String batchId;
  WarehouseLocation location;
  Inventory inventory;
  String lpn;
  Item item;
  int quantity;
  int countQuantity;
  int warehouseId;
  Warehouse warehouse;


  //不同的类使用不同的mixin即可
  factory AuditCountResult.fromJson(Map<String, dynamic> json) => _$AuditCountResultFromJson(json);
  Map<String, dynamic> toJson() => _$AuditCountResultToJson(this);




}