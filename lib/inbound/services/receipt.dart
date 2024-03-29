
import 'dart:convert';

import 'package:cwms_mobile/common/services/system_controlled_number.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/inbound/models/receipt.dart';
import 'package:cwms_mobile/inbound/models/receipt_line.dart';
import 'package:cwms_mobile/inbound/models/receipt_status.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/models/lpn_capture_request.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:dio/dio.dart';

class ReceiptService {

  static Future<Receipt> getReceiptById(int receiptId) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "inbound/receipts/${receiptId}",
        queryParameters: {"warehouseId": Global.currentWarehouse.id}
    );

    // printLongLogMessage("response from receipt: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());


    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return Receipt.fromJson(responseString["data"]);

  }

  static Future<ReceiptLine> getReceiptLineById(int receiptLineId) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "inbound/receipts/receipt-lines/$receiptLineId",
        queryParameters: {"warehouseId": Global.currentWarehouse.id}
    );

    // printLongLogMessage("response from receipt: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());


    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return ReceiptLine.fromJson(responseString["data"]);

  }

  static Future<Receipt> getReceiptByNumber(String receiptNumber) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "inbound/receipts",
        queryParameters: {"number": receiptNumber,
          "warehouseId": Global.currentWarehouse.id}
    );

    // printLongLogMessage("response from receipt: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());


    List<Receipt> receipts
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : Receipt.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // Sort the picks according to the current location. We
    // will assign the closed pick to the user
    if (receipts.length > 0) {
      return receipts.first;
    }
    else {
      return null;
    }

  }


  // Get available Orders
  // 1. with open picks
  // 2. no
  static Future<List<Receipt>> getOpenReceipts() async {
    Dio httpClient = CWMSHttpClient.getDio();

    // receipt status that we can start receiving
    String openReceiptStatuses =
        ReceiptStatus.CHECK_IN.toString().split('.').last + ","
            + ReceiptStatus.RECEIVING.toString().split('.').last;
    print("openReceiptStatuses: $openReceiptStatuses");

    Response response = await httpClient.get(
        "inbound/receipts",
        queryParameters: {"warehouseId": Global.currentWarehouse.id,
            "receipt_status_list": openReceiptStatuses}
    );

    // printLongLogMessage("response from Receipt: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    // List<dynamic> responseData = responseString["data"];

    List<Receipt> receipts
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : Receipt.fromJson(e as Map<String, dynamic>))
        ?.toList();

    print("get ${receipts.length} receipts");

    return receipts;

  }

  static Future<Inventory> receiveInventory(Receipt receipt, ReceiptLine receiptLine,
      String lpn, InventoryStatus inventoryStatus,
      ItemPackageType itemPackageType, int quantity) async {

    printLongLogMessage("start to receiving inventory from receiptLine: ${receiptLine.item.toJson()}");
    if (lpn.isEmpty) {
      lpn = await SystemControlledNumberService.getNextAvailableId("lpn");
    }

    Inventory inventory = await _generateReceivedInventory(
      receipt, receiptLine, lpn, inventoryStatus,
      itemPackageType, quantity
    );

    // send the receiving request to the server
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "/inbound/receipts/${receipt.id}/lines/${receiptLine.id}/receive",
        data: inventory,
      queryParameters: {
          "receiveToStage": Global.getRFConfiguration.receiveToStage
      }
    );

    // printLongLogMessage("response from receiving: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return Inventory.fromJson(responseString["data"]);





  }

  static Future<Inventory> _generateReceivedInventory(Receipt receipt, ReceiptLine receiptLine,
      String lpn, InventoryStatus inventoryStatus,
      ItemPackageType itemPackageType, int quantity) async {

    Inventory inventory = new Inventory();
    inventory.lpn = lpn;
    inventory.item = receiptLine.item;
    inventory.warehouseId = Global.currentWarehouse.id;
    inventory.quantity = quantity;
    // receive the inventory onto RF
    inventory.location = await WarehouseLocationService.getWarehouseLocationByName(
        Global.lastLoginRFCode
    );
    print("inventory's location: ${inventory.location.locationGroup.locationGroupType.virtual}");
    inventory.inventoryStatus = inventoryStatus;
    inventory.itemPackageType = itemPackageType;
    inventory.locationId = inventory.location.id;
    inventory.receiptId = receipt.id;
    inventory.receiptLineId = receiptLine.id;
    inventory.inventoryMovements = [];
    return inventory;
  }


  static Future<List<Inventory>> receiveInventoryWithMultipleLpn(Receipt receipt, ReceiptLine receiptLine,
       InventoryStatus inventoryStatus,
      ItemPackageType itemPackageType, LpnCaptureRequest lpnCaptureRequest) async {

    List<Inventory> inventoryList = await _generateReceivedInventoryList(receipt, receiptLine, inventoryStatus, itemPackageType, lpnCaptureRequest);

    // send the receiving request to the server
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "/inbound/receipts/${receipt.id}/lines/${receiptLine.id}/receive-multiple-lpns",
        data: inventoryList
    );

    // printLongLogMessage("response from receiving: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


    inventoryList
        = (responseString["data"] as List)?.map((e) =>
        e == null ? null : Inventory.fromJson(e as Map<String, dynamic>))
            ?.toList();

    print("get ${inventoryList.length} Inventory");

    return inventoryList;
  }

  static Future<List<Inventory>> _generateReceivedInventoryList(Receipt receipt, ReceiptLine receiptLine,
       InventoryStatus inventoryStatus,
      ItemPackageType itemPackageType, LpnCaptureRequest lpnCaptureRequest) async {

    List<Inventory> inventoryList = [];
    await lpnCaptureRequest.capturedLpn.forEach((element) async {
      Inventory inventory = await _generateReceivedInventory(receipt, receiptLine,
          element, inventoryStatus, itemPackageType, lpnCaptureRequest.lpnUnitOfMeasure.quantity);
    });

    return inventoryList;

  }


}




