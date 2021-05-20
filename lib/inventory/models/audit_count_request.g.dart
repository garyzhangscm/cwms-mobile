// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_count_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditCountRequest _$AuditCountRequestFromJson(Map<String, dynamic> json) {
  return AuditCountRequest()
    ..id = json['id'] as int
    ..batchId = json['batchId'] as String
    ..locationId = json['locationId'] as int
    ..location = json['location'] == null
        ? null
        : WarehouseLocation.fromJson(json['location'] as Map<String, dynamic>)
    ..warehouseId = json['warehouseId'] as int
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
