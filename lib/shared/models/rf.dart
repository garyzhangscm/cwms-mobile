

import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

// server.g.dart 将在我们运行生成命令后自动生成
part 'rf.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class RF {

  RF();

  int? id;

  int? warehouseId;

  String? rfCode;

  int? currentLocationId;

  String? currentLocationName;

  WarehouseLocation? currentLocation;

  String? printerName;




  //不同的类使用不同的mixin即可
  factory RF.fromJson(Map<String, dynamic> json) => _$RFFromJson(json);
  Map<String, dynamic> toJson() => _$RFToJson(this);


}
