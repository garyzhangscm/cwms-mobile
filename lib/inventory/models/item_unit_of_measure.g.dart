// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_unit_of_measure.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemUnitOfMeasure _$ItemUnitOfMeasureFromJson(Map<String, dynamic> json) {
  return ItemUnitOfMeasure()
    ..id = json['id'] as int
    ..unitOfMeasureId = json['unitOfMeasureId']
    ..unitOfMeasure = json['unitOfMeasure'] == null
        ? null
        : UnitOfMeasure.fromJson(json['unitOfMeasure'] as Map<String, dynamic>)
    ..quantity = json['quantity']
    ..weight = json['weight']
    ..length = json['length']
    ..width = json['width']
    ..height = json['height']
    ..warehouseId = json['warehouseId'] ;
}

Map<String, dynamic> _$ItemUnitOfMeasureToJson(ItemUnitOfMeasure instance) => <String, dynamic>{
      'id': instance.id,
      'unitOfMeasureId': instance.unitOfMeasureId,
      'unitOfMeasure': instance.unitOfMeasure,
      'quantity': instance.quantity,
      'weight': instance.weight,
      'length': instance.length,
      'width': instance.width,
      'height': instance.height,
      'warehouse': instance.warehouse,
      'warehouseId': instance.warehouseId,
    };
