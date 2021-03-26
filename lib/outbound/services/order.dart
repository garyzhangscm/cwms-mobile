
import 'dart:convert';

import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
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

    print("response from Order: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    List<dynamic> responseData = responseString["data"];

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
      return null;
    }

  }



}




