// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order_labor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************


WorkOrderLabor _$WorkOrderLaborFromJson(Map<String, dynamic> json) {
  return WorkOrderLabor()
    ..id = json['id'] as int
    ..warehouseId = json['warehouseId']
    ..username = json['username']
    ..productionLine = json['productionLine'] == null
        ? null
        : ProductionLine.fromJson(json['productionLine'] as Map<String, dynamic>)
    ..lastCheckInTime = json['lastCheckInTime'] == null
        ? null
        : DateTime.parse(json['lastCheckInTime'] as String)
    ..lastCheckOutTime = json['lastCheckOutTime'] == null
        ? null
        : DateTime.parse(json['lastCheckOutTime'] as String)
    ..workOrderLaborStatus =  EnumToString.fromString(WorkOrderLaborStatus.values, json['workOrderLaborStatus'] as String);
}

Map<String, dynamic> _$WorkOrderLaborToJson(WorkOrderLabor instance) => <String, dynamic>{
  'id': instance.id,
  'warehouseId': instance.warehouseId,
  'username': instance.username,
  'productionLine': instance.productionLine,
  'lastCheckInTime': instance.lastCheckInTime,
  'lastCheckOutTime': instance.lastCheckOutTime,
  'workOrderLaborStatus': instance.workOrderLaborStatus,
};
