// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pick.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pick _$PickFromJson(Map<String, dynamic> json) {
  return Pick()
    ..id = json['id'] as int
    ..number = json['number'] as String
    ..sourceLocation = json['sourceLocation'] == null
        ? null
        : WarehouseLocation.fromJson(json['sourceLocation'] as Map<String, dynamic>)
    ..destinationLocation = json['destinationLocation'] == null
        ? null
        : WarehouseLocation.fromJson(json['destinationLocation'] as Map<String, dynamic>)
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..quantity = json['quantity'] as int
    ..pickedQuantity = json['pickedQuantity'] as int
    ..warehouseId = json['warehouseId'] as int
    ..confirmItemFlag = json['confirmItemFlag'] as bool
    ..confirmLocationFlag = json['confirmLocationFlag'] as bool
    ..confirmLocationCodeFlag = json['confirmLocationCodeFlag'] as bool
    ..inventoryStatus = json['inventoryStatus'] == null
        ? null
        : InventoryStatus.fromJson(json['inventoryStatus'] as Map<String, dynamic>);
}

Map<String, dynamic> _$PickToJson(Pick instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'sourceLocation': instance.sourceLocation,
  'destinationLocation': instance.destinationLocation,
  'item': instance.item,
  'quantity': instance.quantity,
  'pickedQuantity': instance.pickedQuantity,
  'warehouseId': instance.warehouseId,
  'confirmItemFlag': instance.confirmItemFlag,
  'confirmLocationFlag': instance.confirmLocationFlag,
  'confirmLocationCodeFlag': instance.confirmLocationCodeFlag,
  'inventoryStatus': instance.inventoryStatus,
};
