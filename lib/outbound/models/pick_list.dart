import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pick_list.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class PickList {
  PickList();

  int? id;
  String? number;


  List<Pick> picks = [];





  //不同的类使用不同的mixin即可
  factory PickList.fromJson(Map<String, dynamic> json) => _$PickListFromJson(json);
  Map<String, dynamic> toJson() => _$PickListToJson(this);





}