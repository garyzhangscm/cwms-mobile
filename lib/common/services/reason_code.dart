
import 'dart:convert';

import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:dio/dio.dart';

import '../../exception/WebAPICallException.dart';
import '../../shared/http_client.dart';
import '../models/reason_code.dart';

class ReasonCodeService {

  static Future<List<ReasonCode>> getReasonCodes(String type) async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage("get reason code by type $type");
    Response response = await httpClient.get(
        "/common/reason-codes",
        queryParameters: {'warehouseId': Global.currentWarehouse.id,
          'type': type}
    );


    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("getReasonCodes / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return (responseString["data"] as List).map((e) => ReasonCode.fromJson(e as Map<String, dynamic>))
        .toList();

  }


}




