
import 'dart:convert';

import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_produce_transaction.dart';
import 'package:dio/dio.dart';

class WorkOrderService {
  // Get all cycle count requests by batch id
  static Future<WorkOrder> getWorkOrderByNumber(String workOrderNumber) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "workorder/work-orders",
        queryParameters: {"number": workOrderNumber,
          "warehouseId": Global.currentWarehouse.id}
    );

    print("response from Order: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    List<WorkOrder> workOrders
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : WorkOrder.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // Sort the picks according to the current location. We
    // will assign the closed pick to the user
    if (workOrders.length > 0) {
      return workOrders.first;
    }
    else {
      return null;
    }

  }


  // Get available Work Orders
  // 1. with open picks
  // 2. no
  static Future<List<WorkOrder>> getAvailableWorkOrdersWithPick() async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "workorder/work-orders-with-open-pick",
        queryParameters: {"warehouseId": Global.currentWarehouse.id}
    );

    // print("response from Order: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    // List<dynamic> responseData = responseString["data"];

    List<WorkOrder> workOrders
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : WorkOrder.fromJson(e as Map<String, dynamic>))
          ?.toList();

    print("get ${workOrders.length} work orders");

    return workOrders;

  }

  static Future<void> saveWorkOrderProduceTransaction(
          WorkOrderProduceTransaction workOrderProduceTransaction
  ) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "workorder/work-order-produce-transactions",
       data: workOrderProduceTransaction
    );

    printLongLogMessage("response from Order: $response");
    //Map<String, dynamic> responseString = json.decode(response.toString());
    // List<dynamic> responseData = responseString["data"];


  }

}




