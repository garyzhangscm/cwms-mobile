

import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/common/models/carrier.dart';
import 'package:cwms_mobile/common/models/carrier_service_level.dart';
import 'package:cwms_mobile/common/models/customer.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/production_line_activity_type.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_line.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:json_annotation/json_annotation.dart';

import 'bill_of_material_line.dart';


part 'production_line_activity.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class ProductionLineActivity{
  ProductionLineActivity();

  int id;
  WorkOrder workOrder;
  ProductionLine productionLine;
  int warehouseId;
  String username;
  User user;
  ProductionLineActivityType type;
  int workingTeamMemberCount;
  DateTime transactionTime;








  //不同的类使用不同的mixin即可
  factory ProductionLineActivity.fromJson(Map<String, dynamic> json) => _$ProductionLineActivityFromJson(json);
  Map<String, dynamic> toJson() => _$ProductionLineActivityToJson(this);





}