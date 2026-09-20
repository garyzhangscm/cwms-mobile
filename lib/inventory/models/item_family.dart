import 'package:json_annotation/json_annotation.dart';


// user.g.dart 将在我们运行生成命令后自动生成
part 'item_family.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class ItemFamily{

  ItemFamily() ;

  int? id;

  String? name;
  String? description;



  int? warehouseId;
  int? companyId;




  //不同的类使用不同的mixin即可
  factory ItemFamily.fromJson(Map<String, dynamic> json) => _$ItemFamilyFromJson(json);
  Map<String, dynamic> toJson() => _$ItemFamilyToJson(this);




}