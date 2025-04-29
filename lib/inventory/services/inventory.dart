
import 'dart:collection';
import 'dart:convert';


import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/models/item_unit_of_measure.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/cwms_http_response.dart';
import 'package:cwms_mobile/shared/models/report_history.dart';
import 'package:cwms_mobile/shared/services/printing.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';


import '../../shared/services/printer.dart';
import '../models/inventory_quantity_for_display.dart';


class InventoryService {
  // Get inventory that on the current RF
  static Future<List<Inventory>> getInventoryOnCurrentRF() async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage("will get inventory on ${Global.getLastLoginRFCode()} from warehouse ${Global.currentWarehouse!.id}");
    Response response = await httpClient.get(
        "/inventory/inventories",
      queryParameters: {
          "warehouseId": Global.currentWarehouse!.id,
          'location': Global.getLastLoginRFCode()}
    );

     printLongLogMessage("response from inventory on RF:");

     printLongLogMessage(response.toString());

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("getInventoryOnCurrentRF / Start to raise error with message: ${(responseString["message"] == null? "" : responseString["message"])}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + (responseString["message"] == null? "" : responseString["message"]));
    }

    List<Inventory> inventories
      = (responseString["data"] as List).map((e) => Inventory.fromJson(e as Map<String, dynamic>))
          .toList();


    printLongLogMessage("we have ${inventories.length} on the RF");

    return inventories;
  }

  // Get inventory deposit request from a list of inventory
  // we may group inventories together based on same item / same status
  static List<InventoryDepositRequest> getInventoryDepositRequests(
      List<Inventory> inventories, bool groupItemFlag,
      bool groupInventoryStatusFlag
      ) {

    Map<String, InventoryDepositRequest> inventoryDepositRequestMap =
        new Map<String, InventoryDepositRequest>();

    if (inventories.isEmpty) {
      return inventoryDepositRequestMap.values.toList();
    }

    inventories.forEach((inventory) {
      String key = _getKey(inventory, groupItemFlag, groupInventoryStatusFlag);
      InventoryDepositRequest inventoryDepositRequest;
      if (inventoryDepositRequestMap.containsKey(key)) {
        // the request with same key already exists, let's just add current
        // inventory on top of it
        InventoryDepositRequest inventoryDepositRequest =
            inventoryDepositRequestMap[key]!;
        // add the inventory to the current deposit request
        inventoryDepositRequest.addInventory(inventory);
      }
      else {
        inventoryDepositRequestMap[key] = InventoryDepositRequest.fromInventory(inventory);
      }
    });

    return inventoryDepositRequestMap.values.toList();


  }

  // Get key for the inventory. We will use the key to group
  // inventory into deposit request
  static String _getKey(Inventory inventory, bool groupItemFlag,
      bool groupInventoryStatusFlag) {
    String key = inventory!.lpn!;
    if (!groupItemFlag) {
      key += "-" + inventory!.item!.name!;
    }
    if (!groupInventoryStatusFlag) {
      key += "-" + inventory!.inventoryStatus!.name!;
    }
    return key;
  }

  // Get the next deposit request from a list of inventory
  static InventoryDepositRequest? getNextInventoryDepositRequest(
      List<Inventory> inventories, bool groupItemFlag, 
      bool groupInventoryStatusFlag
  ) {

    printLongLogMessage("getNextInventoryDepositRequest with inventory list ");
    inventories.forEach((element) {
      printLongLogMessage(element.toJson().toString());
    });

    if (inventories.isEmpty) {
      printLongLogMessage("no inventory to be deposit");
      return null;
    }

    // let's get the
    InventoryDepositRequest inventoryDepositRequest = new InventoryDepositRequest();
    inventories.forEach((inventory) {
      if (inventoryDepositRequest.lpn?.isEmpty == true) {
        // OK, this is the first inventory we can check.
        // let's assign to the inventory deposit request
        printLongLogMessage("get the first inventory in the list, init the inventory request by the inventory");
        inventoryDepositRequest = InventoryDepositRequest.fromInventory(inventory);
      }
      else {
        // check if we can add the inventory to the current
        // deposit request
        printLongLogMessage("see if we can add the current inventory into the existing request");
        _addInventoryToDepositRequest(
                inventoryDepositRequest, inventory,
            groupItemFlag, groupInventoryStatusFlag);

      }
    });
    printLongLogMessage("we got inventoryDepositRequest: $inventoryDepositRequest");
    return inventoryDepositRequest;
  }
 

  // Add new inventory into current deposit request
  static void _addInventoryToDepositRequest(
      InventoryDepositRequest inventoryDepositRequest,
      Inventory inventory,
      bool groupItemFlag, bool groupInventoryStatusFlag) {

    // make sure we deposit LPN by LPN
    if (inventoryDepositRequest.lpn !=
        inventory.lpn) {
      return;
    }
    // make sure the inventory goes to the same destination
    if (inventoryDepositRequest.nextLocationId == null &&
        inventory.getNextDepositLocaiton() != null) {
      return ;
    }
    else if (inventoryDepositRequest.nextLocationId != null &&
        inventory.getNextDepositLocaiton() == null) {
      return ;
    }
    else if (inventoryDepositRequest.nextLocationId != null &&
              inventory.getNextDepositLocaiton() != null &&
              inventoryDepositRequest.nextLocationId !=
                  inventory.getNextDepositLocaiton()?.id) {
      return;
    }

    // now we know we can probably combine this inventory into
    // deposit request

    // check if we can group item or inventory status
    // and deposit together
    if (inventoryDepositRequest.itemName !=
        inventory.item?.name) {
      if (!groupItemFlag) {

        return;
      }
    }

    if (inventoryDepositRequest.inventoryStatusName !=
          inventory.inventoryStatus?.name) {
      if (!groupInventoryStatusFlag) {
        return;
      }
    }
    inventoryDepositRequest.addInventory(inventory);

  }


  // move inventory
  static Future<List<Inventory>> moveInventory  (
      {int? inventoryId, int? pickId, bool immediateMove = true,
        String destinationLpn = "", WarehouseLocation? destinationLocation,
        String lpn = "",
        String itemName = "", int? quantity, String unitOfMeasure = ""}) async {
    Map<String, dynamic> queryParameters = new Map<String, dynamic>();

    queryParameters["warehouseId"] = Global.currentWarehouse!.id;

    if (inventoryId != null) {
      queryParameters["inventoryId"] = inventoryId;
    }
    if (pickId != null) {
      queryParameters["pickId"] = pickId;
    }
    if (itemName.isNotEmpty) {
      queryParameters["itemName"] = itemName;
    }
    if (lpn.isNotEmpty) {
      queryParameters["lpn"] = lpn;
    }
    if (quantity != null && quantity > 0) {
      queryParameters["quantity"] = quantity;
    }
    if (unitOfMeasure.isNotEmpty) {
      queryParameters["unitOfMeasure"] = unitOfMeasure;
    }
    queryParameters["immediateMove"] = immediateMove;
    if (destinationLpn.isNotEmpty) {
      queryParameters["destinationLpn"] = destinationLpn;
    }

    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage("start to move inventory to location");
    if (destinationLocation != null) {

      printLongLogMessage(destinationLocation!.toJson().toString());
    }

    Response response = await httpClient.post(
        "/inventory/inventory/move",
        queryParameters: queryParameters,
        data: jsonEncode(destinationLocation)
    );


    Map<String, dynamic> responseString = json.decode(response.toString());


    if (responseString["result"] as int != 0) {
      printLongLogMessage("moveInventory / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


    List<Inventory> inventories
      = (responseString["data"] as List).map((e) => Inventory.fromJson(e as Map<String, dynamic>))
          .toList();


    return inventories;


    // return the moved inventory
    // return Inventory.fromJson(json.decode(response.toString()));
  }

  static Future<Inventory> getInventoryById(int inventoryId) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "inventory/inventory/$inventoryId",
        queryParameters: {"warehouseId": Global.currentWarehouse!.id}
    );

    // printLongLogMessage("response from receipt: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());


    if (responseString["result"] as int != 0) {
      printLongLogMessage("getInventoryById / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return Inventory.fromJson(responseString["data"]);

  }


  static Future<List<Inventory>> findInventory(
      {String locationName = "", String itemName = "", String lpn = "", bool includeDetails = true}
      )  async {

    printLongLogMessage("will find inventory by lpn $lpn");
    Dio httpClient = CWMSHttpClient.getDio();


    Map<String, dynamic> queryParameters = new Map<String, dynamic>();

    queryParameters["warehouseId"] = Global.currentWarehouse!.id;

    if (locationName.isNotEmpty) {
      queryParameters["location"] = locationName;
    }
    if (itemName.isNotEmpty) {
      queryParameters["itemName"] = itemName;
    }
    if (lpn.isNotEmpty) {
      queryParameters["lpn"] = lpn;
    }
    queryParameters["includeDetails"] = includeDetails;

    Response response = await httpClient.get(
          "/inventory/inventories",
          queryParameters: queryParameters
      );

      Map<String, dynamic> responseString = json.decode(response.toString());
    printLongLogMessage("get response from findInventory ${response.toString()}");

    if (responseString["result"] as int != 0) {
      printLongLogMessage("findInventory / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

      List<Inventory> inventories
        = (responseString["data"] as List).map((e) => Inventory.fromJson(e as Map<String, dynamic>))
            .toList();


      return inventories;
  }


  static Future<void> printLPNLabel(String lpn, [String? findPrinterByValue]) async {
    printLongLogMessage("Start calling printLPNLabel with lpn $lpn");
    // get the printer for printing LPN
    String printerName = "";

    if (Global.getLastLoginRF() != null && Global.getLastLoginRF().printerName != null &&
        Global.getLastLoginRF().printerName?.isNotEmpty == true) {
      printerName = Global.getLastLoginRF().printerName!;
    }
    else if (Global.getRFConfiguration.printerName  != null &&
        Global.getRFConfiguration.printerName!.isNotEmpty)  {
      // if the RF doesn't have the default printer, then check if we can get one from the RF configuration
      printerName = Global.getRFConfiguration.printerName!;
    }

    Dio httpClient = CWMSHttpClient.getDio();

    Map<String, dynamic> queryParameters = new Map<String, dynamic>();
    queryParameters["warehouseId"] = Global.currentWarehouse!.id;
    if (printerName.isNotEmpty) {

      queryParameters["printerName"] = printerName;
    }

    Response response = await httpClient.post(
        "/inventory/inventories/${Global.lastLoginCompanyId}/$lpn/lpn-label",
      queryParameters: queryParameters
    );

    printLongLogMessage("get response from printLPNLabel ${response.toString()}");

    // printLongLogMessage("response from receipt: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());


    if (responseString["result"] as int != 0) {
      printLongLogMessage("printLPNLabel / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    ReportHistory reportHistory = ReportHistory.fromJson(responseString["data"]);

    printLongLogMessage("start printing inventory LPN Label with file: ${reportHistory.fileName}, findPrinterBy: $findPrinterByValue");

    await PrintingService.printFile(reportHistory, printerName);
  }

  static Future<Inventory> addInventory(Inventory inventory,
      {String? documentNumber, String? comment}) async {
    /***
     *
     *
        printLongLogMessage("Start calling add inventory");

        Dio httpClient = CWMSHttpClient.getDio();
        Map<String, dynamic> params = new HashMap();
        if (documentNumber != null) {
        params["documentNumber"] = documentNumber;
        }
        if (comment != null) {
        params["comment"] = comment;
        }

        Response response = await httpClient.put(
        "inventory/inventory-adj?warehouseId=${Global.currentWarehouse!.id}",
        queryParameters:params,
        data: inventory
        );

        printLongLogMessage("get response from addInventory ${response.toString()}");

        Map<String, dynamic> responseString = json.decode(response.toString());
        if (responseString["result"] as int != 0) {
        printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
        throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
        }

        return Inventory.fromJson(responseString["data"] as Map<String, dynamic>);
     */

    printLongLogMessage("Start calling add inventory");

    Map<String, dynamic> params = new HashMap();
    if (documentNumber != null) {
      params["documentNumber"] = documentNumber;
    }
    if (comment != null) {
      params["comment"] = comment;
    }

    CWMSHttpResponse response = await Global.httpClient!.put(
        "inventory/inventory-adj?warehouseId=${Global.currentWarehouse!.id}",
        queryParameters:params,
        data: jsonEncode(inventory)
    );

    return Inventory.fromJson(response.data);

  }


  static Future<String> validateNewLpn(String lpn) async {
    /**
     *
        printLongLogMessage("start to validate new lpn ${lpn}");

        Dio httpClient = CWMSHttpClient.getDio();

        Response response = await httpClient.post(
        "/inventory/inventories/validate-new-lpn?warehouseId=${Global.currentWarehouse!.id}",
        queryParameters: {"lpn": lpn}
        );

        printLongLogMessage("get response from validateNewLpn ${response.toString()}");

        Map<String, dynamic> responseString = json.decode(response.toString());

        if (responseString["result"] as int != 0) {
        printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
        throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
        }
        return true;
     */

    printLongLogMessage("start to validate new lpn ${lpn}");


    CWMSHttpResponse? response = await Global.httpClient!.post(
        "/inventory/inventories/validate-new-lpn?warehouseId=${Global.currentWarehouse!.id}",
        queryParameters: {"lpn": lpn}
    );


    printLongLogMessage("validate LPN result: ${response?.data}");
    if (response?.data != null && response!.data.toString().isNotEmpty) {
      // return error message
      return response!.data.toString();
    }


    // return empty string if there's no error
    return "";



  }


  static Future<Inventory> allocateLocation(Inventory inventory) async {
    printLongLogMessage("start to allocate location for lpn ${inventory.lpn}");


    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "/inbound/putaway-configuration/allocate-location",

        data: jsonEncode(inventory)
    );

    //printLongLogMessage("get response from allocateLocation ${response.toString()}");


    Map<String, dynamic> responseString = json.decode(response.toString());
    if (responseString["result"] as int != 0) {
      printLongLogMessage("allocateLocation / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return Inventory.fromJson(responseString["data"] as Map<String, dynamic>);

  }

  static Future<ReportHistory> generateLPNLabel(Inventory inventory) async {
    printLongLogMessage("start to download LPN Label for lpn ${inventory.lpn}");


    Dio httpClient = CWMSHttpClient.getDio();

    // generate LPN Label
    // https://staging.claytechsuite.com/api/inventory/inventories/6/L0000000001/lpn-label?warehouseId=6
    // download PDF:
    // https://staging.claytechsuite.com/api/resource/report-histories/preview/4/6/LPN_LABEL/LPN_LABEL_1743551794620_0109.lbl?token=eyJhbGciOiJIUzI1NiJ9.eyJjb21wYW55SWQiOi0xLCJzdWIiOiJHWkhBTkciLCJpYXQiOjE3NDM1NTE0MzUsImV4cCI6MTc0MzU4NzQzNX0.l4xWVEA5dQSwhGUtVqAGEqFDQYsrMl784Y0N-rkUkJQ&companyId=4


    Response response = await httpClient.post(
        "/inventory/inventories/${Global.currentWarehouse!.id}/${inventory.lpn}/lpn-label",
        queryParameters: {'warehouseId': Global.currentWarehouse!.id},
    );

    // printLongLogMessage("get response from allocateLocation ${response.toString()}");


    Map<String, dynamic> responseString = json.decode(response.toString());
    if (responseString["result"] as int != 0) {
      printLongLogMessage("allocateLocation / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return ReportHistory.fromJson(responseString["data"] as Map<String, dynamic>);

  }

  // tryTime: we may need to wait for a while when print LPN labels
  // for work order producing or inbound receiving
  // as we may use asynchronously receiving for work order producing or inbound receiving
  static Future<void> autoPrintLPNLabelByLpn(BuildContext context, String lpn, {int tryTime = 10}) async {

    if (tryTime > 0) {

      InventoryService.findInventory(lpn : lpn, includeDetails: true)
          .then((inventoryList) {

        if (inventoryList != null && inventoryList.isNotEmpty) {

          autoPrintLPNLabel(context, inventoryList[0]);
        }
        else {
          Future.delayed(const Duration(milliseconds: 1000),
                  () => autoPrintLPNLabelByLpn(context, lpn, tryTime: tryTime - 1));
        }
      });
    }


  }

  static Future<void> autoPrintLPNLabel(BuildContext context, Inventory invenotry) async {


        InventoryService.generateLPNLabel(invenotry).then((reportHistory) {
          PrintingService.downloadFile(reportHistory).then((filePath) {
            /**
            FlutterBluetoothPrinter.selectDevice(context).then((device) {

                if (device != null){
                  /// do print
                  // controller?.print(address: device.address);
                  printLongLogMessage("we will print $filePath from printer ${device.address}");
                }
            });
                **/

            /*

            PrinterService.getDefaultBluetoothPrinter().then((defaultPrinter) {
              
                printLongLogMessage("get default printer: ${defaultPrinter.name}");
                printLongLogMessage("# address: ${defaultPrinter.address}");
                printLongLogMessage("# connected: ${defaultPrinter.connected}");


                BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
                bluetooth.isConnected.then((isConnected){
                    printLongLogMessage("> bluetooth.isConnected: ${isConnected}");


                    if (isConnected) {
                      bluetooth.printNewLine().then((value) => printLongLogMessage("first line is printed"));
                      bluetooth.printCustom("HEADER", 2, 1).then((value) => printLongLogMessage("head ier printed"));
                      bluetooth.printNewLine().then((value) => printLongLogMessage("seond line is printed"));
                      bluetooth
                          .paperCut().then((value) => printLongLogMessage("paper cut"));
                      printLongLogMessage("=== Printing is done  ====");
                    }
                });
            });
             */
 /*
            PrintingService.sendFileToPrinter(filePath).then((value) => {
              printLongLogMessage("$filePath is printed")
            });

  */
          });
        });

  }

  static Future<List<QCInspectionRequest>> getPendingQCInspectionRequest(Inventory inventory) async {

    printLongLogMessage("start to get qc inspection request for lpn ${inventory.lpn}");

    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/inventory/qc-inspection-requests/pending",
      queryParameters: {'warehouseId': Global.currentWarehouse!.id,
        'inventoryId': inventory.id},
    );

    printLongLogMessage("get response from getPendingQCInspectionRequest ${response.toString()}");


    Map<String, dynamic> responseString = json.decode(response.toString());
    if (responseString["result"] as int != 0) {
      printLongLogMessage("getPendingQCInspectionRequest / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    List<QCInspectionRequest> qcInspectionRequests
      = (responseString["data"] as List).map((e) => QCInspectionRequest.fromJson(e as Map<String, dynamic>))
          .toList();


    return qcInspectionRequests;
  }


  static Future<Inventory> reverseReceivedInventory(int inventoryId,
      {bool reverseQCQuantity = false, bool allowReuseLPN = true}) async {

    // send the receiving request to the server
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.delete(
        "inventory/inventory/$inventoryId/reverse-receiving",
        queryParameters: {
          "reverseQCQuantity": reverseQCQuantity,
          "allowReuseLPN": allowReuseLPN,
          'warehouseId': Global.currentWarehouse!.id,
        }
    );

    // printLongLogMessage("response from receiving: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("reverseReceivedInventory / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return Inventory.fromJson(responseString["data"]);
  }


  static Future<List<Inventory>> findPickableInventory(
      int itemId,
      int inventoryStatusId,
      {String lpn = "", String color = "", String productSize = "",
        String style = "",String receiptNumber = "", int? locationId}
      )  async {

    printLongLogMessage("will find pickable inventory by ");
    printLongLogMessage("item id : $itemId");
    printLongLogMessage("inventory status id : $inventoryStatusId");
    printLongLogMessage("lpn : $lpn");
    printLongLogMessage("color : $color");
    printLongLogMessage("productSize : $productSize");
    printLongLogMessage("style : $style");
    printLongLogMessage("receiptNumber : $receiptNumber");
    printLongLogMessage("locationId : $locationId");


    Dio httpClient = CWMSHttpClient.getDio();
    Map<String, dynamic> queryParameters = new Map<String, dynamic>();

    queryParameters["warehouseId"] = Global.currentWarehouse!.id;

    queryParameters["itemId"] = itemId;
    queryParameters["inventoryStatusId"] = inventoryStatusId;
    queryParameters["warehouseId"] = Global.currentWarehouse!.id;

    if (lpn.isNotEmpty) {
      queryParameters["lpn"] = lpn;
    }
    if (color.isNotEmpty) {
      queryParameters["color"] = color;
    }
    if (productSize.isNotEmpty) {
      queryParameters["productSize"] = productSize;
    }
    if (style.isNotEmpty) {
      queryParameters["style"] = style;
    }
    if (receiptNumber.isNotEmpty) {
      queryParameters["receiptNumber"] = receiptNumber;
    }
    if (locationId != null) {
      queryParameters["locationId"] = locationId;
    }

    Response response = await httpClient.get(
        "/inventory/inventories/pickable",
        queryParameters: queryParameters
    );

    Map<String, dynamic> responseString = json.decode(response.toString());
    printLongLogMessage("get response from findPickableInventory ${response.toString()}");

    if (responseString["result"] as int != 0) {
      printLongLogMessage("findPickableInventory / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    List<Inventory> inventories
    = (responseString["data"] as List).map((e) => Inventory.fromJson(e as Map<String, dynamic>))
        .toList();


    return inventories;
  }



  static Future<Inventory> relabelInventory(
      int inventoryId, String newLPN, {bool mergeWithExistingInventory = true} )  async {



    Dio httpClient = CWMSHttpClient.getDio();
    Map<String, dynamic> queryParameters = new Map<String, dynamic>();

    queryParameters["warehouseId"] = Global.currentWarehouse!.id;

    queryParameters["newLPN"] = newLPN;
    queryParameters["mergeWithExistingInventory"] = mergeWithExistingInventory;

    Response response = await httpClient.post(
        "/inventory/inventories/${inventoryId}/relabel",
        queryParameters: queryParameters
    );

    Map<String, dynamic> responseString = json.decode(response.toString());
    printLongLogMessage("get response from relabelInventory ${response.toString()}");

    if (responseString["result"] as int != 0) {
      printLongLogMessage("relabelInventory / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


    return Inventory.fromJson(responseString["data"] as Map<String, dynamic>);
  }


  static Future<List<Inventory>> relabelInventories(
      String inventoryIds, String newLPN, {bool mergeWithExistingInventory = true} )  async {



    Dio httpClient = CWMSHttpClient.getDio();
    Map<String, dynamic> queryParameters = new Map<String, dynamic>();

    queryParameters["warehouseId"] = Global.currentWarehouse!.id;

    queryParameters["ids"] = inventoryIds;
    queryParameters["newLPN"] = newLPN;
    queryParameters["mergeWithExistingInventory"] = mergeWithExistingInventory;

    Response response = await httpClient.post(
        "/inventory/inventories/relabel",
        queryParameters: queryParameters
    );

    Map<String, dynamic> responseString = json.decode(response.toString());
    printLongLogMessage("get response from relabelInventories ${response.toString()}");


    if (responseString["result"] as int != 0) {
      printLongLogMessage("relabelInventories / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    List<Inventory> inventories
    = (responseString["data"] as List).map((e) => Inventory.fromJson(e as Map<String, dynamic>))
          .toList();


    return inventories;
  }


  static Future<List<QCInspectionRequest>> getManualQCInspectionRequest(Inventory inventory) async {

    printLongLogMessage("start to get manual qc inspection request for lpn ${inventory.lpn}");

    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
      "/inventory/inventories/qc-inspection-requests/manual",
      queryParameters: {'warehouseId': Global.currentWarehouse!.id,
        'inventoryId': inventory.id},
    );

    printLongLogMessage("get response from getPendingQCInspectionRequest ${response.toString()}");


    Map<String, dynamic> responseString = json.decode(response.toString());
    if (responseString["result"] as int != 0) {
      printLongLogMessage("getPendingQCInspectionRequest / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    List<QCInspectionRequest> qcInspectionRequests
    = (responseString["data"] as List).map((e) => QCInspectionRequest.fromJson(e as Map<String, dynamic>))
        .toList();


    return qcInspectionRequests;
  }

  static Future<Inventory> removeInventory( int inventoryId )  async {



    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.delete(
        "/inventory/inventory/${inventoryId}",
    );

    Map<String, dynamic> responseString = json.decode(response.toString());
    printLongLogMessage("get response from removeInventory ${response.toString()}");

    if (responseString["result"] as int != 0) {
      printLongLogMessage("removeInventory / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


    return Inventory.fromJson(responseString["data"] as Map<String, dynamic>);
  }

  static Future<Inventory> changeQuantity( int inventoryId , int newQuantity)  async {

    Dio httpClient = CWMSHttpClient.getDio();


    Response response = await httpClient.post(
      "/inventory/inventory/${inventoryId}/adjust-quantity",
      queryParameters: {'newQuantity': newQuantity},
    );

    Map<String, dynamic> responseString = json.decode(response.toString());
    printLongLogMessage("get response from changeQuantity ${response.toString()}");

    if (responseString["result"] as int != 0) {
      printLongLogMessage("removeInventory / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


    return Inventory.fromJson(responseString["data"] as Map<String, dynamic>);
  }


  static InventoryQuantityForDisplay getInventoryQuantityForDisplay(Inventory inventory) {
    // first of all, let's get the display UOM
    // if there're multiple defined, let's get the biggest one
    List<ItemUnitOfMeasure> displayItemUnitOfMeasures =
        inventory.itemPackageType?.itemUnitOfMeasures
            .where((itemUnitOfMeasure) =>
                itemUnitOfMeasure.defaultForDisplay == true &&
                inventory.quantity! % itemUnitOfMeasure.quantity! == 0).toList() ?? [];

    ItemUnitOfMeasure? biggestDisplayItemUnitOfMeasure = getBiggestItemUnitOfMeasure(displayItemUnitOfMeasures);

    // let's get the display UOM, let's return the biggest one
    if (biggestDisplayItemUnitOfMeasure != null) {
      return new InventoryQuantityForDisplay(inventory,
          biggestDisplayItemUnitOfMeasure, (inventory.quantity! / biggestDisplayItemUnitOfMeasure.quantity!).round());
    }

    // there's no UOM setup for display, let's return the biggest unit of measure that
    // can be divided evenly by the inventory's quantity

    List<ItemUnitOfMeasure> itemUnitOfMeasures =
        inventory.itemPackageType?.itemUnitOfMeasures
            .where((itemUnitOfMeasure) =>
            inventory.quantity! % itemUnitOfMeasure.quantity! == 0).toList() ?? [];

    ItemUnitOfMeasure? biggestItemUnitOfMeasure = getBiggestItemUnitOfMeasure(itemUnitOfMeasures);

    // let's get the display UOM, let's return the biggest one
      return new InventoryQuantityForDisplay(inventory,
          biggestItemUnitOfMeasure!, (inventory.quantity! / biggestItemUnitOfMeasure.quantity!).round());

  }

  // get the biggest item unit of measures from a list of item unit of measures
  // we will compare the quantity first, if the quantities are the same for 2 UOM
  // then we compare the size;
  static ItemUnitOfMeasure? getBiggestItemUnitOfMeasure(List<ItemUnitOfMeasure> itemUnitOfMeasures) {
    if (itemUnitOfMeasures.length == 0) {
      return null;
    }

    itemUnitOfMeasures..sort((a, b)  {
      if (a.quantity! != b.quantity!) {
        return b.quantity!.compareTo(a.quantity!);
      }
      else if (a.length != b.length){
        return b.length!.compareTo(a.length!);

      }
      else if (a.width != b.width){
        return b.width!.compareTo(a.width!);

      }
      else if (a.height != b.height){
        return b.height!.compareTo(a.height!);

      }
      else if (a.weight != b.weight){
        return b.weight!.compareTo(a.weight!);
      }
      return 1;
    });

    return itemUnitOfMeasures.first;

  }

  static Future<Inventory> changeInventory(Inventory inventory)  async {

    Dio httpClient = CWMSHttpClient.getDio();


    Response response = await httpClient.put(
      "/inventory/inventory/${inventory.id}",
        data: jsonEncode(inventory)
    );

    Map<String, dynamic> responseString = json.decode(response.toString());
    printLongLogMessage("get response from changeInventory ${response.toString()}");

    if (responseString["result"] as int != 0) {
      printLongLogMessage("changeInventory / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


    return Inventory.fromJson(responseString["data"] as Map<String, dynamic>);
  }

}