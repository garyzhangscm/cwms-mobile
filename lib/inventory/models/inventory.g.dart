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
    ..receipt = json['receipt'] == null
        ? null
        : Receipt.fromJson(json['receipt'] as Map<String, dynamic>)
    ..receiptLineId = json['receiptLineId'] as int
    ..receiptLine = json['receiptLine'] == null
        ? null
        : ReceiptLine.fromJson(json['receiptLine'] as Map<String, dynamic>)
    ..workOrderId = json['workOrderId'] as int
    ..workOrder = json['workOrder'] == null
        ? null
        : WorkOrder.fromJson(json['workOrder'] as Map<String, dynamic>)
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
    ..warehouseId = json['warehouseId'] as int
    ..clientId = json['clientId'] as int
    ..inboundQCRequired = json['inboundQCRequired'] == null
        ? false : json['inboundQCRequired'] as bool;
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
      'workOrder': instance.workOrder,
      'workOrderLineId': instance.workOrderLineId,
      'workOrderByProductId': instance.workOrderByProductId,
      'item': instance.item,
      'clientId': instance.clientId,
      'client': instance.client,
      'itemPackageType': instance.itemPackageType,
      'inventoryStatus': instance.inventoryStatus,
      'quantity': instance.quantity,
      'warehouse': instance.warehouse,
      'warehouseId': instance.warehouseId,
      'inventoryMovements': instance.inventoryMovements,
      'inboundQCRequired': instance.inboundQCRequired
    };
