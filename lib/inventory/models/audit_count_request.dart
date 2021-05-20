import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

import 'item.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'audit_count_request.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class AuditCountRequest{
  AuditCountRequest();

  int id;
  String batchId;

  int locationId;
  WarehouseLocation location;

  int warehouseId;
  Warehouse warehouse;


  //不同的类使用不同的mixin即可
  factory AuditCountRequest.fromJson(Map<String, dynamic> json) => _$AuditCountRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AuditCountRequestToJson(this);




}