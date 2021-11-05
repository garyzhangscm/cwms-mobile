

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

import 'cwms_application_information.dart';

// server.g.dart 将在我们运行生成命令后自动生成
part 'cwms_site_information.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class CWMSSiteInformation {
  CWMSSiteInformation();

  // must be in the format of
  // http://xxx.xxx.xxx:port/
  // which stands for the root of
  // all web service call
  String url;

  // only default server can be 'auto connect'
  bool autoConnectFlag;

  bool singleCompanySite;
  String defaultCompanyCode;
  String rfAppVersion;
  String rfAppName;

  CWMSApplicationInformation cwmsApplicationInformation;




  //不同的类使用不同的mixin即可
  factory CWMSSiteInformation.fromJson(Map<String, dynamic> json) => _$CWMSSiteInformationFromJson(json);
  Map<String, dynamic> toJson() => _$CWMSSiteInformationToJson(this);

  static String encodeServers(List<CWMSSiteInformation> servers) => json.encode(
    servers
        .map<Map<String, dynamic>>((server) => server.toJson())
        .toList(),
  );

  static List<CWMSSiteInformation> decodeServers(String servers) =>
      (json.decode(servers) as List<dynamic>)
          .map<CWMSSiteInformation>((item) => CWMSSiteInformation.fromJson(item))
          .toList();


  bool isAutoConnect() {

    return autoConnectFlag;
  }

  CWMSApplicationInformation getCWMSApplicationInformation() {
    return cwmsApplicationInformation;
  }

  String getDefaultCompanyCode() {
    return defaultCompanyCode;
  }
  bool isSingleCompanySite() {

    return singleCompanySite;
  }

}
