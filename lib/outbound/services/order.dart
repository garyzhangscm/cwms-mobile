import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:dio/dio.dart';

class ManualPickAvailability {
  final Map<int, int> remainingByLine;
  final int remainingQuantity;
  ManualPickAvailability(this.remainingByLine, this.remainingQuantity);
}

class OrderService {
  static Future<ManualPickAvailability> getManualPickAvailability(
      int orderId) async {
    final response = await CWMSHttpClient.getDio().get(
      'outbound/orders/$orderId/manual-pick-availability',
      queryParameters: {'warehouseId': Global.currentWarehouse!.id},
    );
    final dynamic body =
        response.data is Map ? response.data : json.decode(response.toString());
    if (body['result'] != 0) {
      throw WebAPICallException(body['message']?.toString() ??
          'Could not refresh manual-pick quantities');
    }
    final data = body['data'];
    if (data is! Map ||
        data['orderId'] != orderId ||
        data['lines'] is! List ||
        data['remainingQuantity'] is! int) {
      throw WebAPICallException(
          'Invalid manual-pick quantities. Reload the order.');
    }
    final remaining = <int, int>{};
    for (final row in data['lines']) {
      if (row is! Map ||
          row['orderLineId'] is! int ||
          row['remainingQuantity'] is! int ||
          row['remainingQuantity'] < 0 ||
          remaining.containsKey(row['orderLineId'])) {
        throw WebAPICallException(
            'Invalid manual-pick quantities. Reload the order.');
      }
      remaining[row['orderLineId'] as int] = row['remainingQuantity'] as int;
    }
    final total = remaining.values.fold<int>(0, (sum, value) => sum + value);
    if (total != data['remainingQuantity'] || data['canPick'] != (total > 0)) {
      throw WebAPICallException(
          'Manual-pick quantities changed. Reload the order.');
    }
    return ManualPickAvailability(Map<int, int>.unmodifiable(remaining), total);
  }

  // Get all cycle count requests by batch id
  static Future<Order> getOrderByNumber(String orderNumber) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "outbound/orders",
        queryParameters: {"number": orderNumber,
          "warehouseId": Global.currentWarehouse!.id}
    );

    printLongLogMessage("response from Order: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("getOrderByNumber / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


    List<Order> orders
    = (responseString["data"] as List).map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();

    if (orders.length > 0) {
      return orders.first;
    }
    else {
      throw new WebAPICallException("can't find order by number ${orderNumber}");
    }

  }


  // Get available Orders
  // 1. with open picks
  // 2. no
  static Future<List<Order>> getAvailableOrdersWithPick() async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "outbound/orders-with-open-pick",
        queryParameters: {"warehouseId": Global.currentWarehouse!.id}
    );

    // print("response from Order: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    // List<dynamic> responseData = responseString["data"];

    List<Order> orders
    = (responseString["data"] as List).map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();

    print("get ${orders.length} orders");

    return orders;

  }


  static Future<int> getPickableQuantityForManualPick(
      int orderId, String lpn
      ) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "outbound/orders/${orderId}/get-manual-pick-quantity",
        queryParameters: {"warehouseId": Global.currentWarehouse!.id,
          "lpn": lpn,  "rfCode":Global.getLastLoginRFCode()}
    );

    // printLongLogMessage("response from getPickableQuantityForManualPick: $response");
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


  static Future<List<Pick>> generateManualPick(
      int orderId, String lpn, bool pickWholeLPN
      ) async {
    Dio httpClient = CWMSHttpClient.getDio();
    printLongLogMessage("start to generate manual pick for lpn ${lpn}");

    Response response = await httpClient.post(
        "outbound/orders/${orderId}/generate-manual-pick",
        queryParameters: {"warehouseId": Global.currentWarehouse!.id,
          "lpn": lpn,
          "rfCode":Global.getLastLoginRFCode(),
          "pickWholeLPN": pickWholeLPN}
    );

    // printLongLogMessage("response from generateManualPick: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    // List<dynamic> responseData = responseString["data"];
    if (responseString["result"] as int != 0) {
      printLongLogMessage("generateManualPick / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    List<Pick> picks
    = (responseString["data"] as List).map((e) => Pick.fromJson(e as Map<String, dynamic>))
        .toList();

    print("get ${picks.length} picks by manual picking for order $orderId, lpn: $lpn");

    return picks;

  }


}




