// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_count_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditCountRequest _$AuditCountRequestFromJson(Map<String, dynamic> json) {
  return AuditCountRequest()
    ..id = json['id'] as int
    ..batchId = json['batchId']
    ..skippedCount = json['skippedCount'] == null ? 0 : json['skippedCount'] as int
    ..locationId = json['locationId']
    ..location = json['location'] == null
        ? null
        : WarehouseLocation.fromJson(json['location'] as Map<String, dynamic>)
    ..warehouseId = json['warehouseId']
    ..warehouse = json['warehouse'] == null
        ? null
        : Warehouse.fromJson(json['warehouse'] as Map<String, dynamic>);
}

Map<String, dynamic> _$AuditCountRequestToJson(AuditCountRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'batchId': instance.batchId,
      'locationId': instance.locationId,
      'location': instance.location,
      'warehouseId': instance.warehouseId,
      'warehouse': instance.warehouse,
    };
