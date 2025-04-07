import 'package:cwms_mobile/auth/models/menu.dart';
import 'package:cwms_mobile/auth/models/menu_sub_group.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:json_annotation/json_annotation.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'location_group_type.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class LocationGroupType{
  LocationGroupType();

  int? id;
  String? name;
  String? description;

  bool? fourWallInventory;
  bool? virtual;
  bool? receivingStage;
  bool? shippingStage;
  bool? productionLine;
  bool? productionLineInbound;
  bool? productionLineOutbound;
  bool? dock;
  bool? yard;
  bool? storage;
  bool? pickupAndDeposit;
  bool? trailer;
  bool? qcArea;

  //不同的类使用不同的mixin即可
  factory LocationGroupType.fromJson(Map<String, dynamic> json) => _$LocationGroupTypeFromJson(json);
  Map<String, dynamic> toJson() => _$LocationGroupTypeToJson(this);

}