import 'package:cwms_mobile/common/models/carrier.dart';
import 'package:cwms_mobile/common/models/carrier_service_level.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';

import 'package:json_annotation/json_annotation.dart';

part 'order_line.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class OrderLine{
  OrderLine();

  int? id;
  String? number;

  Item? item;
  int? expectedQuantity;
  int? openQuantity;



  int? inprocessQuantity;
  int? shippedQuantity;
  int? productionPlanInprocessQuantity;
  int? productionPlanProducedQuantity;

  Carrier? carrier;
  CarrierServiceLevel? carrierServiceLevel;

  InventoryStatus? inventoryStatus;





  //不同的类使用不同的mixin即可
  factory OrderLine.fromJson(Map<String, dynamic> json) => _$OrderLineFromJson(json);
  Map<String, dynamic> toJson() => _$OrderLineToJson(this);





}