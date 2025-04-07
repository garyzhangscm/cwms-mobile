import 'package:cwms_mobile/common/models/carrier.dart';
import 'package:cwms_mobile/common/models/carrier_service_level.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/workorder/models/work_order_line.dart';

import 'package:json_annotation/json_annotation.dart';

part 'work_order_line_consume_transaction.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class WorkOrderLineConsumeTransaction{
  WorkOrderLineConsumeTransaction();

  int? id;
  WorkOrderLine? workOrderLine;

  int? consumedQuantity;

  //不同的类使用不同的mixin即可
  factory WorkOrderLineConsumeTransaction.fromJson(Map<String, dynamic> json) => _$WorkOrderLineConsumeTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$WorkOrderLineConsumeTransactionToJson(this);





}