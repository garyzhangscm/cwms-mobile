// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qc_inspection_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QCInspectionRequest _$QCInspectionRequestFromJson(Map<String, dynamic> json) {
  return QCInspectionRequest()
    ..id = json['id'] as int
    ..warehouseId = json['warehouseId'] as int
    ..qcQuantity = json['qcQuantity'] as int
    ..number = json['number'] as String
    ..inventory = json['inventory'] == null
        ? null
        : Inventory.fromJson(json['inventory'] as Map<String, dynamic>)
    ..workOrderQCSampleId = json['workOrderQCSampleId'] as int
    ..qcInspectionResult = json['qcInspectionResult'] == null
        ? null : EnumToString.fromString(QCInspectionResult.values, json['qcInspectionResult'] as String)
    ..qcUsername = json['qcUsername'] as String
    ..qcTime = json['qcTime'] == null
        ? null
        : DateTime.parse(json['qcTime'] as String)
    ..qcInspectionRequestItems = (json['qcInspectionRequestItems'] as List)
        ?.map(
            (e) => e == null ? null : QCInspectionRequestItem.fromJson(e as Map<String, dynamic>))
        ?.toList();
}

Map<String, dynamic> _$QCInspectionRequestToJson(QCInspectionRequest instance) => <String, dynamic>{
      'id': instance.id,
      'warehouseId': instance.warehouseId,
      'number': instance.number,
      'inventory': instance.inventory,
  'qcQuantity': instance.qcQuantity,
      'workOrderQCSampleId': instance.workOrderQCSampleId,
      'qcInspectionResult': EnumToString.convertToString(instance.qcInspectionResult),
      'qcUsername': instance.qcUsername,
      'qcTime': instance.qcTime,
      'qcInspectionRequestItems': instance.qcInspectionRequestItems,
    };
