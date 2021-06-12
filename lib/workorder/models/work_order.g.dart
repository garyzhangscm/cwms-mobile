// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkOrder _$WorkOrderFromJson(Map<String, dynamic> json) {
  return WorkOrder()
    ..id = json['id'] as int
    ..number = json['number'] as String
    ..itemId = json['itemId'] as int
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..warehouseId = json['warehouseId'] as int
    ..warehouse = json['warehouse'] == null
        ? null
        : Warehouse.fromJson(json['warehouse'] as Map<String, dynamic>)
    ..workOrderLines = (json['workOrderLines'] as List)
        ?.map(
            (e) => e == null ? null : WorkOrderLine.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..status =  EnumToString.fromString(WorkOrderStatus.values, json['status'] as String)
    ..expectedQuantity = json['expectedQuantity'] as int
    ..producedQuantity = json['producedQuantity'] as int
    ..totalLineCount = json['totalLineCount'] as int
    ..totalItemCount = json['totalItemCount'] as int
    ..totalExpectedQuantity = json['totalExpectedQuantity'] as int
    ..totalOpenQuantity = json['totalOpenQuantity'] as int
    ..totalOpenPickQuantity = json['totalOpenPickQuantity'] as int
    ..totalPickedQuantity = json['totalPickedQuantity'] as int;
}

Map<String, dynamic> _$WorkOrderToJson(WorkOrder instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'itemId': instance.itemId,
  'item': instance.item,
  'warehouseId': instance.warehouseId,
  'warehouse': instance.warehouse,
  'status': EnumToString.convertToString(instance.status),
  'workOrderLines': instance.workOrderLines,
  'expectedQuantity': instance.expectedQuantity,
  'producedQuantity': instance.producedQuantity,
  'totalLineCount': instance.totalLineCount,
  'totalItemCount': instance.totalItemCount,
  'totalExpectedQuantity': instance.totalExpectedQuantity,
  'totalOpenQuantity': instance.totalOpenQuantity,
  'totalOpenPickQuantity': instance.totalOpenPickQuantity,
  'totalPickedQuantity': instance.totalPickedQuantity,
};
