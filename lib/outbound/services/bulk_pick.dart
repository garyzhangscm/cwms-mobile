
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

class BulkPickService {

  // Confirm pick, with picking quantity
  static Future<void> confirmBulkPick(BulkPick bulkPick, int confirmQuantity, [String lpn, String nextLocationName = ""]) async{

    printLongLogMessage("start to confirm bulk pick ${bulkPick.number}, confirmQuantity: ${confirmQuantity}, lpn: ${lpn}");

    // only continue when the confirmed quantity is bigger than 0
    if (confirmQuantity <= 0) {
      return;
    }

    Dio httpClient = CWMSHttpClient.getDio();

    // pick to RF
    // if the user specify the next location, then pick to the next location
    // otherwise  pick to the RF
    printLongLogMessage("start to pick to ${nextLocationName.isEmpty ? Global.getLastLoginRFCode() : nextLocationName}");
    Response response = await httpClient.post(
        "outbound/bulk-picks/${bulkPick.id}/confirm",
        queryParameters: {"quantity": confirmQuantity,
          "nextLocationName": nextLocationName.isEmpty ? Global.getLastLoginRFCode() : nextLocationName,
        "lpn": lpn}
    );

    // print("response from confirm pick: $response");

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


  }

}




