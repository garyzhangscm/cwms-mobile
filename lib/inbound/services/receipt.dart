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
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:cwms_mobile/workorder/models/bill_of_material.dart';
import 'package:cwms_mobile/workorder/models/bill_of_material_line.dart';
import 'package:dio/dio.dart';

import 'package:collection/collection.dart';

class ReceiptService {
  static Future<Receipt> getReceiptById(int receiptId) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get("inbound/receipts/${receiptId}",
        queryParameters: {"warehouseId": Global.currentWarehouse!.id});

    // printLongLogMessage("response from receipt: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage(
          "getReceiptById / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() +
          ":" +
          responseString["message"]);
    }

    return Receipt.fromJson(responseString["data"]);
  }

  static Future<ReceiptLine> getReceiptLineById(int receiptLineId) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "inbound/receipts/receipt-lines/$receiptLineId",
        queryParameters: {"warehouseId": Global.currentWarehouse!.id});

    // printLongLogMessage("response from receipt: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage(
          "getReceiptLineById / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() +
          ":" +
          responseString["message"]);
    }

    return ReceiptLine.fromJson(responseString["data"]);
  }

  static Future<Receipt?> getReceiptByNumber(String receiptNumber) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response =
        await httpClient.get("inbound/receipts", queryParameters: {
      "number": receiptNumber,
      "warehouseId": Global.currentWarehouse!.id,
      // The list endpoint may return receipt lines without the item
      // relationship. Request the expanded form for barcode receiving.
      "loadDetails": true
    });

    printLongLogMessage("response from getReceiptByNumber: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    List<Receipt> receipts = (responseString["data"] as List)
        .map((e) => Receipt.fromJson(e as Map<String, dynamic>))
        .toList();

    // Sort the picks according to the current location. We
    // will assign the closed pick to the user
    if (receipts.length > 0) {
      return receipts.first;
    } else {
      return null;
    }
  }

  // Get available Orders
  // 1. with open picks
  // 2. no
  static Future<List<Receipt>> getOpenReceipts({
    int pageIndex = 0,
    int pageSize = 10,
  }) async {
    Dio httpClient = CWMSHttpClient.getDio();
    final stopwatch = Stopwatch()..start();

    // receipt status that we can start receiving
    String openReceiptStatuses =
        ReceiptStatus.CHECK_IN.toString().split('.').last +
            "," +
            ReceiptStatus.RECEIVING.toString().split('.').last;
    print("openReceiptStatuses: $openReceiptStatuses");

    // v1.64 exposes a paginated endpoint. Request only the ten most recent
    // open receipts instead of downloading every open receipt in the
    // warehouse and trimming the list locally.
    Response response =
        await httpClient.get("inbound/paginated-receipts", queryParameters: {
      "warehouseId": Global.currentWarehouse!.id,
      "receipt_status_list": openReceiptStatuses,
      "pageIndex": pageIndex,
      "pageSize": pageSize,
      "loadDetails": true,
    });
    final networkMilliseconds = stopwatch.elapsedMilliseconds;

    Map<String, dynamic> responseString = json.decode(response.toString());
    final pageData = responseString["data"];
    // The paginated endpoint returns a Spring Page under data.content. Keep a
    // list fallback so the app remains compatible with older server builds.
    final responseData =
        pageData is Map<String, dynamic> ? pageData["content"] : pageData;
    if (responseData is! List) {
      throw WebAPICallException("Invalid paginated receipt response");
    }

    List<Receipt> receipts = responseData
        .map((e) => Receipt.fromJson(e as Map<String, dynamic>))
        .toList();

    printLongLogMessage("getOpenReceipts: network ${networkMilliseconds} ms, "
        "parse ${stopwatch.elapsedMilliseconds - networkMilliseconds} ms, "
        "${receipts.length} receipts");
    print("get ${receipts.length} receipts");

    return receipts;
  }

  static Future<Inventory> receiveInventory(
      Receipt receipt,
      ReceiptLine receiptLine,
      String lpn,
      InventoryStatus inventoryStatus,
      ItemPackageType itemPackageType,
      int quantity,
      String color,
      String productSize,
      String style,
      String inventoryAttribute1,
      String inventoryAttribute2,
      String inventoryAttribute3,
      String inventoryAttribute4,
      String inventoryAttribute5,
      bool kitInnerInventoryWithDefaultAttribute,
      bool kitInnerInventoryAttributeFromKit) async {
    printLongLogMessage(
        "start to receiving inventory from receiptLine: ${receiptLine.item?.toJson()}");
    if (lpn.isEmpty) {
      lpn = await SystemControlledNumberService.getNextAvailableId("lpn");
    }

    Inventory inventory = await _generateReceivedInventory(
        receipt,
        receiptLine,
        lpn,
        inventoryStatus,
        itemPackageType,
        quantity,
        color,
        productSize,
        style,
        inventoryAttribute1,
        inventoryAttribute2,
        inventoryAttribute3,
        inventoryAttribute4,
        inventoryAttribute5,
        kitInnerInventoryWithDefaultAttribute,
        kitInnerInventoryAttributeFromKit);
    printLongLogMessage("and inventory: ${inventory.toJson()}");

    // send the receiving request to the server
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "/inbound/receipts/${receipt.id}/lines/${receiptLine.id}/receive",
        data: jsonEncode(inventory),
        queryParameters: {
          "receiveToStage": Global.getRFConfiguration.receiveToStage
        });

    // printLongLogMessage("response from receiving: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage(
          "receiveInventory / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() +
          ":" +
          responseString["message"]);
    }

    return Inventory.fromJson(responseString["data"]);
  }

  static Future<Inventory> _generateReceivedInventory(
      Receipt receipt,
      ReceiptLine receiptLine,
      String lpn,
      InventoryStatus inventoryStatus,
      ItemPackageType itemPackageType,
      int quantity,
      String color,
      String productSize,
      String style,
      String inventoryAttribute1,
      String inventoryAttribute2,
      String inventoryAttribute3,
      String inventoryAttribute4,
      String inventoryAttribute5,
      bool kitInnerInventoryWithDefaultAttribute,
      bool kitInnerInventoryAttributeFromKit) async {
    Inventory inventory = new Inventory();
    inventory.lpn = lpn;
    inventory.item = receiptLine.item!;
    inventory.warehouseId = Global.currentWarehouse!.id;
    inventory.quantity = quantity;
    // Reuse the RF location loaded during login when it still matches the
    // current RF. Fall back to the API for older/stale login data.
    final cachedRF = Global.lastLoginRF;
    final cachedLocation = cachedRF?.currentLocation;
    final isCurrentRFLocation = cachedLocation != null &&
        (cachedLocation.name == Global.lastLoginRFCode ||
            cachedRF?.currentLocationName == Global.lastLoginRFCode);
    inventory.location = isCurrentRFLocation
        ? cachedLocation
        : await WarehouseLocationService.getWarehouseLocationByName(
            Global.lastLoginRFCode!);
    print(
        "inventory's location: ${inventory.location?.locationGroup?.locationGroupType?.virtual}");
    inventory.inventoryStatus = inventoryStatus;
    inventory.itemPackageType = itemPackageType;
    inventory.locationId = inventory.location?.id;
    inventory.receiptId = receipt.id!;
    inventory.receiptLineId = receiptLine.id!;
    inventory.inventoryMovements = [];
    inventory.color = color;
    inventory.productSize = productSize;
    inventory.style = style;
    inventory.attribute1 = inventoryAttribute1;
    inventory.attribute2 = inventoryAttribute2;
    inventory.attribute3 = inventoryAttribute3;
    inventory.attribute4 = inventoryAttribute4;
    inventory.attribute5 = inventoryAttribute5;

    inventory.kitInnerInventories = [];
    inventory.kitInnerInventoryFlag = false;
    inventory.kitInventoryFlag = false;

    // we are only allow to receive kit item
    // with inner items; we can't receive
    // the inner items directly
    if (inventory.item?.kitItemFlag != null &&
        inventory.item?.kitItemFlag == true &&
        inventory.item?.kitInnerItems.isNotEmpty == true) {
      // we are receive a kit item, let's create the inner inventory as well
      inventory.kitInventoryFlag = true;

      inventory.item?.kitInnerItems.forEach((kitInnerItem) {
        Inventory kitInnerInventory = new Inventory();
        kitInnerInventory.lpn = lpn;
        kitInnerInventory.item = kitInnerItem;
        kitInnerInventory.warehouseId = Global.currentWarehouse!.id;
        // calculate the actual quantity based on the bill of material
        BillOfMaterial billOfMaterial = receiptLine.item!.billOfMaterial!;
        BillOfMaterialLine? matchedBillOfMaterialLine = billOfMaterial
            .billOfMaterialLines
            .firstWhereOrNull((element) => element.itemId == kitInnerItem.id);

        kitInnerInventory.quantity = (quantity *
            matchedBillOfMaterialLine!.expectedQuantity! /
            billOfMaterial.expectedQuantity!) as int;

        // receive the inventory onto RF
        kitInnerInventory.location = inventory.location;

        kitInnerInventory.inventoryStatus = inventoryStatus;
        // get the default item package type. Basically we don't care about the item package type
        // for any inventory inside the kit
        kitInnerInventory.itemPackageType =
            kitInnerItem.defaultItemPackageType!;
        kitInnerInventory.locationId = inventory.location?.id;
        kitInnerInventory.receiptId = receipt.id!;
        kitInnerInventory.receiptLineId = receiptLine.id!;
        kitInnerInventory.inventoryMovements = [];

        // either we get the attribute from inner item's default value
        // or we get from the kit(outside) inventory
        if (kitInnerInventoryWithDefaultAttribute) {
          kitInnerInventory.color = kitInnerItem.defaultColor ?? "";
          kitInnerInventory.productSize = kitInnerItem.defaultProductSize ?? "";
          kitInnerInventory.style = kitInnerItem.defaultStyle ?? "";
          kitInnerInventory.attribute1 =
              kitInnerItem.defaultInventoryAttribute1 ?? "";
          kitInnerInventory.attribute2 =
              kitInnerItem.defaultInventoryAttribute2 ?? "";
          kitInnerInventory.attribute3 =
              kitInnerItem.defaultInventoryAttribute3 ?? "";
          kitInnerInventory.attribute4 =
              kitInnerItem.defaultInventoryAttribute4 ?? "";
          kitInnerInventory.attribute5 =
              kitInnerItem.defaultInventoryAttribute5 ?? "";
        } else {
          kitInnerInventory.color = inventory.color;
          kitInnerInventory.productSize = inventory.productSize;
          kitInnerInventory.style = inventory.style;
          kitInnerInventory.attribute1 = inventory.attribute1;
          kitInnerInventory.attribute2 = inventory.attribute2;
          kitInnerInventory.attribute3 = inventory.attribute3;
          kitInnerInventory.attribute4 = inventory.attribute4;
          kitInnerInventory.attribute5 = inventory.attribute5;
        }
        kitInnerInventory.kitInnerInventoryFlag = true;
        kitInnerInventory.kitInventory = inventory;
        inventory.kitInnerInventories.add(kitInnerInventory);
      });
    }

    // setup the kit inner item

    return inventory;
  }

  static Future<List<Inventory>> receiveInventoryWithMultipleLpn(
      Receipt receipt,
      ReceiptLine receiptLine,
      InventoryStatus inventoryStatus,
      ItemPackageType itemPackageType,
      LpnCaptureRequest lpnCaptureRequest) async {
    List<Inventory> inventoryList = await _generateReceivedInventoryList(
        receipt,
        receiptLine,
        inventoryStatus,
        itemPackageType,
        lpnCaptureRequest);

    // send the receiving request to the server
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "/inbound/receipts/${receipt.id}/lines/${receiptLine.id}/receive-multiple-lpns",
        data: jsonEncode(inventoryList));

    // printLongLogMessage("response from receiving: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage(
          "receiveInventoryWithMultipleLpn / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() +
          ":" +
          responseString["message"]);
    }

    inventoryList = (responseString["data"] as List)
        .map((e) => Inventory.fromJson(e as Map<String, dynamic>))
        .toList();

    print("get ${inventoryList.length} Inventory");

    return inventoryList;
  }

  static Future<List<Inventory>> _generateReceivedInventoryList(
      Receipt receipt,
      ReceiptLine receiptLine,
      InventoryStatus inventoryStatus,
      ItemPackageType itemPackageType,
      LpnCaptureRequest lpnCaptureRequest) async {
    List<Inventory> inventoryList = [];
    lpnCaptureRequest.capturedLpn.forEach((element) async {
      Inventory inventory = await _generateReceivedInventory(
          receipt,
          receiptLine,
          element,
          inventoryStatus,
          itemPackageType,
          lpnCaptureRequest.lpnUnitOfMeasure!.quantity!,
          "",
          "",
          "",
          "",
          "",
          "",
          "",
          "",
          false,
          false);
      inventoryList.add(inventory);
    });

    return inventoryList;
  }
}
