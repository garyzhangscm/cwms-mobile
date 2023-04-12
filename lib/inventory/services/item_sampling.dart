
import 'dart:convert';


import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_sampling.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:dio/dio.dart';

class ItemSamplingService {
  // Get all cycle count requests by batch id
  static Future<ItemSampling> getCurrentItemSamplingByItemName(String itemName) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/inventory/item-sampling",
      queryParameters: {'warehouseId': Global.currentWarehouse.id,
          'itemName': itemName,
      "currentSampleOnly": true}
    );

    // printLongLogMessage("response from getCurrentItemSamplingByItemName by item $itemName");

    // printLongLogMessage(response.toString());

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }
    List<ItemSampling> itemSamplingList
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : ItemSampling.fromJson(e as Map<String, dynamic>))
        ?.toList();
    print("itemSamplingList.length: ${itemSamplingList.length}");

    if (itemSamplingList.length == 1) {
      return itemSamplingList[0];
    }
    else {
      return null;
    }
  }



  static Future<ItemSampling> getItemSamplingByNumber(String number) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/inventory/item-sampling",
        queryParameters: {'warehouseId': Global.currentWarehouse.id,
          'number': number}
    );

    // printLongLogMessage("response from getCurrentItemSamplingByItemName by number $number");

    // printLongLogMessage(response.toString());

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }
    List<ItemSampling> itemSamplingList
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : ItemSampling.fromJson(e as Map<String, dynamic>))
        ?.toList();
    print("itemSamplingList.length: ${itemSamplingList.length}");

    if (itemSamplingList.length == 1) {
      return itemSamplingList[0];
    }
    else {
      return null;
    }
  }


  static Future<ItemSampling> addItemSampling(ItemSampling itemSampling) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.put(
        "/inventory/item-sampling",
        queryParameters: {'warehouseId': Global.currentWarehouse.id},
      data: itemSampling
    );

    // printLongLogMessage("response from addItemSampling by number ${itemSampling.number}");

    // printLongLogMessage(response.toString());

    Map<String, dynamic> responseString = json.decode(response.toString());
    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return ItemSampling.fromJson(responseString["data"] as Map<String, dynamic>);
  }


  static Future<ItemSampling> changeItemSampling(ItemSampling itemSampling) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "/inventory/item-sampling/${itemSampling.id}",
        queryParameters: {'warehouseId': Global.currentWarehouse.id},
        data: itemSampling
    );

    // printLongLogMessage("response from changeItemSampling by number ${itemSampling.number}");

    // printLongLogMessage(response.toString());

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }
    return ItemSampling.fromJson(responseString["data"] as Map<String, dynamic>);
  }


}