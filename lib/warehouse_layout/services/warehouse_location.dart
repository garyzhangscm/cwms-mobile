
import 'dart:convert';



import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:dio/dio.dart';

class WarehouseLocationService {
  // Get all cycle count requests by batch id
  static Future<WarehouseLocation> getWarehouseLocationByName(String locationName) async {


    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/layout/locations",
        queryParameters: {'warehouseId': Global.lastLoginCompanyId,
          'name': locationName}
    );

    print("response from inventory on RF:");

    printLongLogMessage(response.toString());

    Map<String, dynamic> responseString = json.decode(response.toString());

    List<WarehouseLocation> locations
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : WarehouseLocation.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // we should only have one location returned since we qualify by
    // name and warehouse id
    if (locations.length != 1) {
      return null;
    }
    else {
      return locations[0];
    }
  }

}