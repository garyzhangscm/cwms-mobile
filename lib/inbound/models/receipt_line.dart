
import 'package:cwms_mobile/inventory/models/item.dart';

import 'package:json_annotation/json_annotation.dart';

part 'receipt_line.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class ReceiptLine{
  ReceiptLine() {
    id = null;
    number = "";
    item = new Item();
    expectedQuantity = 0;
    receivedQuantity = 0;
    overReceivingQuantity = 0;
    overReceivingPercent = 0.0;
  }

  int? id;
  String? number;

  Item? item;
  int? expectedQuantity;
  int? receivedQuantity;
  int? arrivedQuantity;
  int? overReceivingQuantity;
  double? overReceivingPercent;

  int? itemPackageTypeId;



  //不同的类使用不同的mixin即可
  factory ReceiptLine.fromJson(Map<String, dynamic> json) => _$ReceiptLineFromJson(json);
  Map<String, dynamic> toJson() => _$ReceiptLineToJson(this);





}