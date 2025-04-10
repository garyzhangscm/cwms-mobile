// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order_qc_rule_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkOrderQCRuleConfiguration _$WorkOrderQCRuleConfigurationFromJson(Map<String, dynamic> json) {
  return WorkOrderQCRuleConfiguration()
    ..id = json['id'] as int
    ..warehouseId = json['warehouseId']
    ..qcQuantity = json['qcQuantity']
    ..productionLine = json['productionLine'] == null
        ? null
        : ProductionLine.fromJson(json['productionLine'] as Map<String, dynamic>)
    ..workOrder = json['workOrder'] == null
        ? null
        : WorkOrder.fromJson(json['workOrder'] as Map<String, dynamic>)
    ..workOrderQCRuleConfigurationRules = json['workOrderQCRuleConfigurationRules'] == null ?
        [] : (json['workOrderQCRuleConfigurationRules'] as List)
        .map(
            (e) => WorkOrderQCRuleConfigurationRule.fromJson(e as Map<String, dynamic>))
        .toList()
  ;
}

Map<String, dynamic> _$WorkOrderQCRuleConfigurationToJson(WorkOrderQCRuleConfiguration instance) => <String, dynamic>{
  'id': instance.id,
  'warehouseId': instance.warehouseId,
  'qcQuantity': instance.qcQuantity,
  'productionLine': instance.productionLine,
  'workOrder': instance.workOrder,
  'workOrderQCRuleConfigurationRules': instance.workOrderQCRuleConfigurationRules,


};
