// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pick.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pick _$PickFromJson(Map<String, dynamic> json) {
  return Pick()
    ..id = json['id'] as int
    ..number = json['number']
    ..sourceLocationId = json['sourceLocationId']
    ..sourceLocation = json['sourceLocation'] == null
        ? null
        : WarehouseLocation.fromJson(json['sourceLocation'] as Map<String, dynamic>)
    ..destinationLocationId = json['destinationLocationId']
    ..destinationLocation = json['destinationLocation'] == null
        ? null
        : WarehouseLocation.fromJson(json['destinationLocation'] as Map<String, dynamic>)
    ..itemId = json['itemId']
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..workTaskId = json['workTaskId'] == null
        ? null
        : json['workTaskId']
    ..workTask = json['workTask'] == null
        ? null
        : WorkTask.fromJson(json['workTask'] as Map<String, dynamic>)
    ..quantity = json['quantity']
    ..pickedQuantity = json['pickedQuantity']
    ..warehouseId = json['warehouseId']
    ..confirmItemFlag = json['confirmItemFlag']
    ..confirmLocationFlag = json['confirmLocationFlag']
    ..confirmLocationCodeFlag = json['confirmLocationCodeFlag']
    ..confirmLpnFlag = json['confirmLpnFlag']
    ..color = json['color']
    ..productSize = json['productSize']
    ..style = json['style']
    ..inventoryAttribute1 = json['inventoryAttribute1']
    ..inventoryAttribute2 = json['inventoryAttribute2']
    ..inventoryAttribute3 = json['inventoryAttribute3']
    ..inventoryAttribute4 = json['inventoryAttribute4']
    ..inventoryAttribute5 = json['inventoryAttribute5']
    ..wholeLPNPick = json['wholeLPNPick']
    ..allocateByReceiptNumber = json['allocateByReceiptNumber']
    ..inventoryStatusId = json['inventoryStatusId']
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
  'inventoryAttribute1': instance.inventoryAttribute1,
  'inventoryAttribute2': instance.inventoryAttribute2,
  'inventoryAttribute3': instance.inventoryAttribute3,
  'inventoryAttribute4': instance.inventoryAttribute4,
  'inventoryAttribute5': instance.inventoryAttribute5,
  'allocateByReceiptNumber': instance.allocateByReceiptNumber,
  'inventoryStatusId': instance.inventoryStatusId,
  'inventoryStatus': instance.inventoryStatus,
};
