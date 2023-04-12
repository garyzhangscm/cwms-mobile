
import 'dart:convert';
import 'dart:developer';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/work/models/work_task.dart';
import 'package:dio/dio.dart';

class WorkTaskService {
  // Get all cycle count requests by batch id
  static Future<WorkTask> getNextWorkTask() async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "resource/work-tasks/next-work-task",
        queryParameters: {"rfCode":  Global.getLastLoginRFCode(),
          "warehouseId": Global.currentWarehouse.id}
    );

    // printLongLogMessage("response from getNextWorkTask: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return WorkTask.fromJson(responseString["data"]);

  }
}




