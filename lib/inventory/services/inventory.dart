
import 'dart:collection';
import 'dart:convert';


import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InventoryService {
  // Get inventory that on the current RF
  static Future<List<Inventory>> getInventoryOnCurrentRF() async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage("will get inventory on ${Global.getLastLoginRFCode()}");
    Response response = await httpClient.get(
        "/inventory/inventories",
      queryParameters: {'warehouseId': Global.lastLoginCompanyId,
          'location': Global.getLastLoginRFCode()}
    );

    printLongLogMessage("response from inventory on RF:");

    // printLongLogMessage(response.toString());

    Map<String, dynamic> responseString = json.decode(response.toString());

    List<Inventory> inventories
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : Inventory.fromJson(e as Map<String, dynamic>))
        ?.toList();


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
            inventoryDepositRequestMap[key];
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
    String key = inventory.lpn;
    if (!groupItemFlag) {
      key += "-" + inventory.item.name;
    }
    if (!groupInventoryStatusFlag) {
      key += "-" + inventory.inventoryStatus.name;
    }
    return key;
  }

  // Get the next deposit request from a list of inventory
  static InventoryDepositRequest getNextInventoryDepositRequest(
      List<Inventory> inventories, bool groupItemFlag, 
      bool groupInventoryStatusFlag
  ) {

    if (inventories.isEmpty) {
      printLongLogMessage("no inventory to be deposit");
      return null;
    }

    // let's get the
    InventoryDepositRequest inventoryDepositRequest = new InventoryDepositRequest();
    inventories.forEach((inventory) {
      if (inventoryDepositRequest.lpn.isEmpty) {
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
                  inventory.getNextDepositLocaiton().id) {
      return;
    }

    // now we know we can probably combine this inventory into
    // deposit request

    // check if we can group item or inventory status
    // and deposit together
    if (inventoryDepositRequest.itemName !=
        inventory.item.name) {
      if (!groupItemFlag) {

        return;
      }
    }

    if (inventoryDepositRequest.inventoryStatusName !=
          inventory.inventoryStatus.name) {
      if (!groupInventoryStatusFlag) {
        return;
      }
    }
    inventoryDepositRequest.addInventory(inventory);

  }

  // move inventory
  static Future<Inventory> moveInventory  (
      {int inventoryId, int pickId, bool immediateMove = true,
        String destinationLpn = "", WarehouseLocation destinationLocation}) async {
    Map<String, dynamic> queryParameters = new Map<String, dynamic>();
    if (pickId != null) {
      queryParameters["pickId"] = pickId;
    }
    queryParameters["immediateMove"] = immediateMove;
    if (destinationLpn.isNotEmpty) {
      queryParameters["destinationLpn"] = destinationLpn;
    }

    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "/inventory/inventory/$inventoryId/move",
        queryParameters: queryParameters,
        data: destinationLocation
    );

    printLongLogMessage("response from move inventory:");

    printLongLogMessage(response.toString());

    // return the moved inventory
    return Inventory.fromJson(json.decode(response.toString()));
  }


  static Future<List<Inventory>> findInventory(
      {String locationName = "", String itemName = "", String lpn = "", bool includeDetails = true}
      )  async {

    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
          "/inventory/inventories",
          queryParameters: {'warehouseId': Global.lastLoginCompanyId,
            'location': locationName,
            'lpn': lpn,
            'itemName': itemName,
          'includeDetails': includeDetails}
      );

      Map<String, dynamic> responseString = json.decode(response.toString());

      List<Inventory> inventories
        = (responseString["data"] as List)?.map((e) =>
        e == null ? null : Inventory.fromJson(e as Map<String, dynamic>))
            ?.toList();


      return inventories;
  }


  static Future<void> printLPNLabel(String lpn, String findPrinterByValue) async {
    printLongLogMessage("Start calling printLPNLabel with lpn $lpn");

    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "/inventory/inventories/${Global.lastLoginCompanyId}/$lpn/lpn-label/ecotech"
    );

    printLongLogMessage("get response from printLPNLabel ${response.toString()}");

    Map<String, dynamic> responseString = json.decode(response.toString());

    Map<String, dynamic> reportHistory = responseString["data"] as Map<String, dynamic>;
    String fileName = reportHistory["fileName"];
    printLongLogMessage("start sending printing request with file: $fileName, findPrinterBy: $findPrinterByValue");

    response = await httpClient.post(
        "/resource/report-histories/print/${Global.lastLoginCompanyId}/${Global.currentWarehouse.id}/LPN_REPORT/$fileName",
        queryParameters: {'warehouseId': Global.lastLoginCompanyId,
           'findPrinterBy': findPrinterByValue}
    );

    printLongLogMessage("get response from LPN Printing request ${response.toString()}");

  }

  static Future<Inventory> addInventory(Inventory inventory,
      {String documentNumber, String comment}) async {
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
        "inventory/inventory-adj?warehouseId=${Global.currentWarehouse.id}",
        queryParameters:params,
        data: inventory
    );

    printLongLogMessage("get response from addInventory ${response.toString()}");

    Map<String, dynamic> responseString = json.decode(response.toString());
    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["message"]);
    }

    return Inventory.fromJson(responseString["data"] as Map<String, dynamic>);




  }


  static Future<bool> validateNewLpn(String lpn) async {
    printLongLogMessage("start to validate new lpn ${lpn}");

    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "/inventory/inventories/validate-new-lpn?warehouseId=${Global.currentWarehouse.id}",
        queryParameters: {"lpn": lpn}
    );

    printLongLogMessage("get response from validateNewLpn ${response.toString()}");

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["message"]);
    }
    return true;



  }

}