
import 'package:json_annotation/json_annotation.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'inventory_status.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class InventoryStatus{
  InventoryStatus() {
    id = null;
    name = "";
    description = "";
  }

  int id;
  String name;
  String description;


  int warehouseId;





  //不同的类使用不同的mixin即可
  factory InventoryStatus.fromJson(Map<String, dynamic> json) => _$InventoryStatusFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryStatusToJson(this);




}