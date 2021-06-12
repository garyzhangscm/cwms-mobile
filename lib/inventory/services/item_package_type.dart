
import 'dart:convert';


import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:dio/dio.dart';

class ItemPackageTypeService {
  // Get all cycle count requests by batch id
  static Future<ItemPackageType> getItemPackageTypeByName(int itemId, String name) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/inventory/itemPackageTypes",
      queryParameters: {'warehouseId': Global.lastLoginCompanyId,
        'itemId': itemId,
          'name': name}
    );

    printLongLogMessage("response from item package type by name $itemId / $name");

    printLongLogMessage(response.toString());

    Map<String, dynamic> responseString = json.decode(response.toString());

    List<ItemPackageType> itemPackageTypes
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : ItemPackageType.fromJson(e as Map<String, dynamic>))
        ?.toList();
    print("itemPackageTypes.length: ${itemPackageTypes.length}");

    if (itemPackageTypes.length == 1) {
      return itemPackageTypes[0];
    }
    else {
      return null;
    }
  }






}