

import 'package:json_annotation/json_annotation.dart';
import 'cwms_application_information.dart';

// server.g.dart 将在我们运行生成命令后自动生成
part 'rf.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class RF {

  RF();

  int warehouseId;

  String rfCode;

  int currentLocationId;

  String printerName;




  //不同的类使用不同的mixin即可
  factory RF.fromJson(Map<String, dynamic> json) => _$RFFromJson(json);
  Map<String, dynamic> toJson() => _$RFToJson(this);


}
