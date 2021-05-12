import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

part 'unit_of_measure.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class UnitOfMeasure{
  UnitOfMeasure();

  int id;
  String name;

  String description;







  //不同的类使用不同的mixin即可
  factory UnitOfMeasure.fromJson(Map<String, dynamic> json) => _$UnitOfMeasureFromJson(json);
  Map<String, dynamic> toJson() => _$UnitOfMeasureToJson(this);





}