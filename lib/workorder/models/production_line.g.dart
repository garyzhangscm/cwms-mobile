// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductionLine _$ProductionLineFromJson(Map<String, dynamic> json) {
  return ProductionLine()
    ..id = json['id'] as int
    ..name = json['name']
    ..inboundStageLocationId = json['inboundStageLocationId']
    ..inboundStageLocation = json['inboundStageLocation'] == null
        ? null
        : WarehouseLocation.fromJson(json['inboundStageLocation'] as Map<String, dynamic>)
    ..outboundStageLocationId = json['outboundStageLocationId']
    ..outboundStageLocation = json['outboundStageLocation'] == null
        ? null
        : WarehouseLocation.fromJson(json['outboundStageLocation'] as Map<String, dynamic>)
    ..productionLineLocationId = json['productionLineLocationId']
    ..productionLineLocation = json['productionLineLocation'] == null
        ? null
        : WarehouseLocation.fromJson(json['productionLineLocation'] as Map<String, dynamic>);
}

Map<String, dynamic> _$ProductionLineToJson(ProductionLine instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'inboundStageLocationId': instance.inboundStageLocationId,
  'inboundStageLocation': instance.inboundStageLocation,
  'outboundStageLocationId': instance.outboundStageLocationId,
  'outboundStageLocation': instance.outboundStageLocation,
  'productionLineLocationId': instance.productionLineLocationId,
  'productionLineLocation': instance.productionLineLocation,
};
