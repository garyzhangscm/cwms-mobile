import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:cwms_mobile/common/models/client.dart';

import 'inventory_movement.dart';
import 'inventory_status.dart';
import 'item.dart';
import 'item_package_type.dart';

class ReversedInventoryInformation{
  ReversedInventoryInformation(
      this.lpn, this.clientName, this.itemName,
      this.itemPackageTypeName, this.quantity,
      this.locationName, this.workOrderNumber, this.receiptNumber) {
    this.reverseInProgress = false;
    this.reverseResult = false;
    this.result = "";
  }

  ReversedInventoryInformation.fromProducedInventory(
      this.lpn, this.clientName, this.itemName,
      this.itemPackageTypeName, this.quantity,
      this.locationName, this.workOrderNumber) {
    this.reverseInProgress = false;
    this.reverseResult = false;
    this.result = "";
  }

  ReversedInventoryInformation.fromReceivedInventory(
      this.lpn, this.clientName, this.itemName,
      this.itemPackageTypeName, this.quantity,
      this.locationName, this.receiptNumber) {
    this.reverseInProgress = false;
    this.reverseResult = false;
    this.result = "";
  }

  String lpn;
  String clientName;
  String itemName;
  String itemPackageTypeName;
  int quantity;
  String locationName;
  String workOrderNumber;
  String receiptNumber;
  bool reverseInProgress;
  bool reverseResult;
  String result;



}