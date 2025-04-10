// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_group_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationGroupType _$LocationGroupTypeFromJson(Map<String, dynamic> json) {
  return LocationGroupType()
    ..id = json['id'] as int
    ..name = json['name']
    ..description = json['description']
    ..fourWallInventory = json['fourWallInventory']
    ..virtual = json['virtual']
    ..receivingStage = json['receivingStage']
    ..shippingStage = json['shippingStage']
    ..productionLine = json['productionLine']
    ..productionLineInbound = json['productionLineInbound']
    ..productionLineOutbound = json['productionLineOutbound']
    ..dock = json['dock']
    ..yard = json['yard']
    ..storage = json['storage']
    ..pickupAndDeposit = json['pickupAndDeposit']
    ..trailer = json['trailer']
    ..qcArea = json['qcArea']  ;
}

Map<String, dynamic> _$LocationGroupTypeToJson(LocationGroupType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'fourWallInventory': instance.fourWallInventory,
      'virtual': instance.virtual,
      'receivingStage': instance.receivingStage,
      'shippingStage': instance.shippingStage,
      'productionLine': instance.productionLine,
      'productionLineInbound': instance.productionLineInbound,
      'productionLineOutbound': instance.productionLineOutbound,
      'dock': instance.dock,
      'yard': instance.yard,
      'storage': instance.storage,
      'pickupAndDeposit': instance.pickupAndDeposit,
      'trailer': instance.trailer,
      'qcArea': instance.qcArea,
    };
