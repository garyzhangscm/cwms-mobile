// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order_qc_sample.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkOrderQCSample _$WorkOrderQCSampleFromJson(Map<String, dynamic> json) {
  return WorkOrderQCSample()
    ..id = json['id'] as int
    ..number = json['number'] as String
    ..warehouseId = json['warehouseId'] as int
    ..productionLineAssignment = json['productionLineAssignment'] == null
        ? null
        : ProductionLineAssignment.fromJson(json['productionLineAssignment'] as Map<String, dynamic>)
    ..imageUrls = json['imageUrls'] as String
  ;
}

Map<String, dynamic> _$WorkOrderQCSampleToJson(WorkOrderQCSample instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'warehouseId': instance.warehouseId,
  'productionLineAssignment': instance.productionLineAssignment,
  'imageUrls': instance.imageUrls,

};
