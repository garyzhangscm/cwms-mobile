// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_sampling.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemSampling _$ItemSamplingFromJson(Map<String, dynamic> json) {
  return ItemSampling()
    ..id = json['id'] as int
    ..number = json['number'] as String
    ..description = json['description'] as String
    ..warehouseId = json['warehouseId'] as int
    ..imageUrls = json['imageUrls'] as String
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..enabled = json['enabled'] == null
        ? false : json['enabled'] as bool;
}

Map<String, dynamic> _$ItemSamplingToJson(ItemSampling instance) => <String, dynamic>{
      'id': instance.id,
      'number': instance.number,
      'description': instance.description,
      'warehouseId': instance.warehouseId,
      'imageUrls': instance.imageUrls,
      'item': instance.item,
      'enabled': instance.enabled,
    };
