// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkOrderLine _$WorkOrderLineFromJson(Map<String, dynamic> json) {
  return WorkOrderLine()
    ..id = json['id'] as int
    ..number = json['number'] as String
    ..itemId = json['itemId'] as int
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..expectedQuantity = json['expectedQuantity'] as int
    ..openQuantity = json['openQuantity'] as int
    ..inprocessQuantity = json['inprocessQuantity'] as int
    ..deliveredQuantity = json['deliveredQuantity'] as int
    ..consumedQuantity = json['consumedQuantity'] as int
    ..scrappedQuantity = json['scrappedQuantity'] as int
    ..returnedQuantity = json['returnedQuantity'] as int
    ..inventoryStatusId = json['inventoryStatusId'] as int
    ..inventoryStatus = json['inventoryStatus'] == null
        ? null
        : InventoryStatus.fromJson(json['inventoryStatus'] as Map<String, dynamic>);
}

Map<String, dynamic> _$WorkOrderLineToJson(WorkOrderLine instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'item': instance.item,
  'itemId': instance.itemId,
  'expectedQuantity': instance.expectedQuantity,
  'openQuantity': instance.openQuantity,
  'inprocessQuantity': instance.inprocessQuantity,
  'deliveredQuantity': instance.deliveredQuantity,
  'consumedQuantity': instance.consumedQuantity,
  'scrappedQuantity': instance.scrappedQuantity,
  'returnedQuantity': instance.returnedQuantity,
  'inventoryStatusId': instance.inventoryStatusId,
  'inventoryStatus': instance.inventoryStatus,
};
