// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_of_material.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************


BillOfMaterial _$BillOfMaterialFromJson(Map<String, dynamic> json) {
  return BillOfMaterial()
    ..id = json['id'] as int
    ..number = json['number'] as String
    ..description = json['description'] as String
    ..billOfMaterialLines = (json['billOfMaterialLines'] as List)
        .map(
            (e) =>   BillOfMaterialLine.fromJson(e as Map<String, dynamic>))
        .toList()
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..itemId = json['itemId'] as int
    ..expectedQuantity = json['expectedQuantity'] as double
    ..warehouse = json['warehouse'] == null
        ? null
        : Warehouse.fromJson(json['warehouse'] as Map<String, dynamic>)
    ..warehouseId = json['warehouseId'] as int;
}

Map<String, dynamic> _$BillOfMaterialToJson(BillOfMaterial instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'description': instance.description,
  'billOfMaterialLines': instance.billOfMaterialLines,
  'item': instance.item,
  'itemId': instance.itemId,
  'expectedQuantity': instance.expectedQuantity,
  'warehouseId': instance.warehouseId,
  'warehouse': instance.warehouse,
};
