import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

// server.g.dart 将在我们运行生成命令后自动生成
part 'cwms_application_information.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class CWMSApplicationInformation {
  CWMSApplicationInformation();


  String name;
  String description;
  String version;






  //不同的类使用不同的mixin即可
  factory CWMSApplicationInformation.fromJson(Map<String, dynamic> json) => _$CWMSApplicationInformationFromJson(json);
  Map<String, dynamic> toJson() => _$CWMSApplicationInformationToJson(this);
}
