// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cwms_site_information.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CWMSSiteInformation _$CWMSSiteInformationFromJson(Map<String, dynamic> json) {
  return CWMSSiteInformation()
    ..url = json['url'] ?? ""
    ..autoConnectFlag = json['autoConnectFlag'] ?? false
    ..singleCompanySite = json['singleCompanySite']  ?? false
    ..defaultCompanyCode = json['defaultCompanyCode'] ?? ""
    ..rfAppVersion = json['rfAppVersion'] ?? ""
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
      'rfAppVersion': instance.rfAppVersion,
      'cwmsApplicationInformation': instance.cwmsApplicationInformation
    };
