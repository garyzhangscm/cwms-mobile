import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:json_annotation/json_annotation.dart';

part 'supplier.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class Supplier{
  Supplier();

  int id;
  String name;

  String description;

  String contactorFirstname;
  String contactorLastname;

  String addressCountry;
  String addressState;
  String addressCounty;
  String addressCity;
  String addressDistrict;
  String addressLine1;
  String addressLine2;
  String addressPostcode;





  //不同的类使用不同的mixin即可
  factory Supplier.fromJson(Map<String, dynamic> json) => _$SupplierFromJson(json);
  Map<String, dynamic> toJson() => _$SupplierToJson(this);





}