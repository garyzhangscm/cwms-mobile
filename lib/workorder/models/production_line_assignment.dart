

import 'package:cwms_mobile/common/models/carrier.dart';
import 'package:cwms_mobile/common/models/carrier_service_level.dart';
import 'package:cwms_mobile/common/models/customer.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_line.dart';
import 'package:json_annotation/json_annotation.dart';


part 'production_line_assignment.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class ProductionLineAssignment{
  ProductionLineAssignment();

  int? id;

  ProductionLine? productionLine;
  WorkOrder? workOrder;
  int? workOrderId;
  String? workOrderNumber;



  //不同的类使用不同的mixin即可
  factory ProductionLineAssignment.fromJson(Map<String, dynamic> json) => _$ProductionLineAssignmentFromJson(json);
  Map<String, dynamic> toJson() => _$ProductionLineAssignmentToJson(this);





}