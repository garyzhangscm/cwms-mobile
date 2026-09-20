
import 'dart:convert';

import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:dio/dio.dart';

class SystemControlledNumberService {

  static Future<String> getNextAvailableId(String type) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "common/system-controlled-number/$type/next",
        queryParameters: {
          "warehouseId": Global.currentWarehouse!.id,
          "rfCode": Global.getLastLoginRFCode()
        }
    );

    // print("response from receipt: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());


    String nextNumber = responseString["data"]["nextNumber"];

    return nextNumber;

  }


}




