

import 'package:json_annotation/json_annotation.dart';

part 'carrier_service_level.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class CarrierServiceLevel{
  CarrierServiceLevel();

  int? id;
  String? name;

  String? description;

  String? type;





  //不同的类使用不同的mixin即可
  factory CarrierServiceLevel.fromJson(Map<String, dynamic> json)
      => _$CarrierServiceLevelFromJson(json);
  Map<String, dynamic> toJson() => _$CarrierServiceLevelToJson(this);





}