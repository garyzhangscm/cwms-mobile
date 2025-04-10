// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_count_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuditCountResult _$AuditCountResultFromJson(Map<String, dynamic> json) {
  return AuditCountResult()
    ..id = json['id'] as int
    ..batchId = json['batchId']
    ..location = json['location'] == null
        ? null
        : WarehouseLocation.fromJson(json['location'] as Map<String, dynamic>)
    ..inventory = json['inventory'] == null
        ? null
        : Inventory.fromJson(json['inventory'] as Map<String, dynamic>)
    ..lpn = json['lpn']
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..warehouseId = json['warehouseId']
    ..warehouse = json['warehouse'] == null
        ? null
        : Warehouse.fromJson(json['warehouse'] as Map<String, dynamic>)
    ..quantity = json['quantity']
    ..countQuantity = json['countQuantity']  ;
}

Map<String, dynamic> _$AuditCountResultToJson(AuditCountResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'batchId': instance.batchId,
      'location': instance.location,
      'warehouseId': instance.warehouseId,
      'warehouse': instance.warehouse,
      'item': instance.item,
      'lpn': instance.lpn,
      'inventory': instance.inventory,
      'quantity': instance.quantity,
      'countQuantity': instance.countQuantity,
    };
