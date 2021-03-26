// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryStatus _$InventoryStatusFromJson(Map<String, dynamic> json) {
  return InventoryStatus()
    ..id = json['id'] as int
    ..name = json['name'] as String
    ..description = json['description'] as String
    ..warehouseId = json['warehouseId'] as int;
}

Map<String, dynamic> _$InventoryStatusToJson(InventoryStatus instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'warehouseId': instance.warehouseId,
};
