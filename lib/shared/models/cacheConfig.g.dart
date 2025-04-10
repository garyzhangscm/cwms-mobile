// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cacheConfig.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CacheConfig _$CacheConfigFromJson(Map<String, dynamic> json) {
  return CacheConfig()
    ..enable = json['enable']
    ..maxAge = json['maxAge']
    ..maxCount = json['maxCount']  ;
}

Map<String, dynamic> _$CacheConfigToJson(CacheConfig instance) =>
    <String, dynamic>{
      'enable': instance.enable,
      'maxAge': instance.maxAge,
      'maxCount': instance.maxCount
    };
