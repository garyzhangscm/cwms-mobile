import 'dart:ffi';

import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pick_result.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class PickResult{
  PickResult();

  bool result;
  int confirmedQuantity;

  // key: pick id
  // value: confirmed quantity
  Map<int, int> confirmedPickResult;

  // in case of pick cancellation
  Set<int> cancelledPicks;

  List<Pick> reallocatedPicks;




  //不同的类使用不同的mixin即可
  factory PickResult.fromJson(Map<String, dynamic> json) => _$PickResultFromJson(json);
  Map<String, dynamic> toJson() => _$PickResultToJson(this);





}