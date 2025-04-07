
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';

import 'package:json_annotation/json_annotation.dart';

part 'work_order_line.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class WorkOrderLine{
  WorkOrderLine();

  int? id;
  String? number;

  Item? item;
  int? itemId;

  int? expectedQuantity;
  int? openQuantity;
  int? inprocessQuantity;
  int? deliveredQuantity;
  int? consumedQuantity;
  int? scrappedQuantity;
  int? returnedQuantity;

  int? inventoryStatusId;
  InventoryStatus? inventoryStatus;






  //不同的类使用不同的mixin即可
  factory WorkOrderLine.fromJson(Map<String, dynamic> json) => _$WorkOrderLineFromJson(json);
  Map<String, dynamic> toJson() => _$WorkOrderLineToJson(this);





}