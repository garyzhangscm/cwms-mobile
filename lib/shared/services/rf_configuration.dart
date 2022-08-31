
import 'dart:convert';

import 'package:cwms_mobile/common/services/system_controlled_number.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/inbound/models/receipt.dart';
import 'package:cwms_mobile/inbound/models/receipt_line.dart';
import 'package:cwms_mobile/inbound/models/receipt_status.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/rf_app_version.dart';
import 'package:cwms_mobile/shared/models/rf_configuration.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:dio/dio.dart';

class RFConfigurationService {

  static Future<RFConfiguration> getRFConfiguration(String rfCode) async {

    Response response = await Dio().get(
        Global.currentServer.url + "/resource/rf-configurations",
        queryParameters: {"companyId": Global.currentWarehouse.id,
        "rfCode": rfCode}
    );

    print("response from getRFConfiguration: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }
    Map<String, dynamic> responseData = responseString["data"] as Map<String, dynamic>;
    if (responseData == null || responseData.isEmpty) {
      return null;
    }
    return RFConfiguration.fromJson(responseData);

  }




}




