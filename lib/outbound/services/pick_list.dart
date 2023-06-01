
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

}




