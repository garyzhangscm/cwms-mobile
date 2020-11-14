// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cwms_server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CWMSServer _$CWMSServerFromJson(Map<String, dynamic> json) {
  return CWMSServer()
    ..url = json['url'] as String
    ..autoConnectFlag = json['autoConnectFlag'] as bool
    ..name = json['name'] as String
    ..description = json['description'] as String
    ..version = json['version'] as String;
}

Map<String, dynamic> _$CWMSServerToJson(CWMSServer instance) =>
    <String, dynamic>{
      'url': instance.url,
      'autoConnectFlag': instance.autoConnectFlag,
      'name': instance.name,
      'description': instance.description,
      'version': instance.version,
    };
