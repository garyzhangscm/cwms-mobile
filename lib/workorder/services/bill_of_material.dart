
import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/workorder/models/bill_of_material.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_produce_transaction.dart';
import 'package:dio/dio.dart';

class BillOfMaterialService {
  // Get all cycle count requests by batch id
  static Future<BillOfMaterial> findMatchedBillOfMaterial(WorkOrder workOrder) async {
    Dio httpClient = CWMSHttpClient.getDio();
    printLongLogMessage("findMatchedBillOfMaterial by work order id ${workOrder.id}");

    Response response = await httpClient.get(
        "workorder/bill-of-materials/matched-with-work-order",
        queryParameters: {"workOrderId": workOrder.id}
    );

    // print("response from findMatchedBillOfMaterial: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("findMatchedBillOfMaterial / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    if (responseString["data"] != null) {
      return BillOfMaterial.fromJson(responseString["data"] as Map<String, dynamic>);

    }
    else {
      return null;
    }




  }





}




