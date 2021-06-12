// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order_produced_inventory.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkOrderProducedInventory _$WorkOrderProducedInventoryFromJson(Map<String, dynamic> json) {
  return WorkOrderProducedInventory()
    ..id = json['id'] as int
    ..lpn = json['lpn'] as String
    ..quantity = json['quantity'] as int
    ..inventoryStatusId = json['inventoryStatusId'] as int
    ..inventoryStatus = json['inventoryStatus'] == null
        ? null
        : InventoryStatus.fromJson(json['inventoryStatus'] as Map<String, dynamic>)
    ..itemPackageTypeId = json['itemPackageTypeId'] as int
    ..itemPackageType = json['itemPackageType'] == null
        ? null
        : ItemPackageType.fromJson(json['itemPackageType'] as Map<String, dynamic>);
}

Map<String, dynamic> _$WorkOrderProducedInventoryToJson(WorkOrderProducedInventory instance) => <String, dynamic>{
  'id': instance.id,
  'lpn': instance.lpn,
  'quantity': instance.quantity,
  'inventoryStatusId': instance.inventoryStatusId,
  'inventoryStatus': instance.inventoryStatus,
  'itemPackageTypeId': instance.itemPackageTypeId,
  'itemPackageType': instance.itemPackageType,
};
