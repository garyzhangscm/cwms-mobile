// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rf_app_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RFAppVersion _$RFAppVersionFromJson(Map<String, dynamic> json) {
  return RFAppVersion()
    ..id = json['id'] as int
    ..versionNumber = json['versionNumber']
    ..fileName = json['fileName']
    ..fileSize = json['fileSize']
    ..isLatestVersion = json['latestVersion']
    ..companyId = json['companyId']
    ..releaseNote = json['releaseNote']
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
