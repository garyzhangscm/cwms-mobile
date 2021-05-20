// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_group_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationGroupType _$LocationGroupTypeFromJson(Map<String, dynamic> json) {
  return LocationGroupType()
    ..id = json['id'] as int
    ..name = json['name'] as String
    ..description = json['description'] as String
    ..fourWallInventory = json['fourWallInventory'] as bool
    ..virtual = json['virtual'] as bool
    ..receivingStage = json['receivingStage'] as bool
    ..shippingStage = json['shippingStage'] as bool
    ..productionLine = json['productionLine'] as bool
    ..productionLineInbound = json['productionLineInbound'] as bool
    ..productionLineOutbound = json['productionLineOutbound'] as bool
    ..dock = json['dock'] as bool
    ..yard = json['yard'] as bool
    ..storage = json['storage'] as bool
    ..pickupAndDeposit = json['pickupAndDeposit'] as bool
    ..trailer = json['trailer'] as bool;
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
    };
