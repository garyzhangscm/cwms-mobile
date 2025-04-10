// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationGroup _$LocationGroupFromJson(Map<String, dynamic> json) {
  return LocationGroup()
    ..id = json['id'] as int
    ..name = json['name']
    ..description = json['description']
    ..warehouse = json['warehouse'] == null
        ? null
        : Warehouse.fromJson(json['warehouse'] as Map<String, dynamic>)
    ..pickable = json['pickable']
    ..storable = json['storable']
    ..countable = json['countable']
    ..adjustable = json['adjustable']
    ..trackingVolume = json['trackingVolume']
    ..locationGroupType = json['locationGroupType'] == null
        ? null
        : LocationGroupType.fromJson(json['locationGroupType'] as Map<String, dynamic>);
}

Map<String, dynamic> _$LocationGroupToJson(LocationGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'warehouse': instance.warehouse,
      'pickable': instance.pickable,
      'storable': instance.storable,
      'countable': instance.countable,
      'adjustable': instance.adjustable,
      'trackingVolume': instance.trackingVolume,
      'locationGroupType': instance.locationGroupType,
    };
