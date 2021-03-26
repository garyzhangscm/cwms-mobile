

import 'package:cwms_mobile/common/models/carrier.dart';
import 'package:cwms_mobile/common/models/carrier_service_level.dart';
import 'package:cwms_mobile/common/models/customer.dart';
import 'package:json_annotation/json_annotation.dart';

import 'order_line.dart';

part 'order.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class Order{
  Order();

  int id;
  String number;

  Customer shipToCustomer;
  Customer billToCustomer;

  String shipToContactorFirstname;
  String shipToContactorLastname;


  String shipToAddressCountry;
  String shipToAddressState;
  String shipToAddressCounty;
  String shipToAddressCity;
  String shipToAddressDistrict;
  String shipToAddressLine1;
  String shipToAddressLine2;
  String shipToAddressPostcode;


  String billToContactorFirstname;
  String billToContactorLastname;

  String billToAddressCountry;
  String billToAddressState;
  String billToAddressCounty;
  String billToAddressCity;
  String billToAddressDistrict;
  String billToAddressLine1;
  String billToAddressLine2;
  String billToAddressPostcode;

  Carrier carrier;
  CarrierServiceLevel carrierServiceLevel;

  List<OrderLine> orderLines;

  int totalLineCount;
  int totalItemCount;
  int totalExpectedQuantity;
  int totalOpenQuantity;
  int totalInprocessQuantity;
  int totalPendingAllocationQuantity;
  int  totalOpenPickQuantity;
  int totalPickedQuantity;
  int totalShippedQuantity;






  //不同的类使用不同的mixin即可
  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);





}