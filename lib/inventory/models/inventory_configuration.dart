import 'package:cwms_mobile/inbound/models/receipt_line.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:cwms_mobile/common/models/client.dart';

import '../../inbound/models/receipt.dart';
import 'inventory_movement.dart';
import 'inventory_status.dart';
import 'item.dart';
import 'item_package_type.dart';

// user.g.dart 将在我们运行生成命令后自动生成
part 'inventory_configuration.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class InventoryConfiguration{
  InventoryConfiguration() ;

  int id;

  int companyId;
  int warehouseId;

  String lpnValidationRule;

  String inventoryAttribute1DisplayName;
  bool inventoryAttribute1Enabled;
  String inventoryAttribute2DisplayName;
  bool inventoryAttribute2Enabled;
  String inventoryAttribute3DisplayName;
  bool inventoryAttribute3Enabled;
  String inventoryAttribute4DisplayName;
  bool inventoryAttribute4Enabled;
  String inventoryAttribute5DisplayName;
  bool inventoryAttribute5Enabled;



  //不同的类使用不同的mixin即可
  factory InventoryConfiguration.fromJson(Map<String, dynamic> json) => _$InventoryConfigurationFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryConfigurationToJson(this);




}