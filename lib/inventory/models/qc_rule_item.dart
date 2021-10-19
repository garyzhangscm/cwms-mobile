import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/inventory/models/qc_rule_item_comparator.dart';
import 'package:cwms_mobile/inventory/models/qc_rule_item_type.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:json_annotation/json_annotation.dart';

import 'inventory_movement.dart';
import 'inventory_status.dart';
import 'item.dart';
import 'item_package_type.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'qc_rule_item.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class QCRuleItem{
  QCRuleItem() ;

  int id;
  String checkPoint;
  QCRuleItemType qcRuleItemType;
  String expectedValue;
  QCRuleItemComparator qcRuleItemComparator;


  //不同的类使用不同的mixin即可
  factory QCRuleItem.fromJson(Map<String, dynamic> json) => _$QCRuleItemFromJson(json);
  Map<String, dynamic> toJson() => _$QCRuleItemToJson(this);




}