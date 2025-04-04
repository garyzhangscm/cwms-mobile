import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/work/models/work_task.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wave.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class Wave{
  Wave();
  int? id;
  String? number;

  int? totalOpenPickQuantity;
  int? totalPickedQuantity;


  //不同的类使用不同的mixin即可
  factory Wave.fromJson(Map<String, dynamic> json) => _$WaveFromJson(json);
  Map<String, dynamic> toJson() => _$WaveToJson(this);





}