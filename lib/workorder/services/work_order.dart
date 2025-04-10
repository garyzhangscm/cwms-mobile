
import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
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
  static Future<WorkOrder?> getWorkOrderByNumber(String workOrderNumber, {loadDetails : true}) async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage("Start to get work order by ${workOrderNumber}");
    Response response = await httpClient.get(
        "workorder/work-orders",
        queryParameters: {"number": workOrderNumber,
          "loadDetails" : loadDetails,
          "warehouseId": Global.currentWarehouse!.id}
    );

    printLongLogMessage("response from getWorkOrderByNumber: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    List<WorkOrder> workOrders
    = (responseString["data"] as List).map((e) => WorkOrder.fromJson(e as Map<String, dynamic>))
        .toList();

    // Sort the picks according to the current location. We
    // will assign the closed pick to the user
    if (workOrders.length > 0) {
      return workOrders.first;
    }
    else {
      return null;
    }

  }

  static Future<WorkOrder> getWorkOrderById(int workOrderId) async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage("Start to get work order by id ${workOrderId}");
    Response response = await httpClient.get(
        "workorder/work-orders/${workOrderId}",
    );

    // printLongLogMessage("response from getWorkOrderById: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    return WorkOrder.fromJson(responseString["data"] as Map<String, dynamic>) ;

  }


  // Get available Work Orders
  // 1. with open picks
  // 2. no
  static Future<List<WorkOrder>> getAvailableWorkOrdersWithPick() async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "workorder/work-orders-with-open-pick",
        queryParameters: {"warehouseId": Global.currentWarehouse!.id}
    );

    // print("response from Order: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    // List<dynamic> responseData = responseString["data"];

    List<WorkOrder> workOrders
    = (responseString["data"] as List).map((e) =>  WorkOrder.fromJson(e as Map<String, dynamic>))
          .toList();

    print("get ${workOrders.length} work orders");

    setupStatisticQuantityForWorkOrders(workOrders);


    return workOrders;

  }

  static Future<void> saveWorkOrderProduceTransaction(
          WorkOrderProduceTransaction workOrderProduceTransaction
  ) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "workorder/work-order-produce-transactions",
       data: jsonEncode(workOrderProduceTransaction)
    );

    // printLongLogMessage("response from saveWorkOrderProduceTransaction: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    // List<dynamic> responseData = responseString["data"];
    if (responseString["result"] as int != 0) {
      printLongLogMessage("saveWorkOrderProduceTransaction / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


  }

  static void setupStatisticQuantityForWorkOrders(List<WorkOrder> workOrders) {
    workOrders.forEach((workOrder) { setupStatisticQuantityForWorkOrder(workOrder); });

  }
  static void setupStatisticQuantityForWorkOrder(WorkOrder workOrder) {

    workOrder.totalLineExpectedQuantity = 0;
    workOrder.totalLineOpenQuantity = 0;
    workOrder.totalLineInprocessQuantity = 0;
    workOrder.totalLineDeliveredQuantity = 0;
    workOrder.totalLineConsumedQuantity = 0;

    workOrder.workOrderLines.forEach((workOrderLine)  {
      workOrder.totalLineExpectedQuantity = workOrder.totalLineExpectedQuantity! + workOrderLine.expectedQuantity!;
      workOrder.totalLineOpenQuantity = workOrder.totalLineOpenQuantity! + workOrderLine.openQuantity!;
      workOrder.totalLineInprocessQuantity = workOrder.totalLineInprocessQuantity! + workOrderLine.inprocessQuantity!;
      workOrder.totalLineDeliveredQuantity = workOrder.totalLineDeliveredQuantity! + workOrderLine.deliveredQuantity!;
      workOrder.totalLineConsumedQuantity = workOrder.totalLineConsumedQuantity! + workOrderLine.consumedQuantity!;
    });


  }


  static Future<List<Pick>> generateManualPick(
      int workOrderId, String lpn, int productionLineId, bool pickWholeLPN
      ) async {
    Dio httpClient = CWMSHttpClient.getDio();
    printLongLogMessage("start to generate manual pick for lpn ${lpn}");

    Response response = await httpClient.post(
        "workorder/work-orders/${workOrderId}/generate-manual-pick",
        queryParameters: {"warehouseId": Global.currentWarehouse!.id,
          "lpn": lpn,
          "productionLineId": productionLineId,
          "rfCode":Global.getLastLoginRFCode(),
        "pickWholeLPN": pickWholeLPN}
    );

    printLongLogMessage("response from generateManualPick: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    // List<dynamic> responseData = responseString["data"];
    if (responseString["result"] as int != 0) {
      printLongLogMessage("generateManualPick / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    List<Pick> picks
    = (responseString["data"] as List).map((e) => Pick.fromJson(e as Map<String, dynamic>))
        .toList();

    print("get ${picks.length} picks by manual picking for work order $workOrderId, lpn: $lpn");

    return picks;

  }
  static Future<List<Pick>> processManualPick(
      int workOrderId, String lpn, int productionLineId
      ) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "workorder/work-orders/${workOrderId}/process-manual-pick",
        queryParameters: {"warehouseId": Global.currentWarehouse!.id,
          "lpn": lpn, "productionLineId": productionLineId, "rfCode":Global.getLastLoginRFCode()}
    );

    // printLongLogMessage("response from saveWorkOrderProduceTransaction: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    // List<dynamic> responseData = responseString["data"];
    if (responseString["result"] as int != 0) {
      printLongLogMessage("processManualPick / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    List<Pick> picks
    = (responseString["data"] as List).map((e) => Pick.fromJson(e as Map<String, dynamic>))
        .toList();

    print("get ${picks.length} picks by manual picking for work order $workOrderId, lpn: $lpn");

    return picks;

  }


  static Future<int> getPickableQuantityForManualPick(
      int workOrderId, String lpn, int productionLineId
      ) async {
    printLongLogMessage("start to get pickable quantity for manual pick of work order id $workOrderId "
        "from LPN $lpn , into production line with id $productionLineId");

    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "workorder/work-orders/${workOrderId}/get-manual-pick-quantity",
        queryParameters: {"warehouseId": Global.currentWarehouse!.id,
          "lpn": lpn, "productionLineId": productionLineId, "rfCode":Global.getLastLoginRFCode()}
    );

    printLongLogMessage("response from getPickableQuantityForManualPick: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    // List<dynamic> responseData = responseString["data"];
    if (responseString["result"] as int != 0) {
      printLongLogMessage("getPickableQuantityForManualPick / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    int pickableQuantity
    = (responseString["data"] as int);


    return pickableQuantity;

  }


  static Future<WorkOrder> reverseProduction(int workOrderId, String lpn) async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage("Start to reverse work order by id ${workOrderId}");
    Response response = await httpClient.post(
      "workorder/work-orders/${workOrderId}/reverse-production",
        queryParameters: {
          "warehouseId": Global.currentWarehouse!.id,
          "lpn": lpn,
          "rfCode":Global.getLastLoginRFCode()}

    );

    Map<String, dynamic> responseString = json.decode(response.toString());
    // List<dynamic> responseData = responseString["data"];
    if (responseString["result"] as int != 0) {
      printLongLogMessage("reverseProduction / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return WorkOrder.fromJson(responseString["data"] as Map<String, dynamic>) ;



  }
}




