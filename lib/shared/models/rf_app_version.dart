

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

import 'cwms_application_information.dart';

// server.g.dart 将在我们运行生成命令后自动生成
part 'rf_app_version.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class RFAppVersion {
  RFAppVersion();

  int  id;
  String versionNumber;
  String fileName;
  int fileSize;
  bool isLatestVersion;
  int companyId;

  String releaseNote;
  DateTime releaseDate;




  //不同的类使用不同的mixin即可
  factory RFAppVersion.fromJson(Map<String, dynamic> json) => _$RFAppVersionFromJson(json);
  Map<String, dynamic> toJson() => _$RFAppVersionToJson(this);


}
