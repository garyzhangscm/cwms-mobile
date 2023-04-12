import 'dart:convert';

import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';

import 'package:cwms_mobile/shared/models/login_response_wrapper.dart';
import 'package:dio/dio.dart';

class UserService {
  // 登录接口，登录成功后返回用户信息
  static Future<User> findUser(int companyId, String username) async {

    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
      "/resource/users",
        queryParameters:{"companyId": companyId, "username":username}
    );

    // print("response from findUser: $response");

    Map<String, dynamic> responseString = json.decode(response.toString());

    List<User> users
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : User.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // we should only have user with the specific name
    if (users.length > 0) {
      return users.first;
    }
    else {
      return null;
    }
  }
}