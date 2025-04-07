
import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/rf_configuration.dart';
import 'package:dio/dio.dart';

import '../models/warehouse_configuration.dart';

class WarehouseConfigurationService {

  static Future<WarehouseConfiguration?> getWarehouseConfiguration() async {

    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        Global.currentServer.url! + "/layout/warehouse-configuration/by-warehouse/${Global.currentWarehouse.id}",
        queryParameters: {"warehouseId": Global.currentWarehouse.id}
    );

    // print("response from getRFConfiguration: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("getWarehouseConfiguration / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }
    Map<String, dynamic> responseData = responseString["data"] as Map<String, dynamic>;
    if (responseData == null || responseData.isEmpty) {
      return null;
    }
    return WarehouseConfiguration.fromJson(responseData);

  }




}




