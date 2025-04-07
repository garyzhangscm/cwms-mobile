import 'package:cwms_mobile/auth/models/menu.dart';
import 'package:cwms_mobile/auth/models/menu_sub_group.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:json_annotation/json_annotation.dart';

import 'location_group.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'warehouse_location.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class WarehouseLocation{
  WarehouseLocation();

  int? id;
  String? name;

  String? aisle;
  double? x;
  double? y;
  double? z;
  double? length;
  double? width;
  double? height;
  int? pickSequence;
  int? putawaySequence;
  int? countSequence;
  double? capacity;
  double? fillPercentage;
  double? currentVolume;
  double? pendingVolume;
  LocationGroup? locationGroup;
  bool? enabled;
  bool? locked;
  String? reservedCode;

  //不同的类使用不同的mixin即可
  factory WarehouseLocation.fromJson(Map<String, dynamic> json) => _$WarehouseLocationFromJson(json);
  Map<String, dynamic> toJson() => _$WarehouseLocationToJson(this);

}