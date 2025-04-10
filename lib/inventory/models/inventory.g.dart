// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Inventory _$InventoryFromJson(Map<String, dynamic> json) {
  return Inventory()
    ..id = json['id'] as int
    ..lpn = json['lpn']
    ..locationId = json['locationId']
    ..locationName = json['locationName']
    ..virtual = json['virtual']
    ..color = json['color']
    ..productSize = json['productSize']
    ..style = json['style']
    ..attribute1 = json['attribute1']
    ..attribute2 = json['attribute2']
    ..attribute3 = json['attribute3']
    ..attribute4 = json['attribute4']
    ..attribute5 = json['attribute5']
    ..location = json['location'] == null
        ? null
        : WarehouseLocation.fromJson(json['location'] as Map<String, dynamic>)
    ..pickId = json['pickId']
    ..pick = json['pick'] == null
        ? null
        : Pick.fromJson(json['pick'] as Map<String, dynamic>)
    ..receiptId = json['receiptId']
    ..receipt = json['receipt'] == null
        ? null
        : Receipt.fromJson(json['receipt'] as Map<String, dynamic>)
    ..receiptNumber = json['receiptNumber']
    ..receiptLineId = json['receiptLineId']
    ..receiptLine = json['receiptLine'] == null
        ? null
        : ReceiptLine.fromJson(json['receiptLine'] as Map<String, dynamic>)
    ..workOrderId = json['workOrderId']
    ..workOrder = json['workOrder'] == null
        ? null
        : WorkOrder.fromJson(json['workOrder'] as Map<String, dynamic>)
    ..workOrderLineId = json['workOrderLineId']
    ..workOrderByProductId = json['workOrderByProductId']
    ..lastQCTime = json['lastQCTime'] == null
        ? null
        : DateTime.parse(json['lastQCTime'] as String)
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..itemPackageType = json['itemPackageType'] == null
        ? null
        : ItemPackageType.fromJson(json['itemPackageType'] as Map<String, dynamic>)
    ..inventoryStatus = json['inventoryStatus'] == null
        ? null
        : InventoryStatus.fromJson(json['inventoryStatus'] as Map<String, dynamic>)
    ..quantity = json['quantity']
    ..inventoryMovements = json['inventoryMovements'] == null
      ? [] :
        (json['inventoryMovements'] as List)
        .map(
            (e) => InventoryMovement.fromJson(e as Map<String, dynamic>))
        .toList()
    ..warehouseId = json['warehouseId']
    ..clientId = json['clientId']
    ..inboundQCRequired = json['inboundQCRequired'] == null
        ? false : json['inboundQCRequired'] as bool
    ..kitInventoryFlag = json['kitInventoryFlag'] == null
        ? false : json['kitInventoryFlag'] as bool
    ..kitInnerInventoryFlag = json['kitInnerInventoryFlag'] == null
        ? false : json['kitInnerInventoryFlag'] as bool
    ..kitInventory = json['kitInventory'] == null
        ? null
        : Inventory.fromJson(json['kitInventory'] as Map<String, dynamic>)
    ..kitInnerInventories = json['kitInnerInventories']  == null ?
        [] :
        (json['kitInnerInventories'] as List)
        .map(
            (e) =>  Inventory.fromJson(e as Map<String, dynamic>))
        .toList();
}

Map<String, dynamic> _$InventoryToJson(Inventory instance) => <String, dynamic>{
      'id': instance.id,
      'lpn': instance.lpn,
      'locationId': instance.locationId,
      'locationName': instance.locationName,
      'location': instance.location,
      'virtual': instance.virtual,
      'pickId': instance.pickId,
      'pick': instance.pick,
      'receiptId': instance.receiptId,
      'receiptNumber': instance.receiptNumber,
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
      'inboundQCRequired': instance.inboundQCRequired,
      'color': instance.color,
      'productSize;': instance.productSize,
      'style': instance.style,
      'lastQCTime': instance.lastQCTime,
      'attribute1': instance.attribute1,
      'attribute2': instance.attribute2,
      'attribute3': instance.attribute3,
      'attribute4': instance.attribute4,
      'attribute5': instance.attribute5,
      'kitInventoryFlag': instance.kitInventoryFlag,
      'kitInnerInventoryFlag': instance.kitInnerInventoryFlag,
      'kitInventory': instance.kitInventory,
      'kitInnerInventories': instance.kitInnerInventories

};
