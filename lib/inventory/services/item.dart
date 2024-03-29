
import 'dart:convert';


import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:dio/dio.dart';

class ItemService {
  // Get all cycle count requests by batch id
  static Future<Item> getItemByName(String name) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/inventory/items",
      queryParameters: {'warehouseId': Global.currentWarehouse.id,
          'name': name}
    );

    // printLongLogMessage("response from item by name $name");

    // printLongLogMessage(response.toString());

    Map<String, dynamic> responseString = json.decode(response.toString());

    List<Item> items
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : Item.fromJson(e as Map<String, dynamic>))
        ?.toList();
    print("items.length: ${items.length}");

    if (items.length == 1) {
      return items[0];
    }
    else {
      return null;
    }
  }




  static Future<List<Item>> queryItemByKeyword(String keyword) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/inventory/items-query/by-keyword",
        queryParameters: {'warehouseId': Global.currentWarehouse.id,
          'companyId': Global.lastLoginCompanyId,
          'keyword': keyword}
    );

    // printLongLogMessage("response from item by keyword $keyword");

    // printLongLogMessage(response.toString());

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return (responseString["data"] as List)?.map((e) =>
        e == null ? null : Item.fromJson(e as Map<String, dynamic>))
            ?.toList();
  }


}