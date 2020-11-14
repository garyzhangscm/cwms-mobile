// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warehouse_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WarehouseLocation _$WarehouseLocationFromJson(Map<String, dynamic> json) {
  return WarehouseLocation()
    ..id = json['id'] as int
    ..name = json['name'] as String
    ..aisle = json['aisle'] as String
    ..x = (json['x'] as num)?.toDouble()
    ..y = (json['y'] as num)?.toDouble()
    ..z = (json['z'] as num)?.toDouble()
    ..length = (json['length'] as num)?.toDouble()
    ..width = (json['width'] as num)?.toDouble()
    ..height = (json['height'] as num)?.toDouble()
    ..pickSequence = json['pickSequence'] as int
    ..putawaySequence = json['putawaySequence'] as int
    ..countSequence = json['countSequence'] as int
    ..capacity = (json['capacity'] as num)?.toDouble()
    ..fillPercentage = (json['fillPercentage'] as num)?.toDouble()
    ..currentVolume = (json['currentVolume'] as num)?.toDouble()
    ..pendingVolume = (json['pendingVolume'] as num)?.toDouble()
    ..locationGroup = json['locationGroup'] == null
        ? null
        : LocationGroup.fromJson(json['locationGroup'] as Map<String, dynamic>)
    ..enabled = json['enabled'] as bool
    ..locked = json['locked'] as bool
    ..reservedCode = json['reservedCode'] as String;
}

Map<String, dynamic> _$WarehouseLocationToJson(WarehouseLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'aisle': instance.aisle,
      'x': instance.x,
      'y': instance.y,
      'z': instance.z,
      'length': instance.length,
      'width': instance.width,
      'height': instance.height,
      'pickSequence': instance.pickSequence,
      'putawaySequence': instance.putawaySequence,
      'countSequence': instance.countSequence,
      'capacity': instance.capacity,
      'fillPercentage': instance.fillPercentage,
      'currentVolume': instance.currentVolume,
      'pendingVolume': instance.pendingVolume,
      'locationGroup': instance.locationGroup,
      'enabled': instance.enabled,
      'locked': instance.locked,
      'reservedCode': instance.reservedCode,
    };
