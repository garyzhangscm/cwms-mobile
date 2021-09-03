// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Inventory _$InventoryFromJson(Map<String, dynamic> json) {
  return Inventory()
    ..id = json['id'] as int
    ..lpn = json['lpn'] as String
    ..locationId = json['locationId'] as int
    ..virtual = json['virtual'] as bool
    ..location = json['location'] == null
        ? null
        : WarehouseLocation.fromJson(json['location'] as Map<String, dynamic>)
    ..pickId = json['pickId'] as int
    ..pick = json['pick'] == null
        ? null
        : Pick.fromJson(json['pick'] as Map<String, dynamic>)
    ..receiptId = json['receiptId'] as int
    ..receiptLineId = json['receiptLineId'] as int
    ..workOrderId = json['workOrderId'] as int
    ..workOrderLineId = json['workOrderLineId'] as int
    ..workOrderByProductId = json['workOrderByProductId'] as int
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..itemPackageType = json['itemPackageType'] == null
        ? null
        : ItemPackageType.fromJson(json['itemPackageType'] as Map<String, dynamic>)
    ..inventoryStatus = json['inventoryStatus'] == null
        ? null
        : InventoryStatus.fromJson(json['inventoryStatus'] as Map<String, dynamic>)
    ..quantity = json['quantity'] as int
    ..inventoryMovements = (json['inventoryMovements'] as List)
        ?.map(
            (e) => e == null ? null : InventoryMovement.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..warehouseId = json['warehouseId'] as int;
}

Map<String, dynamic> _$InventoryToJson(Inventory instance) => <String, dynamic>{
      'id': instance.id,
      'lpn': instance.lpn,
      'locationId': instance.locationId,
      'location': instance.location,
      'virtual': instance.virtual,
      'pickId': instance.pickId,
      'pick': instance.pick,
      'receiptId': instance.receiptId,
      'receiptLineId': instance.receiptLineId,
      'workOrderId': instance.workOrderId,
      'workOrderLineId': instance.workOrderLineId,
      'workOrderByProductId': instance.workOrderByProductId,
      'item': instance.item,
      'itemPackageType': instance.itemPackageType,
      'inventoryStatus': instance.inventoryStatus,
      'quantity': instance.quantity,
      'warehouse': instance.warehouse,
      'warehouseId': instance.warehouseId,
      'inventoryMovements': instance.inventoryMovements
    };
