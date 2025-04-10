// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkOrder _$WorkOrderFromJson(Map<String, dynamic> json) {
  return WorkOrder()
    ..id = json['id'] as int
    ..number = json['number']
    ..itemId = json['itemId']
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..warehouseId = json['warehouseId']
    ..warehouse = json['warehouse'] == null
        ? null
        : Warehouse.fromJson(json['warehouse'] as Map<String, dynamic>)
    ..workOrderLines = json['workOrderLines'] == null ?
        [] :
        (json['workOrderLines'] as List)
        .map(
            (e) => WorkOrderLine.fromJson(e as Map<String, dynamic>))
        .toList()
    ..productionLineAssignments = json['productionLineAssignments'] == null ?
        [] : (json['productionLineAssignments'] as List)
        .map(
            (e) =>  ProductionLineAssignment.fromJson(e as Map<String, dynamic>))
        .toList()
    ..status =  json['status'] == null
        ? null
        : EnumToString.fromString(WorkOrderStatus.values, json['status'] as String)
    ..expectedQuantity = json['expectedQuantity']
    ..producedQuantity = json['producedQuantity']
    ..totalLineExpectedQuantity = json['totalLineExpectedQuantity']
    ..totalLineOpenQuantity = json['totalLineOpenQuantity']
    ..totalLineInprocessQuantity = json['totalLineInprocessQuantity']
    ..totalLineDeliveredQuantity = json['totalLineDeliveredQuantity']
    ..totalLineConsumedQuantity = json['totalLineConsumedQuantity']
    ..materialConsumeTiming = json['materialConsumeTiming'] == null ? null : materialConsumeTimingFromString(json['materialConsumeTiming'] as String)
    ..consumeByBomOnly = json['consumeByBomOnly']
    ..consumeByBom = json['consumeByBom'] == null
        ? null
        : BillOfMaterial.fromJson(json['consumeByBom'] as Map<String, dynamic>);
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
  'totalLineExpectedQuantity': instance.totalLineExpectedQuantity,
  'totalLineOpenQuantity': instance.totalLineOpenQuantity,
  'totalLineInprocessQuantity': instance.totalLineInprocessQuantity,
  'totalLineDeliveredQuantity': instance.totalLineDeliveredQuantity,
  'totalLineConsumedQuantity': instance.totalLineConsumedQuantity,
  'materialConsumeTiming': instance.materialConsumeTiming == null ? null : EnumToString.convertToString(instance.materialConsumeTiming),
  'consumeByBomOnly': instance.consumeByBomOnly,
  'consumeByBom': instance.consumeByBom,
  'productionLineAssignments': instance.productionLineAssignments,
};
