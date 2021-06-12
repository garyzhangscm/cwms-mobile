// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order_line_consume_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkOrderLineConsumeTransaction _$WorkOrderLineConsumeTransactionFromJson(Map<String, dynamic> json) {
  return WorkOrderLineConsumeTransaction()
    ..id = json['id'] as int
    ..workOrderLine = json['workOrderLine'] == null
        ? null
        : WorkOrderLine.fromJson(json['workOrderLine'] as Map<String, dynamic>)
    ..consumedQuantity = json['consumedQuantity'] as int;
}

Map<String, dynamic> _$WorkOrderLineConsumeTransactionToJson(WorkOrderLineConsumeTransaction instance) => <String, dynamic>{
  'id': instance.id,
  'workOrderLine': instance.workOrderLine,
  'consumedQuantity': instance.consumedQuantity,
};
