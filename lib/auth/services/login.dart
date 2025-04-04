import 'dart:convert';

import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';

import 'package:cwms_mobile/shared/models/login_response_wrapper.dart';
import 'package:dio/dio.dart';

class LoginService {
  // 登录接口，登录成功后返回用户信息
  static Future<User> login(int companyId, String username, String password) async {
    Global.currentUsername = username;
    Dio httpClient = CWMSHttpClient.dio;


    Response response = await httpClient.post(
      "/auth/login",
      data:{"companyId": companyId, "username":username,"password": password}
    );

    print("login response: $response");

    LoginResponseWrapper loginResponseWrapper =
        LoginResponseWrapper.fromJson(json.decode(response.toString()));

    print("httpResponseWrapper: ${loginResponseWrapper.result}");


    if (loginResponseWrapper.result == 0) {
      // ok, we can connect to the server. Add it to the history
      return User.fromJson(loginResponseWrapper.user);
    }
    else {
      throw(loginResponseWrapper.message);
    }

  }
}