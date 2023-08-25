

import 'package:cwms_mobile/common/models/reason_code.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_kpi_transaction.dart';
import 'package:cwms_mobile/workorder/models/work_order_line_consume_transaction.dart';
import 'package:cwms_mobile/workorder/models/work_order_produced_inventory.dart';
import 'package:json_annotation/json_annotation.dart';

import 'bill_of_material.dart';


part 'work_order_produce_transaction.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class WorkOrderProduceTransaction{
  WorkOrderProduceTransaction();

  WorkOrder workOrder;
  List<WorkOrderLineConsumeTransaction> workOrderLineConsumeTransactions;
  List<WorkOrderProducedInventory> workOrderProducedInventories;
  List<WorkOrderKPITransaction> workOrderKPITransactions;
  bool consumeByBomQuantity;
  BillOfMaterial consumeByBom;
  ProductionLine productionLine;

  // reason code. normally used when there's
  // defective product being produced
  int reasonCodeId;
  ReasonCode reasonCode;




  //不同的类使用不同的mixin即可
  factory WorkOrderProduceTransaction.fromJson(Map<String, dynamic> json) => _$WorkOrderProduceTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$WorkOrderProduceTransactionToJson(this);





}