import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

import 'item.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'cycle_count_result.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class CycleCountResult{
  CycleCountResult();

  int id;
  String batchId;
  int locationId;
  WarehouseLocation location;
  int warehouseId;
  Warehouse warehouse;

  Item item;
  int quantity;
  int countQuantity;
  // flag used by the client only.
  // set to true when adding new item
  // during the count
  bool unexpectedItem;

  //不同的类使用不同的mixin即可
  factory CycleCountResult.fromJson(Map<String, dynamic> json) => _$CycleCountResultFromJson(json);
  Map<String, dynamic> toJson() => _$CycleCountResultToJson(this);




}