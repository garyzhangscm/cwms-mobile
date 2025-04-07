

import 'package:cwms_mobile/common/models/carrier.dart';
import 'package:cwms_mobile/common/models/carrier_service_level.dart';
import 'package:cwms_mobile/common/models/customer.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_kpi_transaction_type.dart';
import 'package:cwms_mobile/workorder/models/work_order_line.dart';
import 'package:cwms_mobile/workorder/models/work_order_line_consume_transaction.dart';
import 'package:cwms_mobile/workorder/models/work_order_produced_inventory.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:json_annotation/json_annotation.dart';

import 'bill_of_material.dart';
import 'kpi_measurement.dart';


part 'work_order_kpi_transaction.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class WorkOrderKPITransaction{
  WorkOrderKPITransaction();

  int? id;
  String? username;
  String? workingTeamName;
  KPIMeasurement? kpiMeasurement;
  WorkOrderKPITransactionType? type;
  double? amount;




  //不同的类使用不同的mixin即可
  factory WorkOrderKPITransaction.fromJson(Map<String, dynamic> json) => _$WorkOrderKPITransactionFromJson(json);
  Map<String, dynamic> toJson() => _$WorkOrderKPITransactionToJson(this);





}