import 'dart:convert';

import 'package:cwms_mobile/auth/models/menu_group.dart';

import 'package:cwms_mobile/common/global.dart';
import 'package:cwms_mobile/common/http_client.dart';

import 'package:dio/dio.dart';

class MenuService {

  static Future<MenuGroup> getAccessibleMenus() async {
    Dio httpClient = CWMSHttpClient.getDio();


    Response response = await httpClient.get(
      "/resource/site-information/mobile",
        queryParameters: {
          "companyId": Global.companyId
        }
    );
    Map<String, dynamic> responseString = json.decode(response.toString());
    Map<String, dynamic> responseData = responseString["data"];

    List<MenuGroup> menuGroups
      = (responseData['menu'] as List)?.map((e) =>
          e == null ? null : MenuGroup.fromJson(e as Map<String, dynamic>))
          ?.toList();


    return menuGroups[0];
  }
}