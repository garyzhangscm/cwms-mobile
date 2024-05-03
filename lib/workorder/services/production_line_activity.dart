
import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/production_line_activity.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_produce_transaction.dart';
import 'package:dio/dio.dart';

class ProductionLineActivityService {
  // Get all cycle count requests by batch id
  static Future<ProductionLineActivity> saveCheckInProductionLineActivity(
      ProductionLineActivity productionLineActivity
      ) async {

    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "workorder/production-line-activities/check_in",
        queryParameters: {
          "warehouseId": productionLineActivity.warehouseId,
          "workOrderId": productionLineActivity.workOrder.id,
          "productionLineId": productionLineActivity.productionLine.id,
          "username": productionLineActivity.username,
          "workingTeamMemberCount": productionLineActivity.workingTeamMemberCount}
    );

    // print("response from saveCheckInProductionLineActivity: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("saveCheckInProductionLineActivity / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return ProductionLineActivity.fromJson(responseString["data"] as Map<String, dynamic>);



  }

  static Future<ProductionLineActivity> saveCheckOutProductionLineActivity(
      ProductionLineActivity productionLineActivity
      ) async {

    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "workorder/production-line-activities/check_out",
        queryParameters: {
          "warehouseId": productionLineActivity.warehouseId,
          "workOrderId": productionLineActivity.workOrder.id,
          "productionLineId": productionLineActivity.productionLine.id,
          "username": productionLineActivity.username,
          "workingTeamMemberCount": productionLineActivity.workingTeamMemberCount}
    );

    // print("response from saveCheckInProductionLineActivity: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


    return ProductionLineActivity.fromJson(responseString["data"] as Map<String, dynamic>);



  }


}




