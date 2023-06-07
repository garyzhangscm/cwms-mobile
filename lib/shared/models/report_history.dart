

import 'package:cwms_mobile/shared/models/report_orientation.dart';
import 'package:cwms_mobile/shared/models/report_type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'cwms_application_information.dart';

// server.g.dart 将在我们运行生成命令后自动生成
part 'report_history.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class ReportHistory {

  ReportHistory();

  int id;
  int warehouseId;

  DateTime printedDate;
  String printedUsername;


  String description;


  ReportType type;
  String fileName;

  ReportOrientation reportOrientation;



  //不同的类使用不同的mixin即可
  factory ReportHistory.fromJson(Map<String, dynamic> json) => _$ReportHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$ReportHistoryToJson(this);


}
