// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_movement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryMovement _$InventoryMovementFromJson(Map<String, dynamic> json) {
  return InventoryMovement()
    ..id = json['id'] as int
    ..locationId = json['locationId'] as int
    ..sequence = json['sequence'] as int
    ..location = json['location'] == null
        ? null
        : WarehouseLocation.fromJson(json['location'] as Map<String, dynamic>)
    ..warehouseId = json['warehouseId'] as int;
}

Map<String, dynamic> _$InventoryMovementToJson(InventoryMovement instance) => <String, dynamic>{
      'id': instance.id,
      'locationId': instance.locationId,
      'location': instance.location,
      'sequence': instance.sequence,
      'warehouse': instance.warehouse,
      'warehouseId': instance.warehouseId,
    };
