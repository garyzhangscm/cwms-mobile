
import 'dart:convert';

import 'package:cwms_mobile/common/services/system_controlled_number.dart';
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
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:dio/dio.dart';

class SystemControlledNumberService {

  static Future<String> getNextAvailableId(String type) async {
    Dio httpClient = CWMSHttpClient.getDio();


    Response response = await httpClient.get(
        "`common/system-controlled-number/${type}/next",
        queryParameters: {"warehouseId": Global.currentWarehouse.id}
    );

    // print("response from receipt: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());


    return responseString["data"] as String;



  }




}




