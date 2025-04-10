// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_count_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CycleCountResult _$CycleCountResultFromJson(Map<String, dynamic> json) {
  return CycleCountResult()
    ..id = json['id'] as int
    ..batchId = json['batchId']
    ..locationId = json['locationId']
    ..location = json['location'] == null
        ? null
        : WarehouseLocation.fromJson(json['location'] as Map<String, dynamic>)
    ..warehouseId = json['warehouseId']
    ..warehouse = json['warehouse'] == null
        ? null
        : Warehouse.fromJson(json['warehouse'] as Map<String, dynamic>)
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..quantity = json['quantity']
    ..countQuantity = json['countQuantity']  ;
}

Map<String, dynamic> _$CycleCountResultToJson(CycleCountResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'batchId': instance.batchId,
      'location': instance.location,
      'locationId': instance.locationId,
      'warehouseId': instance.warehouseId,
      'warehouse': instance.warehouse,
      'item': instance.item,
      'quantity': instance.quantity,
      'countQuantity': instance.countQuantity,
    };
