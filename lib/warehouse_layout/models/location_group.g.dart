// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationGroup _$LocationGroupFromJson(Map<String, dynamic> json) {
  return LocationGroup()
    ..id = json['id'] as int
    ..name = json['name'] as String
    ..description = json['description'] as String
    ..warehouse = json['warehouse'] == null
        ? null
        : Warehouse.fromJson(json['warehouse'] as Map<String, dynamic>)
    ..pickable = json['pickable'] as bool
    ..storable = json['storable'] as bool
    ..countable = json['countable'] as bool
    ..adjustable = json['adjustable'] as bool
    ..trackingVolume = json['trackingVolume'] as bool;
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
    };
