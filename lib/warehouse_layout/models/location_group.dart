import 'package:cwms_mobile/auth/models/menu.dart';
import 'package:cwms_mobile/auth/models/menu_sub_group.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:json_annotation/json_annotation.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'location_group.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class LocationGroup{
  LocationGroup();

  int id;
  String name;
  String description;
  Warehouse warehouse;

  bool pickable;
  bool storable;
  bool countable;
  bool adjustable;
  bool trackingVolume;

  //不同的类使用不同的mixin即可
  factory LocationGroup.fromJson(Map<String, dynamic> json) => _$LocationGroupFromJson(json);
  Map<String, dynamic> toJson() => _$LocationGroupToJson(this);

}