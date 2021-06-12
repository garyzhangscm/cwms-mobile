import 'package:cwms_mobile/common/models/carrier.dart';
import 'package:cwms_mobile/common/models/carrier_service_level.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';

import 'package:json_annotation/json_annotation.dart';

part 'bill_of_material_line.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class BillOfMaterialLine{
  BillOfMaterialLine();

  int id;
  String number;

  Item item;
  int itemId;

  int expectedQuantity;

  int inventoryStatusId;
  InventoryStatus inventoryStatus;






  //不同的类使用不同的mixin即可
  factory BillOfMaterialLine.fromJson(Map<String, dynamic> json) => _$BillOfMaterialLineFromJson(json);
  Map<String, dynamic> toJson() => _$BillOfMaterialLineToJson(this);





}