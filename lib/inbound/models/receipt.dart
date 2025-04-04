

import 'package:cwms_mobile/common/models/carrier.dart';
import 'package:cwms_mobile/common/models/carrier_service_level.dart';
import 'package:cwms_mobile/common/models/client.dart';
import 'package:cwms_mobile/common/models/customer.dart';
import 'package:cwms_mobile/common/models/supplier.dart';
import 'package:cwms_mobile/inbound/models/receipt_line.dart';
import 'package:cwms_mobile/inbound/models/receipt_status.dart';
import 'package:json_annotation/json_annotation.dart';



part 'receipt.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class Receipt{
  Receipt() {
    id = null;
    number = "";
    client = null;
    supplier = null;
    receiptLines = [];
    allowUnexpectedItem = false;
    receiptStatus = ReceiptStatus.OPEN;
  }

  int? id;
  String? number;

  Client? client;
  Supplier? supplier;
  List<ReceiptLine> receiptLines = [];

  bool? allowUnexpectedItem;
  ReceiptStatus? receiptStatus;

  int? totalExpectedQuantity;
  int? totalReceivedQuantity;




  //不同的类使用不同的mixin即可
  factory Receipt.fromJson(Map<String, dynamic> json) => _$ReceiptFromJson(json);
  Map<String, dynamic> toJson() => _$ReceiptToJson(this);





}