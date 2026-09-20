

import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_sample.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:json_annotation/json_annotation.dart';



part 'work_order_qc_result.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class WorkOrderQCResult{
  WorkOrderQCResult();

  int? id;
  String? number;
  int? warehouseId;
  WorkOrderQCSample? workOrderQCSample;
  QCInspectionResult? qcInspectionResult;
  String? qcUsername;
  String? qcRFCode;



  //不同的类使用不同的mixin即可
  factory WorkOrderQCResult.fromJson(Map<String, dynamic> json) => _$WorkOrderQCResultFromJson(json);
  Map<String, dynamic> toJson() => _$WorkOrderQCResultToJson(this);





}