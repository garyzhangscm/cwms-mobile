import 'package:cwms_mobile/common/models/client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

import 'item_package_type.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'item.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class Item{
  Item() {
    id = null;
    name = "";
    description = "";
    warehouseId = null;
    clientId = null;
    client = null;
    itemPackageTypes = new List<ItemPackageType>();

  }

  int id;
  String name;
  String description;

  int clientId;

  Client client;

  List<ItemPackageType> itemPackageTypes;

  int warehouseId;





  //不同的类使用不同的mixin即可
  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
  Map<String, dynamic> toJson() => _$ItemToJson(this);




}