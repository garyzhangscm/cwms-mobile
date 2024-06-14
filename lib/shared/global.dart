import 'dart:convert';
import 'dart:io';
import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/models/rf_configuration.dart';
import 'package:cwms_mobile/shared/models/warehouse_configuration.dart';
import 'package:cwms_mobile/warehouse_layout/models/company.dart';

import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../inventory/models/inventory_configuration.dart';
import '../inventory/services/inventory_configuration.dart';
import 'http_client.dart';
import 'models/cacheConfig.dart';
import 'models/cwms_application_information.dart';
import 'models/cwms_http_client_wrapper.dart';
import 'models/cwms_http_config.dart';
import 'models/cwms_site_information.dart';
import 'models/profile.dart';
import 'models/rf.dart';

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
  static RF lastLoginRF;

  static Warehouse currentWarehouse;
  static Warehouse autoLoginWarehouse;
  static Company _autoLoginCompany;

  // Server from history, saved in SharedPreferences
  static List<CWMSSiteInformation> servers;

  static String lastLoginCompanyCode;

  static int lastLoginCompanyId;

  static String currentAPPVersion;

  static InventoryConfiguration currentInventoryConfiguration;

  static Profile profile = Profile();

  static RFConfiguration _rfConfiguration = RFConfiguration();
  static WarehouseConfiguration _warehouseConfiguration = WarehouseConfiguration();

  // 可选的主题列表
  static List<MaterialColor> get themes => _themes;

  // Last activity location;
  // The system will use this information to assign
  // next activity
  static WarehouseLocation _lastActivityLocation;
  // whether we need to move forward (1) or backward(-1)
  static int _lastActivityDirection;

  static CWMSHttpClientAdapter httpClient;


  // 是否为release版
  static bool get isRelease => bool.fromEnvironment("dart.vm.product");

  static RFConfiguration get getRFConfiguration => _rfConfiguration;

  static WarehouseConfiguration get warehouseConfiguration => _warehouseConfiguration;

  //初始化全局信息
  static Future init() async {
    WidgetsFlutterBinding.ensureInitialized();
    _prefs = await SharedPreferences.getInstance();
    _initServers();
    _initAutoLoginUser();
    _initAutoLoginWarehouse();
    _initAutoLoginCompany();
    _initLastLoginRFCode();
    _initLastLoginRF();


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

    // initial download flugin
    // await FlutterDownloader.initialize(
    //     debug: true // optional: set false to disable printing logs to console
   //  );

    // default configuration
    _rfConfiguration = RFConfiguration();
    printLongLogMessage("setup the default _rfConfiguration");
    _warehouseConfiguration = WarehouseConfiguration();
    printLongLogMessage("setup the default warehouse configuration");

    PackageInfo.fromPlatform().then((packageInfo) =>
        currentAPPVersion = packageInfo.version
    );
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

  static _clearAutoLoginUser() {
    _prefs.setString("auto_login_user", "");
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

  static initInventoryConfiguration() {
    InventoryConfigurationService.getInventoryConfiguration().then(
            (inventoryConfiguration) => currentInventoryConfiguration = inventoryConfiguration
    );
  }

  static _clearAutoLoginWarehouse() {
    _prefs.setString("auto_login_warehouse", "");
  }

  static _initAutoLoginCompany(){
    var _company = _prefs.getString("auto_login_company");
    print("_initAutoLingCompany: ${_company}");
    if (_company != null ) {
      try {
        _autoLoginCompany = Company.fromJson(json.decode(_company));
      } catch (e) {
        print(e);
      }
    }
  }

  static _clearAutoLoginCompany() {
    _prefs.setString("auto_login_company", "");
  }

  static _initLastLoginRFCode(){
    lastLoginRFCode = _prefs.getString("last_login_rf_code");
  }
  static _initLastLoginRF(){
    var _lastLoginRF = _prefs.getString("last_login_rf");
    if (_lastLoginRF != null) {
      try {
        lastLoginRF = RF.fromJson(jsonDecode(_lastLoginRF));
      } catch (e) {
        print(e);
      }
    }

  }

  static String getLastLoginRFCode(){
    return lastLoginRFCode;
  }
  static setLastLoginRFCode(String rfCode){
    lastLoginRFCode = rfCode;

    _prefs.setString("last_login_rf_code", lastLoginRFCode);
  }
  static RF getLastLoginRF(){
    return lastLoginRF;
  }
  static setLastLoginRF(RF rf){
    lastLoginRF = rf;

    _prefs.setString("last_login_rf", jsonEncode(rf.toJson()));
  }

  static Warehouse getAutoLoginWarehouse(){
    return autoLoginWarehouse;
  }
  static Company getAutoLoginCompany(){
    return _autoLoginCompany;
  }


  static setAutoLoginWarehouse(Warehouse warehouse)  async {

    _prefs = await SharedPreferences.getInstance();
    _prefs.setString("auto_login_warehouse", json.encode(warehouse.toJson()));

    print("set auto loginc warehouse to ${json.encode(warehouse.toJson())}");
    autoLoginWarehouse = warehouse;
  }

  static setAutoLoginCompany(Company company)  async {

    _prefs = await SharedPreferences.getInstance();
    _prefs.setString("auto_login_company", json.encode(company.toJson()));

    print("set auto loginc warehouse to ${json.encode(company.toJson())}");
    _autoLoginCompany = company;
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

  static void setupHttpClient() {
    CWMSHttpConfig dioConfig =
        CWMSHttpConfig(
          baseUrl: Global.currentServer.url,
          headers: {
            HttpHeaders.acceptHeader: "application/json",
            HttpHeaders.authorizationHeader: "Bearer ${Global.currentUser.token}",
            "rfCode": Global.lastLoginRFCode
          },);
    httpClient = CWMSHttpClientAdapter(dioConfig: dioConfig);

    CWMSHttpClient.resetDio();
  }

// 持久化Profile信息
  static saveProfile() =>
      _prefs.setString("profile", jsonEncode(profile.toJson()));


  static WarehouseLocation getLastActivityLocation() {
    return _lastActivityLocation;
  }

  static void setLastActivityLocation(WarehouseLocation location) {
    print("_lastActivityLocation is changed to ${location.name}");
    _lastActivityLocation = location;
  }

  static void setRFConfiguration(RFConfiguration rfConfiguration) {
    _rfConfiguration = rfConfiguration;
  }

  static void setWarehouseConfiguration(WarehouseConfiguration warehouseConfiguration) {
    _warehouseConfiguration = warehouseConfiguration;
  }

  static bool getConfigurationAsBoolean(String key) {
    printLongLogMessage("_rfConfiguration is null? ${_rfConfiguration == null}");
    Map<String, dynamic> configurations = _rfConfiguration.toJson();

    // return false by default for boolean value
    return configurations.containsKey(key) ? configurations[key] as bool :
        false;
  }
  static String getConfigurationAsString(String key) {
    Map<String, dynamic> configurations = _rfConfiguration.toJson();

    // return empty string by default for String value
    return configurations.containsKey(key) ? configurations[key] as String :
        "";
  }
  static int getConfigurationAsInt(String key) {
    Map<String, dynamic> configurations = _rfConfiguration.toJson();

    // return 0  by default for int value
    return configurations.containsKey(key) ? configurations[key] as int :
     0;
  }


  // logout the current user
  static logout() {
    currentUser = null;
    currentUsername = "";
    _clearAutoLoginUser();

    currentWarehouse = null;
    _clearAutoLoginWarehouse();

    lastLoginCompanyCode = "";
    lastLoginCompanyId = null;

  }
}