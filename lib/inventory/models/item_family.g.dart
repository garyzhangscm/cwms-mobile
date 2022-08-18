// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_family.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemFamily _$ItemFamilyFromJson(Map<String, dynamic> json) {
  return ItemFamily()
    ..id = json['id'] as int
    ..name = json['name'] as String
    ..description = json['description'] as String
    ..warehouseId = json['warehouseId'] as int
    ..companyId = json['companyId'] as int;

}

Map<String, dynamic> _$ItemFamilyToJson(ItemFamily instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'warehouseId': instance.warehouseId,
      'companyId': instance.companyId,
    };
