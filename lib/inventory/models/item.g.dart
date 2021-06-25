// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Item _$ItemFromJson(Map<String, dynamic> json) {
  return Item()
    ..id = json['id'] as int
    ..name = json['name'] as String
    ..description = json['description'] as String
    ..warehouseId = json['warehouseId'] as int
    ..clientId = json['clientId'] as int
    ..itemPackageTypes = (json['itemPackageTypes'] as List)
        ?.map(
          (e) => e == null ? null : ItemPackageType.fromJson(e as Map<String, dynamic>))
              ?.toList();
    /**
    ..client = json['client'] == null
        ? null
        : Client.fromJson(json['client'] as Map<String, dynamic>)

        **/
}

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'warehouseId': instance.warehouseId,
      'clientId': instance.clientId,
      'client': instance.client,
      'itemPackageTypes': instance.itemPackageTypes,
    };
