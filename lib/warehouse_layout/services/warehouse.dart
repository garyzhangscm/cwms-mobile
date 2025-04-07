
import 'dart:convert';



import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:dio/dio.dart';

import '../../exception/WebAPICallException.dart';
import '../../shared/functions.dart';

class WarehouseService {
  // Get all cycle count requests by batch id
  static Future<List<Warehouse>> getWarehouseByUser(String companyCode, String username) async {

    String warehouseListURL =
        Global.currentServer!.url! + "layout/warehouses/accessible/$companyCode/$username";
    print("Will get warehouse list from $warehouseListURL");
    Response response = await Dio().get(warehouseListURL);

    print("reponse from WAREHOUSE: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("getWarehouseByUser / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    List<Warehouse> _warehouses
    = (responseString["data"] as List).map((e) =>  Warehouse.fromJson(e as Map<String, dynamic>))
        .toList();


    return _warehouses;


  }

}