
import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_produce_transaction.dart';
import 'package:dio/dio.dart';

class ProductionLineService {
  // Get all cycle count requests by batch id
  static Future<ProductionLine> getProductionLineByNumber(String productionLineName) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "workorder/production-lines",
        queryParameters: {"name": productionLineName,
          "warehouseId": Global.currentWarehouse.id}
    );

    printLongLogMessage("response from getProductionLineByNumber: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["message"]);
    }
    List<ProductionLine> productionLines
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : ProductionLine.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // Sort the picks according to the current location. We
    // will assign the closed pick to the user
    if (productionLines.length > 0) {
      return productionLines.first;
    }
    else {
      return null;
    }

  }


}




