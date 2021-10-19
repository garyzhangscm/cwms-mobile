

import 'package:cwms_mobile/common/models/carrier.dart';
import 'package:cwms_mobile/common/models/carrier_service_level.dart';
import 'package:cwms_mobile/common/models/customer.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/workorder/models/material-consume-timing.dart';
import 'package:cwms_mobile/workorder/models/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/models/work_order_line.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_sample.dart';
import 'package:cwms_mobile/workorder/models/work_order_status.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:json_annotation/json_annotation.dart';

import 'bill_of_material.dart';


part 'work_order_qc_result.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class WorkOrderQCResult{
  WorkOrderQCResult();

  int id;
  String number;
  int warehouseId;
  WorkOrderQCSample workOrderQCSample;
  QCInspectionResult qcInspectionResult;
  String qcUsername;
  String qcRFCode;



  //不同的类使用不同的mixin即可
  factory WorkOrderQCResult.fromJson(Map<String, dynamic> json) => _$WorkOrderQCResultFromJson(json);
  Map<String, dynamic> toJson() => _$WorkOrderQCResultToJson(this);





}