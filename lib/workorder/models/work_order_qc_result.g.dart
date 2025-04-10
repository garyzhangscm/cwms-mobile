// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order_qc_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkOrderQCResult _$WorkOrderQCResultFromJson(Map<String, dynamic> json) {
  return WorkOrderQCResult()
    ..id = json['id'] as int
    ..number = json['number']
    ..warehouseId = json['warehouseId']
    ..workOrderQCSample = json['workOrderQCSample'] == null
        ? null
        : WorkOrderQCSample.fromJson(json['workOrderQCSample'] as Map<String, dynamic>)
    ..qcInspectionResult = json['qcInspectionResult'] == null
        ? null : EnumToString.fromString(QCInspectionResult.values, json['qcInspectionResult'] as String)
    ..qcUsername = json['qcUsername']
  ;
}

Map<String, dynamic> _$WorkOrderQCResultToJson(WorkOrderQCResult instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'warehouseId': instance.warehouseId,
  'workOrderQCSample': instance.workOrderQCSample,
  'qcInspectionResult': EnumToString.convertToString(instance.qcInspectionResult),
  'qcUsername': instance.qcUsername,
  'qcRFCode': instance.qcRFCode,

};
