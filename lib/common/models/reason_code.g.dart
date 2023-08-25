// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reason_code.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReasonCode _$ReasonCodeFromJson(Map<String, dynamic> json) {
  return ReasonCode()
    ..id = json['id'] as int
    ..name = json['name'] as String
    ..description = json['description'] as String
    ..type =  json['type'] == null
        ? null
        : EnumToString.fromString(ReasonCodeType.values, json['type'] as String);
}

Map<String, dynamic> _$ReasonCodeToJson(ReasonCode instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'type': instance.type
};
