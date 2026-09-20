

import 'package:cwms_mobile/inventory/models/qc_rule.dart';
import 'package:json_annotation/json_annotation.dart';



part 'work_order_qc_rule_configuration_rule.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class WorkOrderQCRuleConfigurationRule{
  WorkOrderQCRuleConfigurationRule();

  int? id;
  int? qcRuleId;
  QCRule? qcRule;



  //不同的类使用不同的mixin即可
  factory WorkOrderQCRuleConfigurationRule.fromJson(Map<String, dynamic> json) => _$WorkOrderQCRuleConfigurationRuleFromJson(json);
  Map<String, dynamic> toJson() => _$WorkOrderQCRuleConfigurationRuleToJson(this);





}