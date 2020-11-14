import 'dart:convert';

import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/common/http_client.dart';
import 'package:cwms_mobile/common/models/http_response_wrapper.dart';
import 'package:cwms_mobile/common/models/login_response_wrapper.dart';
import 'package:dio/dio.dart';

class LoginService {
  // 登录接口，登录成功后返回用户信息
  static Future<User> login(String username, String password) async {
    Dio httpClient = CWMSHttpClient.dio;


    Response response = await httpClient.post(
      "/auth/login",
      data:{"username":username,"password": password}
    );

    print("login response: $response");

    LoginResponseWrapper loginResponseWrapper =
        LoginResponseWrapper.fromJson(json.decode(response.toString()));

    print("httpResponseWrapper: $loginResponseWrapper");

    if (loginResponseWrapper.result == 0) {
      // ok, we can connect to the server. Add it to the history
      return User.fromJson(loginResponseWrapper.user);
    }

    return null;
  }
}