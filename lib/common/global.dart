import 'dart:convert';
import 'package:cwms_mobile/auth/models/user.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'http_client.dart';
import 'models/cwms_server.dart';



class Global {
  static SharedPreferences _prefs;
  // current connection
  static CWMSServer currentServer;
  // current Login
  static User currentUser;
  static User autoLoginUser;

  // Server from history, saved in SharedPreferences
  static List<CWMSServer> servers;

  static int companyId;


  // 是否为release版
  static bool get isRelease => bool.fromEnvironment("dart.vm.product");

  //初始化全局信息
  static Future init() async {
    WidgetsFlutterBinding.ensureInitialized();
    _prefs = await SharedPreferences.getInstance();
    _initServers();
    _initAutoLingUser();

    //初始化网络请求相关配置
    CWMSHttpClient.init();

    // hard code company id to 1
    companyId = 1;
  }
  static _initServers() {
    var _servers = _prefs.getString("servers");
    if (_servers != null ) {
      try {
        List<dynamic> serverList = jsonDecode(_servers);
        if (serverList.isEmpty) {
          servers = List<CWMSServer>();
        }
        else {
          servers = CWMSServer.decodeServers(_servers);

        }
      } catch (e) {
        print(e);
      }
    }
    else {
      servers = List<CWMSServer>();
    }

  }

  static _initAutoLingUser(){
    var _user = _prefs.getString("auto_login_user");
    print("_initAutoLingUser: ${_user}");
    if (_user != null ) {
      try {
          autoLoginUser = User.fromJson(json.decode(_user));
      } catch (e) {
        print(e);
      }
    }
  }

  static addServer(CWMSServer server) async {

    CWMSServer matchedServer
      = servers.firstWhere((element) => element.url.compareTo(server.url) == 0, orElse: () => null);

    if (matchedServer != null) {
      // OK, we get a matched server, let's update it based on the new configuration
      matchedServer.autoConnectFlag = server.autoConnectFlag;
      matchedServer.name = server.name;
      matchedServer.version = server.version;
    }
    else {
      // we will save the new server.
      // If the new server is configured as 'auto connect' then
      // we will cancel the auto connect flag of other server to make sure
      // we will only have one auto connect server
      if (server.autoConnectFlag == true) {

        CWMSServer autoConnectServer = getAutoConnectServer();
        if (autoConnectServer != null) {
          autoConnectServer.autoConnectFlag = false;
        }
      }
      servers.add(server);
    }

    _prefs = await SharedPreferences.getInstance();
    _prefs.setString("servers", CWMSServer.encodeServers(servers));

  }


  static setCurrentServer(CWMSServer server) {
    currentServer = server;
  }

  static CWMSServer getAutoConnectServer() {
    if (servers == null || servers.isEmpty) {
      return null;
    }
    else {
      return servers.firstWhere((element) => element.isAutoConnect(), orElse: () => null);
    }
  }


  static setCurrentUser(User user) {
    currentUser = user;
  }

  static addAutoLoginUser(User user) async{
    print("start to add user to the auto login: ${user.username}");
    _prefs = await SharedPreferences.getInstance();
    _prefs.setString("auto_login_user", json.encode(user.toJson()));


    var _user = _prefs.getString("auto_login_user");
    print("after adding  auto login: ${_user}");
  }

  static int getCompanyId() {
    return companyId;
  }

}