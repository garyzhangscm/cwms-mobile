

import 'package:cwms_mobile/common/models/carrier.dart';
import 'package:cwms_mobile/common/models/carrier_service_level.dart';
import 'package:cwms_mobile/common/models/customer.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/workorder/models/material-consume-timing.dart';
import 'package:cwms_mobile/workorder/models/work_order_line.dart';
import 'package:cwms_mobile/workorder/models/work_order_status.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:json_annotation/json_annotation.dart';

import 'bill_of_material.dart';


part 'work_order.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class WorkOrder{
  WorkOrder();

  int id;
  String number;


  Item item;
  int itemId;

  int warehouseId;
  Warehouse warehouse;

  List<WorkOrderLine> workOrderLines;

  WorkOrderStatus status;

  int expectedQuantity;
  int producedQuantity;


  int totalLineExpectedQuantity;
  int totalLineOpenQuantity;
  int totalLineInprocessQuantity;
  int totalLineDeliveredQuantity;
  int totalLineConsumedQuantity;


  bool consumeByBomOnly;

  BillOfMaterial consumeByBom;
  MaterialConsumeTiming materialConsumeTiming;



  //不同的类使用不同的mixin即可
  factory WorkOrder.fromJson(Map<String, dynamic> json) => _$WorkOrderFromJson(json);
  Map<String, dynamic> toJson() => _$WorkOrderToJson(this);





}