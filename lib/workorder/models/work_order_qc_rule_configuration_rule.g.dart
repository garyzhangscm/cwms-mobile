// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order_qc_rule_configuration_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkOrderQCRuleConfigurationRule _$WorkOrderQCRuleConfigurationRuleFromJson(Map<String, dynamic> json) {
  return WorkOrderQCRuleConfigurationRule()
    ..id = json['id'] as int
    ..qcRuleId = json['qcRuleId'] as int
    ..qcRule = json['qcRule'] == null
        ? null
        : QCRule.fromJson(json['qcRule'] as Map<String, dynamic>)
  ;
}

Map<String, dynamic> _$WorkOrderQCRuleConfigurationRuleToJson(WorkOrderQCRuleConfigurationRule instance) => <String, dynamic>{
  'id': instance.id,
  'qcRuleId': instance.qcRuleId,
  'qcRule': instance.qcRule,


};
