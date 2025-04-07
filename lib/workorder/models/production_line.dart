

import 'package:cwms_mobile/common/models/carrier.dart';
import 'package:cwms_mobile/common/models/carrier_service_level.dart';
import 'package:cwms_mobile/common/models/customer.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/workorder/models/work_order_line.dart';
import 'package:json_annotation/json_annotation.dart';


part 'production_line.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class ProductionLine{
  ProductionLine();

  int? id;
  String? name;


  int? inboundStageLocationId;
  WarehouseLocation? inboundStageLocation;
  int? outboundStageLocationId;
  WarehouseLocation? outboundStageLocation;
  int? productionLineLocationId;
  WarehouseLocation? productionLineLocation;



  //不同的类使用不同的mixin即可
  factory ProductionLine.fromJson(Map<String, dynamic> json) => _$ProductionLineFromJson(json);
  Map<String, dynamic> toJson() => _$ProductionLineToJson(this);





}