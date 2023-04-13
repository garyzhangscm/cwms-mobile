// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bulk_pick.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BulkPick _$BulkPickFromJson(Map<String, dynamic> json) {
  return BulkPick()
    ..id = json['id'] as int
    ..number = json['number'] as String
    ..waveNumber = json['waveNumber'] as String
    ..sourceLocationId = json['sourceLocationId'] as int
    ..sourceLocation = json['sourceLocation'] == null
        ? null
        : WarehouseLocation.fromJson(json['sourceLocation'] as Map<String, dynamic>)
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..quantity = json['quantity'] as int
    ..pickedQuantity = json['pickedQuantity'] as int
    ..inventoryStatus = json['inventoryStatus'] == null
        ? null
        : InventoryStatus.fromJson(json['inventoryStatus'] as Map<String, dynamic>)
    ..warehouseId = json['warehouseId'] as int
    ..confirmItemFlag = json['confirmItemFlag'] as bool
    ..confirmLocationFlag = json['confirmLocationFlag'] as bool
    ..confirmLocationCodeFlag = json['confirmLocationCodeFlag'] as bool
    ..confirmLpnFlag = json['confirmLpnFlag'] as bool
    ..color = json['color'] as String
    ..productSize = json['productSize'] as String
    ..style = json['style'] as String;
}

Map<String, dynamic> _$BulkPickToJson(BulkPick instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'waveNumber': instance.waveNumber,
  'sourceLocationId': instance.sourceLocationId,
  'sourceLocation': instance.sourceLocation,
  'item': instance.item,
  'quantity': instance.quantity,
  'pickedQuantity': instance.pickedQuantity,
  'warehouseId': instance.warehouseId,
  'confirmItemFlag': instance.confirmItemFlag,
  'confirmLocationFlag': instance.confirmLocationFlag,
  'confirmLocationCodeFlag': instance.confirmLocationCodeFlag,
  'confirmLpnFlag': instance.confirmLpnFlag,
  'inventoryStatus': instance.inventoryStatus,
  'color': instance.color,
  'productSize': instance.productSize,
  'style': instance.style,
};
