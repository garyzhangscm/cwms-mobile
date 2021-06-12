
import 'dart:convert';


import 'package:cwms_mobile/inventory/models/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:dio/dio.dart';

class InventoryStatusService {
  // Get all cycle count requests by batch id
  static Future<List<InventoryStatus>> getAllInventoryStatus() async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/inventory/inventory-statuses",
      queryParameters: {'warehouseId': Global.lastLoginCompanyId}
    );

    printLongLogMessage("response from inventory on RF:");

    printLongLogMessage(response.toString());

    Map<String, dynamic> responseString = json.decode(response.toString());

    List<InventoryStatus> inventoryStatuses
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : InventoryStatus.fromJson(e as Map<String, dynamic>))
        ?.toList();



    return inventoryStatuses;
  }


  static Future<InventoryStatus> getInventoryStatusByName(String name) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/inventory/inventory-statuses",
        queryParameters: {'warehouseId': Global.lastLoginCompanyId,
          'name': name}
    );

    printLongLogMessage("response from inventory status by name $name");

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



}