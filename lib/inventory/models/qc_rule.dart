

import 'package:cwms_mobile/inventory/models/qc_rule_item.dart';
import 'package:json_annotation/json_annotation.dart';


// user.g.dart 将在我们运行生成命令后自动生成
part 'qc_rule.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class QCRule{
  QCRule() ;

  int? id;
  int? warehouseId;
  String? name;
  String? description;

  List<QCRuleItem> qcRuleItems = [];


  //不同的类使用不同的mixin即可
  factory QCRule.fromJson(Map<String, dynamic> json) => _$QCRuleFromJson(json);
  Map<String, dynamic> toJson() => _$QCRuleToJson(this);




}