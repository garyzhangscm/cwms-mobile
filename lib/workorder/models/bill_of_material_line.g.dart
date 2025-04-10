// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_of_material_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BillOfMaterialLine _$BillOfMaterialLineFromJson(Map<String, dynamic> json) {
  return BillOfMaterialLine()
    ..id = json['id'] as int
    ..number = json['number']
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..itemId = json['itemId']
    ..expectedQuantity = json['expectedQuantity']
    ..inventoryStatus = json['inventoryStatus'] == null
        ? null
        : InventoryStatus.fromJson(json['item'] as Map<String, dynamic>)
    ..inventoryStatusId = json['inventoryStatusId'] ;
}

Map<String, dynamic> _$BillOfMaterialLineToJson(BillOfMaterialLine instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'item': instance.item,
  'itemId': instance.itemId,
  'expectedQuantity': instance.expectedQuantity,
  'inventoryStatusId': instance.inventoryStatusId,
  'inventoryStatus': instance.inventoryStatus,
};
