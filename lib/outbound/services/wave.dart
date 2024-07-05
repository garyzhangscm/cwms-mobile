
import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:dio/dio.dart';

import '../models/wave.dart';

class WaveService {
  // Get all cycle count requests by batch id
  static Future<Wave> getWaveByNumber(String waveNumber) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "outbound/waves",
        queryParameters: {"number": waveNumber,
          "warehouseId": Global.currentWarehouse.id}
    );

    // print("response from Order: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("getWaveByNumber / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


    List<Wave> waves
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : Wave.fromJson(e as Map<String, dynamic>))
        ?.toList();

    if (waves.length > 0) {
      return waves.first;
    }
    else {
      throw new WebAPICallException("can't find wave by number ${waveNumber}");
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


  static Future<int> getPickableQuantityForManualPick(
      int orderId, String lpn
      ) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "outbound/orders/${orderId}/get-manual-pick-quantity",
        queryParameters: {"warehouseId": Global.currentWarehouse.id,
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
        queryParameters: {"warehouseId": Global.currentWarehouse.id,
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
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : Pick.fromJson(e as Map<String, dynamic>))
        ?.toList();

    print("get ${picks.length} picks by manual picking for order $orderId, lpn: $lpn");

    return picks;

  }


}




