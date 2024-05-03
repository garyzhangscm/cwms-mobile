
import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/models/rf_app_version.dart';
import 'package:dio/dio.dart';

class RFAppVersionService {

  static Future<RFAppVersion> getLatestRFAppVersion(String rfCode) async {

    Response response = await Dio().get(
        Global.currentServer.url + "/resource/rf-app-version/latest-version",
        queryParameters: {"companyId": Global.getLastLoginCompanyId(),
        "rfCode": rfCode}
    );

    // print("response from getLatestRFAppVersion: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("getLatestRFAppVersion / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }
    Map<String, dynamic> responseData = responseString["data"] as Map<String, dynamic>;
    if (responseData == null || responseData.isEmpty) {
      return null;
    }
    return RFAppVersion.fromJson(responseData);

  }




}




