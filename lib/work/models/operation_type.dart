 import 'package:json_annotation/json_annotation.dart';

part 'operation_type.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class OperationType{
  OperationType();

  int id;

  String name;
  String description;
  int defaultPriority;



  //不同的类使用不同的mixin即可
  factory OperationType.fromJson(Map<String, dynamic> json) => _$OperationTypeFromJson(json);
  Map<String, dynamic> toJson() => _$OperationTypeToJson(this);





}