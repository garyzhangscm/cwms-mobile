
import 'package:cwms_mobile/auth/models/menu_group.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/models/cwms_http_response.dart';



import 'package:dio/dio.dart';

class MenuService {

  static Future<MenuGroup> getAccessibleMenus() async {


    CWMSHttpResponse response = await Global.httpClient!.get("/resource/site-information/mobile",
        queryParameters: {
          "companyId": Global.lastLoginCompanyId
        });

      Map<String, dynamic> responseData = response.data;
      List<MenuGroup> menuGroups
      = (responseData['menu'] as List).map((e) => MenuGroup.fromJson(e as Map<String, dynamic>))
          .toList();
      return menuGroups[0];

  }
}