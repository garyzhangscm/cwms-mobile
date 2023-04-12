
import 'dart:convert';


import 'package:cwms_mobile/inventory/models/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/cwms_http_response.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:dio/dio.dart';

import '../../exception/WebAPICallException.dart';

class InventoryStatusService {
  // Get all cycle count requests by batch id
  static Future<List<InventoryStatus>> getAllInventoryStatus() async {
    /***
     *
        Dio httpClient = CWMSHttpClient.getDio();

        Response response = await httpClient.get(
        "/inventory/inventory-statuses",
        queryParameters: {'warehouseId': Global.lastLoginCompanyId}
        );

        printLongLogMessage("response from getAllInventoryStatus");

        printLongLogMessage(response.toString());

        Map<String, dynamic> responseString = json.decode(response.toString());

        List<InventoryStatus> inventoryStatuses
        = (responseString["data"] as List)?.map((e) =>
        e == null ? null : InventoryStatus.fromJson(e as Map<String, dynamic>))
        ?.toList();



        return inventoryStatuses;
     */

    CWMSHttpResponse response = await Global.httpClient.get(
        "/inventory/inventory-statuses",
        queryParameters: {'warehouseId': Global.currentWarehouse.id}
    );

    // printLongLogMessage("response from getAllInventoryStatus");


    List<InventoryStatus> inventoryStatuses
      = (response.data as List)?.map((e) =>
      e == null ? null : InventoryStatus.fromJson(e as Map<String, dynamic>))
          ?.toList();



    return inventoryStatuses;
  }


  static Future<InventoryStatus> getInventoryStatusByName(String name) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/inventory/inventory-statuses",
        queryParameters: {'warehouseId': Global.currentWarehouse.id,
          'name': name}
    );

    // printLongLogMessage("response from inventory status by name $name");

    printLongLogMessage(response.toString());

    Map<String, dynamic> responseString = json.decode(response.toString());

    List<InventoryStatus> inventoryStatuses
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : InventoryStatus.fromJson(e as Map<String, dynamic>))
          ?.toList();
    printLongLogMessage("items.length: ${inventoryStatuses.length}");

    if (inventoryStatuses.length == 1) {
      return inventoryStatuses[0];
    }
    else {
      return null;
    }
  }


  static Future<InventoryStatus> getAvaiableInventoryStatus() async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/inventory/inventory-statuses/available",
        queryParameters: {'warehouseId': Global.currentWarehouse.id}
    );

    // printLongLogMessage("response from getAvaiableInventoryStatus: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());


    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    if (responseString["data"] == null) {
      return null;
    }
    return InventoryStatus.fromJson(responseString["data"]);
  }

}