
import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:dio/dio.dart';

import '../models/bulk_pick.dart';
import '../models/pick_list.dart';

class PickListService {

  // find bulk pick by number
  static Future<PickList> getPickListByNumber(String number) async{

    printLongLogMessage("start to find pick list by number $number");


    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "outbound/pick-lists",
        queryParameters: {"number": number,
          "warehouseId": Global.currentWarehouse.id
        }
    );

    // print("response from confirm pick: $response");

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    List<PickList> pickLists
      = (responseString["data"] as List)?.map((e) =>
      e == null ? null : PickList.fromJson(e as Map<String, dynamic>))
          ?.toList();


    if (pickLists.length > 0) {
      return pickLists.first;
    }
    else {
      throw new WebAPICallException("can't find pick list by number $number");
    }

  }


  // Confirm pick, with picking quantity
  static Future<PickList> confirmPickList(PickList pickList, int confirmQuantity,
      int sourceLocationId, [String lpn, String nextLocationName = ""]) async{

    printLongLogMessage("start to confirm pick list ${pickList.number}, confirmQuantity: $confirmQuantity, lpn: $lpn");

    // only continue when the confirmed quantity is bigger than 0
    if (confirmQuantity <= 0) {
      return null;
    }

    Dio httpClient = CWMSHttpClient.getDio();

    // pick to RF
    // if the user specify the next location, then pick to the next location
    // otherwise  pick to the RF
    printLongLogMessage("start to pick to ${nextLocationName.isEmpty ? Global.getLastLoginRFCode() : nextLocationName}");
    Response response = await httpClient.post(
        "outbound/pick-lists/${pickList.id}/confirm",
        queryParameters: {
          "warehouseId": Global.currentWarehouse.id,
          "quantity": confirmQuantity,
          "sourceLocationId": sourceLocationId,
          "nextLocationName": nextLocationName.isEmpty ? Global.getLastLoginRFCode() : nextLocationName,
          "lpn": lpn}
    );

    print("response from confirm pick: $response");

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return PickList.fromJson(responseString["data"]);

  }

  static Future<PickList> acknowledgePickList(int id) async{

    printLongLogMessage("start to acknowledge pick list by id $id");


    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "outbound/pick-lists/${id}/acknowledge",
        queryParameters: {
          "warehouseId": Global.currentWarehouse.id
        }
    );

    // print("response from confirm pick: $response");

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return PickList.fromJson(responseString["data"] as Map<String, dynamic>) ;

  }
  static Future<PickList> unacknowledgePickList(int id) async{

    printLongLogMessage("start to unacknowledgePickList pick list by id $id");


    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "outbound/pick-lists/${id}/unacknowledge",
        queryParameters: {
          "warehouseId": Global.currentWarehouse.id
        }
    );

    // print("response from confirm pick: $response");

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return PickList.fromJson(responseString["data"] as Map<String, dynamic>) ;

  }
}




