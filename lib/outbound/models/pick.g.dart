// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pick.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pick _$PickFromJson(Map<String, dynamic> json) {
  return Pick()
    ..id = json['id'] as int
    ..number = json['number'] as String
    ..sourceLocationId = json['sourceLocationId'] as int
    ..sourceLocation = json['sourceLocation'] == null
        ? null
        : WarehouseLocation.fromJson(json['sourceLocation'] as Map<String, dynamic>)
    ..destinationLocationId = json['destinationLocationId'] as int
    ..destinationLocation = json['destinationLocation'] == null
        ? null
        : WarehouseLocation.fromJson(json['destinationLocation'] as Map<String, dynamic>)
    ..itemId = json['itemId'] as int
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..workTaskId = json['workTaskId'] == null
        ? null
        : json['workTaskId'] as int
    ..workTask = json['workTask'] == null
        ? null
        : WorkTask.fromJson(json['workTask'] as Map<String, dynamic>)
    ..quantity = json['quantity'] as int
    ..pickedQuantity = json['pickedQuantity'] as int
    ..warehouseId = json['warehouseId'] as int
    ..confirmItemFlag = json['confirmItemFlag'] as bool
    ..confirmLocationFlag = json['confirmLocationFlag'] as bool
    ..confirmLocationCodeFlag = json['confirmLocationCodeFlag'] as bool
    ..confirmLpnFlag = json['confirmLpnFlag'] as bool
    ..color = json['color'] as String
    ..productSize = json['productSize'] as String
    ..style = json['style'] as String
    ..wholeLPNPick = json['wholeLPNPick'] as bool
    ..allocateByReceiptNumber = json['allocateByReceiptNumber'] as String
    ..inventoryStatusId = json['inventoryStatusId'] as int
    ..inventoryStatus = json['inventoryStatus'] == null
        ? null
        : InventoryStatus.fromJson(json['inventoryStatus'] as Map<String, dynamic>);
}

Map<String, dynamic> _$PickToJson(Pick instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'sourceLocationId': instance.sourceLocationId,
  'sourceLocation': instance.sourceLocation,
  'destinationLocationId': instance.destinationLocationId,
  'destinationLocation': instance.destinationLocation,
  'itemId': instance.itemId,
  'item': instance.item,
  'quantity': instance.quantity,
  'pickedQuantity': instance.pickedQuantity,
  'warehouseId': instance.warehouseId,
  'confirmItemFlag': instance.confirmItemFlag,
  'confirmLocationFlag': instance.confirmLocationFlag,
  'confirmLocationCodeFlag': instance.confirmLocationCodeFlag,
  'confirmLpnFlag': instance.confirmLpnFlag,
  'wholeLPNPick': instance.wholeLPNPick,
  'color': instance.color,
  'productSize': instance.productSize,
  'style': instance.style,
  'allocateByReceiptNumber': instance.allocateByReceiptNumber,
  'inventoryStatusId': instance.inventoryStatusId,
  'inventoryStatus': instance.inventoryStatus,
};
