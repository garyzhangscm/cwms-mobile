import 'package:cwms_mobile/common/models/reason_code_type.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reason_code.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class ReasonCode{
  ReasonCode();

  int? id;
  String? name;

  String? description;


  ReasonCodeType? type;




  //不同的类使用不同的mixin即可
  factory ReasonCode.fromJson(Map<String, dynamic> json) => _$ReasonCodeFromJson(json);
  Map<String, dynamic> toJson() => _$ReasonCodeToJson(this);





}