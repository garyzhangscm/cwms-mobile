import 'package:cwms_mobile/inventory/models/qc_inspection_request_item_option.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/inventory/models/qc_rule.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:json_annotation/json_annotation.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'qc_inspection_request_item.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class QCInspectionRequestItem {
  QCInspectionRequestItem() ;

  int? id;
  QCRule? qcRule;
  QCInspectionResult? qcInspectionResult;
  List<QCInspectionRequestItemOption> qcInspectionRequestItemOptions = [];




  //不同的类使用不同的mixin即可
  factory QCInspectionRequestItem.fromJson(Map<String, dynamic> json) => _$QCInspectionRequestItemFromJson(json);
  Map<String, dynamic> toJson() => _$QCInspectionRequestItemToJson(this);




}