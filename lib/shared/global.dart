import 'dart:convert';
import 'package:cwms_mobile/auth/models/user.dart';

import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'http_client.dart';
import 'models/cacheConfig.dart';
import 'models/cwms_application_information.dart';
import 'models/cwms_site_information.dart';
import 'models/profile.dart';

// 提供四套可选主题色
const _themes = <MaterialColor>[
  Colors.blue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.red,
];

class Global {
  static SharedPreferences _prefs;
  // current connection
  static CWMSSiteInformation currentServer;
  // current Login
  static User currentUser;
  static String currentUsername;
  static User autoLoginUser;

  static String lastLoginRFCode;

  static Warehouse currentWarehouse;
  static Warehouse autoLoginWarehouse;

  // Server from history, saved in SharedPreferences
  static List<CWMSSiteInformation> servers;

  static String lastLoginCompanyCode;

  static int lastLoginCompanyId;

  static Profile profile = Profile();

  // 可选的主题列表
  static List<MaterialColor> get themes => _themes;

  // Last activity location;
  // The system will use this information to assign
  // next activity
  static WarehouseLocation lastActivityLocation;
  // whether we need to move forward (1) or backward(-1)
  static int _lastActivityDirection;


  // 是否为release版
  static bool get isRelease => bool.fromEnvironment("dart.vm.product");

  //初始化全局信息
  static Future init() async {
    WidgetsFlutterBinding.ensureInitialized();
    _prefs = await SharedPreferences.getInstance();
    _initServers();
    _initAutoLoginUser();
    _initAutoLoginWarehouse();
    _initLastLoginRFCode();

    // initial profile
    var _profile = _prefs.getString("profile");
    if (_profile != null) {
      try {
        profile = Profile.fromJson(jsonDecode(_profile));
      } catch (e) {
        print(e);
      }
    }

    // 如果没有缓存策略，设置默认缓存策略
    profile.cache = profile.cache ?? CacheConfig()
      ..enable = true
      ..maxAge = 3600
      ..maxCount = 100;

    //初始化网络请求相关配置
    CWMSHttpClient.init();

    // hard code company id to -1
    lastLoginCompanyId = _prefs.getInt("lastLoginCompanyId");
    lastLoginCompanyCode = _prefs.getString("lastLoginCompanyCode");
  }
  static _initServers() {
    var _servers = _prefs.getString("servers");
    if (_servers != null ) {
      try {
        List<dynamic> serverList = jsonDecode(_servers);
        if (serverList.isEmpty) {
          servers = List<CWMSSiteInformation>();
        }
        else {
          servers = CWMSSiteInformation.decodeServers(_servers);

        }
      } catch (e) {
        print(e);
      }
    }
    else {
      servers = List<CWMSSiteInformation>();
    }

  }

  static _initAutoLoginUser(){
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
  static _initAutoLoginWarehouse(){
    var _warehouse = _prefs.getString("auto_login_warehouse");
    print("_initAutoLingWarehouse: ${_warehouse}");
    if (_warehouse != null ) {
      try {
        autoLoginWarehouse = Warehouse.fromJson(json.decode(_warehouse));
      } catch (e) {
        print(e);
      }
    }
  }

  static _initLastLoginRFCode(){
    lastLoginRFCode = _prefs.getString("last_login_rf_code");
  }
  static String getLastLoginRFCode(){
    return lastLoginRFCode;
  }
  static setLastLoginRFCode(String rfCode){
    lastLoginRFCode = rfCode;

    _prefs.setString("last_login_rf_code", lastLoginRFCode);
  }

  static Warehouse getAutoLoginWarehouse(){
    return autoLoginWarehouse;
  }

  static setAutoLoginWarehouse(Warehouse warehouse)  async {

    _prefs = await SharedPreferences.getInstance();
    _prefs.setString("auto_login_warehouse", json.encode(warehouse.toJson()));

    print("set auto loginc warehouse to ${json.encode(warehouse.toJson())}");
    autoLoginWarehouse = warehouse;
  }


  static addServer(CWMSSiteInformation server) async {

    CWMSSiteInformation matchedServer
      = servers.firstWhere((element) => element.url.compareTo(server.url) == 0, orElse: () => null);

    if (matchedServer != null) {
      // OK, we get a matched server, let's update it based on the new configuration
      matchedServer.autoConnectFlag = server.autoConnectFlag;
      if (matchedServer.cwmsApplicationInformation == null) {
        matchedServer.cwmsApplicationInformation = new CWMSApplicationInformation();
      }
      matchedServer.cwmsApplicationInformation.name = server.cwmsApplicationInformation.name;
      matchedServer.cwmsApplicationInformation.version = server.cwmsApplicationInformation.version;
    }
    else {
      // we will save the new server.
      // If the new server is configured as 'auto connect' then
      // we will cancel the auto connect flag of other server to make sure
      // we will only have one auto connect server
      if (server.autoConnectFlag == true) {

        CWMSSiteInformation autoConnectServer = getAutoConnectServer();
        if (autoConnectServer != null) {
          autoConnectServer.autoConnectFlag = false;
        }
      }
      servers.add(server);
    }

    _prefs = await SharedPreferences.getInstance();
    _prefs.setString("servers", CWMSSiteInformation.encodeServers(servers));

  }


  static setCurrentServer(CWMSSiteInformation server) {
    currentServer = server;
  }
  static CWMSSiteInformation geturrentServer() {
    return currentServer;
  }


  static CWMSSiteInformation getAutoConnectServer() {
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

  static setCurrentWarehouse(Warehouse warehouse) {
    currentWarehouse = warehouse;
  }

  static int getLastLoginCompanyId() {
    return lastLoginCompanyId;
  }
  static setLastLoginCompanyId(int _lastLoginCompanyId) {
    _prefs.setInt("lastLoginCompanyId", _lastLoginCompanyId);
    lastLoginCompanyId = _lastLoginCompanyId;
  }
  static String getLastLoginCompanyCode() {
    return lastLoginCompanyCode;
  }
  static setLastLoginCompanyCode(String _lastLoginCompanyCode) {
    _prefs.setString("lastLoginCompanyCode", _lastLoginCompanyCode);
    lastLoginCompanyCode = _lastLoginCompanyCode;
  }

  static void movingForward() {
    _lastActivityDirection = 1;
  }
  static void movingBackward() {
    _lastActivityDirection = -1;
  }

  static bool isMovingForward() {
    return _lastActivityDirection == 1;
  }

// 持久化Profile信息
  static saveProfile() =>
      _prefs.setString("profile", jsonEncode(profile.toJson()));

}