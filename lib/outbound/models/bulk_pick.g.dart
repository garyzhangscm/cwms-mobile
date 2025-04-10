// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bulk_pick.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BulkPick _$BulkPickFromJson(Map<String, dynamic> json) {
  return BulkPick()
    ..id = json['id'] as int
    ..number = json['number']
    ..waveNumber = json['waveNumber']
    ..sourceLocationId = json['sourceLocationId']
    ..sourceLocation = json['sourceLocation'] == null
        ? null
        : WarehouseLocation.fromJson(json['sourceLocation'] as Map<String, dynamic>)
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..quantity = json['quantity']
    ..pickedQuantity = json['pickedQuantity']
    ..inventoryStatus = json['inventoryStatus'] == null
        ? null
        : InventoryStatus.fromJson(json['inventoryStatus'] as Map<String, dynamic>)
    ..warehouseId = json['warehouseId']
    ..confirmItemFlag = json['confirmItemFlag']
    ..confirmLocationFlag = json['confirmLocationFlag']
    ..confirmLocationCodeFlag = json['confirmLocationCodeFlag']
    ..confirmLpnFlag = json['confirmLpnFlag']
    ..color = json['color']
    ..productSize = json['productSize']
    ..style = json['style']  ;
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
