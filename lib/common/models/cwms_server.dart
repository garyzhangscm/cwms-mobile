import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

// server.g.dart 将在我们运行生成命令后自动生成
part 'cwms_server.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class CWMSServer {
  CWMSServer();

  // must be in the format of
  // http://xxx.xxx.xxx:port/
  // which stands for the root of
  // all web service call
  String url;

  // only default server can be 'auto connect'
  bool autoConnectFlag;

  String name;
  String description;
  String version;



  //不同的类使用不同的mixin即可
  factory CWMSServer.fromJson(Map<String, dynamic> json) => _$CWMSServerFromJson(json);
  Map<String, dynamic> toJson() => _$CWMSServerToJson(this);

  static String encodeServers(List<CWMSServer> servers) => json.encode(
    servers
        .map<Map<String, dynamic>>((server) => server.toJson())
        .toList(),
  );

  static List<CWMSServer> decodeServers(String servers) =>
      (json.decode(servers) as List<dynamic>)
          .map<CWMSServer>((item) => CWMSServer.fromJson(item))
          .toList();


  bool isAutoConnect() {

    return autoConnectFlag;
  }
}
