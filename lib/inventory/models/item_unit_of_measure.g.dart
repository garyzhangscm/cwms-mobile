// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_unit_of_measure.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemUnitOfMeasure _$ItemUnitOfMeasureFromJson(Map<String, dynamic> json) {
  return ItemUnitOfMeasure()
    ..id = json['id'] as int
    ..unitOfMeasureId = json['unitOfMeasureId'] as int
    ..unitOfMeasure = json['unitOfMeasure'] == null
        ? null
        : UnitOfMeasure.fromJson(json['unitOfMeasure'] as Map<String, dynamic>)
    ..quantity = json['quantity'] as int
    ..weight = json['weight'] as double
    ..length = json['length'] as double
    ..width = json['width'] as double
    ..height = json['height'] as double
    ..warehouseId = json['warehouseId'] as int;
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
