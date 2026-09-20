
import 'dart:convert';


import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:dio/dio.dart';

import '../models/inventory_configuration.dart';


class InventoryConfigurationService {
  // Get inventory that on the current RF
  static Future<InventoryConfiguration?> getInventoryConfiguration() async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "inventory/inventory_configuration",
      queryParameters: {
          "warehouseId": Global.currentWarehouse!.id,
        "companyId": Global.lastLoginCompanyId}
    );


    // printLongLogMessage("response from receipt: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());


    if (responseString["result"] as int != 0) {
      printLongLogMessage("getInventoryConfiguration / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    if (responseString["data"] == null) {
      return null;
    }
    return InventoryConfiguration.fromJson(responseString["data"]);
  }

}