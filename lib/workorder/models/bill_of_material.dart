

import 'package:cwms_mobile/common/models/carrier.dart';
import 'package:cwms_mobile/common/models/carrier_service_level.dart';
import 'package:cwms_mobile/common/models/customer.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/workorder/models/work_order_line.dart';
import 'package:json_annotation/json_annotation.dart';

import 'bill_of_material_line.dart';


part 'bill_of_material.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class BillOfMaterial{
  BillOfMaterial();

  int? id;
  String? number;
  String? description;
  List<BillOfMaterialLine> billOfMaterialLines = [];

  Item? item;
  int? itemId;

  double? expectedQuantity;

  int? warehouseId;
  Warehouse? warehouse;








  //不同的类使用不同的mixin即可
  factory BillOfMaterial.fromJson(Map<String, dynamic> json) => _$BillOfMaterialFromJson(json);
  Map<String, dynamic> toJson() => _$BillOfMaterialToJson(this);





}