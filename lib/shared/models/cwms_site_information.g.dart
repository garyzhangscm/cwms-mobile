// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cwms_site_information.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CWMSSiteInformation _$CWMSSiteInformationFromJson(Map<String, dynamic> json) {
  return CWMSSiteInformation()
    ..url = json['url'] as String
    ..autoConnectFlag = json['autoConnectFlag'] as bool
    ..singleCompanySite = json['singleCompanySite'] as bool
    ..defaultCompanyCode = json['defaultCompanyCode'] as String
    ..cwmsApplicationInformation = json['app'] == null
        ? null
        : CWMSApplicationInformation.fromJson(json['app'] as Map<String, dynamic>);
}

Map<String, dynamic> _$CWMSSiteInformationToJson(CWMSSiteInformation instance) =>
    <String, dynamic>{
      'url': instance.url,
      'autoConnectFlag': instance.autoConnectFlag,
      'singleCompanySite': instance.singleCompanySite,
      'defaultCompanyCode': instance.defaultCompanyCode,
      'cwmsApplicationInformation': instance.cwmsApplicationInformation
    };
