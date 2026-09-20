

import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/workorder/models/production_line_assignment.dart';
import 'package:json_annotation/json_annotation.dart';



part 'work_order_qc_sample.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class WorkOrderQCSample{
  WorkOrderQCSample();
  WorkOrderQCSample.fromProductionLineAssignment(ProductionLineAssignment productionLineAssignment) {
    this.productionLineAssignment = productionLineAssignment;
    this.warehouseId = Global.currentWarehouse!.id;
    this.number = "";
    this.imageUrls = "";
  }

  int? id;
  String? number;
  int? warehouseId;
  ProductionLineAssignment? productionLineAssignment;

  String? imageUrls;



  //不同的类使用不同的mixin即可
  factory WorkOrderQCSample.fromJson(Map<String, dynamic> json) => _$WorkOrderQCSampleFromJson(json);
  Map<String, dynamic> toJson() => _$WorkOrderQCSampleToJson(this);





}