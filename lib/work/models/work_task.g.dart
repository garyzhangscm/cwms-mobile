// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkTask _$WorkTaskFromJson(Map<String, dynamic> json) {
  return WorkTask()
    ..id = json['id'] as int
    ..number = json['number']
    ..type = json['type'] == null ? null : workTaskTypeFromString(json['type'] as String)
    ..status = json['status'] == null ? null : workTaskStatusFromString(json['status'] as String)
    ..priority = json['priority']
    ..sourceLocationId = json['sourceLocationId']
    ..sourceLocation = json['sourceLocation'] == null
        ? null
        : WarehouseLocation.fromJson(json['sourceLocation'] as Map<String, dynamic>)
    ..destinationLocationId = json['destinationLocationId']
    ..destinationLocation = json['destinationLocation'] == null
        ? null
        : WarehouseLocation.fromJson(json['destinationLocation'] as Map<String, dynamic>)
    ..referenceNumber = json['referenceNumber']
    ..operationType = json['operationType'] == null
        ? null
        : OperationType.fromJson(json['operationType'] as Map<String, dynamic>);
}

Map<String, dynamic> _$WorkTaskToJson(WorkTask instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'type': instance.type,
  'status': instance.status,
  'priority': instance.priority,
  'sourceLocationId': instance.sourceLocationId,
  'sourceLocation': instance.sourceLocation,
  'destinationLocationId': instance.destinationLocationId,
  'destinationLocation': instance.destinationLocation,
  'referenceNumber': instance.referenceNumber,
  'operationType': instance.operationType,
};
