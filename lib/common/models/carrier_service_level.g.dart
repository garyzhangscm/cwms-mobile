// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carrier_service_level.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarrierServiceLevel _$CarrierServiceLevelFromJson(Map<String, dynamic> json) {
  return CarrierServiceLevel()
    ..id = json['id'] as int
    ..name = json['name'] as String
    ..description = json['description'] as String
    ..type = json['type'] as String;
}

Map<String, dynamic> _$CarrierServiceLevelToJson(CarrierServiceLevel instance)
=> <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'type': instance.type,
};
