// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cwms_application_information.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CWMSApplicationInformation _$CWMSApplicationInformationFromJson(Map<String, dynamic> json) {
  return CWMSApplicationInformation()
    ..name = json['name'] as String
    ..description = json['description'] as String
    ..version = json['version'] as String;
}

Map<String, dynamic> _$CWMSApplicationInformationToJson(CWMSApplicationInformation instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'version': instance.version,
    };
