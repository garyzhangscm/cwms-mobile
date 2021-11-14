
import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_produce_transaction.dart';
import 'package:dio/dio.dart';

class ProductionLineAssignmentService {
  static Future<ProductionLineAssignment> getProductionLineAssignmentByProductionLine(ProductionLine productionLine) async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage("start to get assignment by productionLineId: ${productionLine.id}");
    Response response = await httpClient.get(
        "workorder/production-line-assignments",
        queryParameters: {"productionLineId": productionLine.id}
    );

    printLongLogMessage("response from getProductionLineAssignmentByProductionLine: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["message"]);
    }
    List<ProductionLineAssignment> productionLineAssignments
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : ProductionLineAssignment.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // Sort the picks according to the current location. We
    // will assign the closed pick to the user
    if (productionLineAssignments.length > 0) {
      return productionLineAssignments.first;
    }
    else {
      return null;
    }

  }

  static Future<ProductionLineAssignment> getProductionLineAssignmentByProductionLineName(String productionLineName) async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage("start to get assignment by productionLineNumber: ${productionLineName}");
    Response response = await httpClient.get(
        "workorder/production-line-assignments",
        queryParameters: {"productionLineNames": productionLineName}
    );

    printLongLogMessage("response from getProductionLineAssignmentByProductionLineName: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["message"]);
    }
    List<ProductionLineAssignment> productionLineAssignments
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : ProductionLineAssignment.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // Sort the picks according to the current location. We
    // will assign the closed pick to the user
    if (productionLineAssignments.length > 0) {
      return productionLineAssignments.first;
    }
    else {
      return null;
    }

  }



  static Future<List<WorkOrder>> getAssignedWorkOrderByProductionLine(
      ProductionLine productionLine) async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage("start to get assigned work order by productionLineId: ${productionLine.id}");
    Response response = await httpClient.get(
        "workorder/production-line-assignments/assigned-work-orders",
        queryParameters: {"productionLineId": productionLine.id}
    );

    printLongLogMessage("response from getAssignedWorkOrderByProductionLine: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["message"]);
    }
    List<WorkOrder> workOrders
      = (responseString["data"] as List)?.map((e) =>
      e == null ? null : WorkOrder.fromJson(e as Map<String, dynamic>))
          ?.toList();

    return workOrders;


  }
}




