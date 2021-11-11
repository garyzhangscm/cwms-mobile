// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rf_app_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RFAppVersion _$RFAppVersionFromJson(Map<String, dynamic> json) {
  return RFAppVersion()
    ..id = json['id'] as int
    ..versionNumber = json['versionNumber'] as String
    ..fileName = json['fileName'] as String
    ..fileSize = json['fileSize'] as int
    ..isLatestVersion = json['latestVersion'] as bool
    ..companyId = json['companyId'] as int
    ..releaseNote = json['releaseNote'] as String
    ..releaseDate = json['releaseDate'] == null ? null:
        DateTime.parse(json['releaseDate']) ;
}

Map<String, dynamic> _$RFAppVersionToJson(RFAppVersion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'versionNumber': instance.versionNumber,
      'fileName': instance.fileName,
      'fileSize': instance.fileSize,
      'isLatestVersion': instance.isLatestVersion,
      'companyId': instance.companyId,
      'releaseNote': instance.releaseNote,
      'releaseDate': instance.releaseDate
    };
