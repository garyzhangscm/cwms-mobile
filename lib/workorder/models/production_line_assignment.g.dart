// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_line_assignment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductionLineAssignment _$ProductionLineAssignmentFromJson(Map<String, dynamic> json) {
  return ProductionLineAssignment()
    ..id = json['id'] as int
    ..productionLine = json['productionLine'] == null
        ? null
        : ProductionLine.fromJson(json['productionLine'] as Map<String, dynamic>)
    ..workOrder = json['workOrder'] == null
        ? null
        : WorkOrder.fromJson(json['workOrder'] as Map<String, dynamic>)
    ..workOrderId = json['workOrderId'] as int;
}

Map<String, dynamic> _$ProductionLineAssignmentToJson(ProductionLineAssignment instance) => <String, dynamic>{
  'id': instance.id,
  'productionLine': instance.productionLine,
  'workOrder': instance.workOrder,
  'workOrderId': instance.workOrderId,
};
