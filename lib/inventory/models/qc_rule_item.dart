

import 'package:cwms_mobile/inventory/models/qc_rule_item_comparator.dart';
import 'package:cwms_mobile/inventory/models/qc_rule_item_type.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:json_annotation/json_annotation.dart';


// user.g.dart 将在我们运行生成命令后自动生成
part 'qc_rule_item.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class QCRuleItem{
  QCRuleItem() ;

  int? id;
  String? checkPoint;
  QCRuleItemType? qcRuleItemType;
  bool? enabled;
  String? expectedValue;
  QCRuleItemComparator? qcRuleItemComparator;


  //不同的类使用不同的mixin即可
  factory QCRuleItem.fromJson(Map<String, dynamic> json) => _$QCRuleItemFromJson(json);
  Map<String, dynamic> toJson() => _$QCRuleItemToJson(this);





}