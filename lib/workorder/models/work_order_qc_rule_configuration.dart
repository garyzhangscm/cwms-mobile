

import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_rule_configuration_rule.dart';
import 'package:json_annotation/json_annotation.dart';



part 'work_order_qc_rule_configuration.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class WorkOrderQCRuleConfiguration{
  WorkOrderQCRuleConfiguration();

  int? id;
  int? warehouseId;
  ProductionLine? productionLine;
  WorkOrder? workOrder;
  List<WorkOrderQCRuleConfigurationRule> workOrderQCRuleConfigurationRules = [];
  int? qcQuantity;



  //不同的类使用不同的mixin即可
  factory WorkOrderQCRuleConfiguration.fromJson(Map<String, dynamic> json) => _$WorkOrderQCRuleConfigurationFromJson(json);
  Map<String, dynamic> toJson() => _$WorkOrderQCRuleConfigurationToJson(this);





}