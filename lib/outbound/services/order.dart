
import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:dio/dio.dart';

class OrderService {
  // Get all cycle count requests by batch id
  static Future<Order> getOrderByNumber(String orderNumber) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "outbound/orders",
        queryParameters: {"number": orderNumber,
          "warehouseId": Global.currentWarehouse.id}
    );

    // print("response from Order: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


    List<Order> orders
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : Order.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // Sort the picks according to the current location. We
    // will assign the closed pick to the user
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
        queryParameters: {"warehouseId": Global.currentWarehouse.id}
    );

    // print("response from Order: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    // List<dynamic> responseData = responseString["data"];

    List<Order> orders
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : Order.fromJson(e as Map<String, dynamic>))
        ?.toList();

    print("get ${orders.length} orders");

    return orders;

  }

}




