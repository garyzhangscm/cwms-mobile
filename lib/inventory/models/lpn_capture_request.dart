import 'package:cwms_mobile/common/models/client.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_unit_of_measure.dart';
import 'package:json_annotation/json_annotation.dart';

import 'item_package_type.dart';

part 'lpn_capture_request.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class LpnCaptureRequest{
  LpnCaptureRequest();

  LpnCaptureRequest.withData(Item item,
      ItemPackageType itemPackageType,
      ItemUnitOfMeasure lpnUnitOfMeasure,
      int requestedLPNQuantity,
      Set<String> capturedLpn,
      bool newLPNOnly) {

    this.item = item;
    this.itemPackageType = itemPackageType;
    this.lpnUnitOfMeasure = lpnUnitOfMeasure;
    this.requestedLPNQuantity = requestedLPNQuantity;
    this.capturedLpn = capturedLpn;
    this.result = false;
    this.newLPNOnly = newLPNOnly;
  }

  Item? item;
  ItemPackageType? itemPackageType;
  ItemUnitOfMeasure? lpnUnitOfMeasure;

  int? requestedLPNQuantity;
  Set<String> capturedLpn = new Set();

  bool? result;
  bool? newLPNOnly;

  factory LpnCaptureRequest.fromJson(Map<String, dynamic> json) => _$LpnCaptureRequestFromJson(json);
  Map<String, dynamic> toJson() => _$LpnCaptureRequestToJson(this);



}