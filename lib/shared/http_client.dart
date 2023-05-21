import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cwms_mobile/auth/models/user.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'global.dart';

class CWMSHttpClient {
  // 在网络请求过程中可能会需要使用当前的context信息，比如在请求失败时
  // 打开一个新路由，而打开新路由需要context信息。
  CWMSHttpClient([this.context]) {
    _options = Options(extra: {"context": context});
  }

  BuildContext context;
  Options _options;

  static int timeoutRetryTime = 20;


  static Dio _dio = new Dio(BaseOptions(
    baseUrl: Global.currentServer.url,
    headers: {
      HttpHeaders.acceptHeader: "application/json",
    },

  ));

  static Dio _dioWithAuth;

  static Dio get  dio => _dio;

  static Dio getDio() {
    if (_dioWithAuth == null) {
      _dioWithAuth = new Dio(BaseOptions(
          baseUrl: Global.currentServer.url,
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader: "Bearer ${Global.currentUser.token}",
            "rfCode": Global.lastLoginRFCode,
            "warehouseId": Global.currentWarehouse.id,
            "companyId": Global.lastLoginCompanyId
          },
          // connectTimeout: 10000,
          // receiveTimeout: 15000,
          // sendTimeout: 15000,

      ));
    }
    return _dioWithAuth;
  }

  static void init() {
    // 添加缓存插件
    // dio.interceptors.add(Global.netCache);
    // 设置用户token（可能为null，代表未登录）
    // dio.options.headers[HttpHeaders.authorizationHeader] = Global.profile.token;

    // 在调试模式下需要抓包调试，所以我们使用代理，并禁用HTTPS证书校验

    /***
    if (!Global.isRelease) {
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
          (client) {
        client.findProxy = (uri) {
          return "PROXY 10.95.249.53:8888";
        };
        //代理工具会提供一个抓包的自签名证书，会通不过证书校验，所以我们禁用证书校验
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      };
    }
        ***/
  }


}
