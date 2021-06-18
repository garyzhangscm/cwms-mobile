// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order_produce_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkOrderProduceTransaction _$WorkOrderProduceTransactionFromJson(Map<String, dynamic> json) {
  return WorkOrderProduceTransaction()
    ..workOrder = json['workOrder'] == null
        ? null
        : WorkOrder.fromJson(json['workOrdr'] as Map<String, dynamic>)
    ..workOrderLineConsumeTransactions = (json['workOrderLineConsumeTransactions'] as List)
        ?.map(
            (e) => e == null ? null : WorkOrderLineConsumeTransaction.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..workOrderProducedInventories = (json['workOrderProducedInventories'] as List)
        ?.map(
            (e) => e == null ? null : WorkOrderProducedInventory.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..workOrderKPITransactions = (json['workOrderKPITransactions'] as List)
        ?.map(
            (e) => e == null ? null : WorkOrderKPITransaction.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..consumeByBomQuantity = json['consumeByBomQuantity'] as bool
    ..productionLine = json['productionLine'] == null
        ? null
        : ProductionLine.fromJson(json['productionLine'] as Map<String, dynamic>);
}

Map<String, dynamic> _$WorkOrderProduceTransactionToJson(WorkOrderProduceTransaction instance) => <String, dynamic>{
  'workOrder': instance.workOrder,
  'workOrderLineConsumeTransactions': instance.workOrderLineConsumeTransactions,
  'workOrderProducedInventories': instance.workOrderProducedInventories,
  'workOrderKPITransactions': instance.workOrderKPITransactions,
  'consumeByBomQuantity': instance.consumeByBomQuantity,
  'matchedBillOfMaterial': instance.matchedBillOfMaterial,
  'productionLine': instance.productionLine,
};
