// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_family.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemFamily _$ItemFamilyFromJson(Map<String, dynamic> json) {
  return ItemFamily()
    ..id = json['id'] as int
    ..name = json['name']
    ..description = json['description']
    ..warehouseId = json['warehouseId']
    ..companyId = json['companyId'] ;

}

Map<String, dynamic> _$ItemFamilyToJson(ItemFamily instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'warehouseId': instance.warehouseId,
      'companyId': instance.companyId,
    };
