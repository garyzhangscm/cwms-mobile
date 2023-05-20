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
    ..productionLineAssignments = (json['productionLineAssignments'] as List)
        ?.map(
            (e) => e == null ? null : ProductionLineAssignment.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..status =  json['status'] == null
        ? null
        : EnumToString.fromString(WorkOrderStatus.values, json['status'] as String)
    ..expectedQuantity = json['expectedQuantity'] as int
    ..producedQuantity = json['producedQuantity'] as int
    ..totalLineExpectedQuantity = json['totalLineExpectedQuantity'] as int
    ..totalLineOpenQuantity = json['totalLineOpenQuantity'] as int
    ..totalLineInprocessQuantity = json['totalLineInprocessQuantity'] as int
    ..totalLineDeliveredQuantity = json['totalLineDeliveredQuantity'] as int
    ..totalLineConsumedQuantity = json['totalLineConsumedQuantity'] as int
    ..materialConsumeTiming = json['materialConsumeTiming'] == null ? null : materialConsumeTimingFromString(json['materialConsumeTiming'] as String)
    ..consumeByBomOnly = json['consumeByBomOnly'] as bool
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
