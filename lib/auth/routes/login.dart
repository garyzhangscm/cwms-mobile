import 'dart:convert';

import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/auth/services/login.dart';
import 'package:cwms_mobile/common/services/rf.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/models/rf_app_version.dart';
import 'package:cwms_mobile/shared/services/rf_app_version.dart';


import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/services/company.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

class LoginPage extends StatefulWidget{

  LoginPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {

  TextEditingController _companyCodeController = new TextEditingController();
  TextEditingController _unameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  TextEditingController _rfCodeController = new TextEditingController();
  List<Warehouse> _validWarehouses = [];
  Warehouse selectedWarehouse;
  bool pwdShow = false;
  GlobalKey _formKey = new GlobalKey<FormState>();

  bool _rememberMe = false;
  String defaultCompanyCode = "";
  int companyId = -1;

  @override
  void initState() {
    super.initState();
    // check if this is a single company site

    if (Global.geturrentServer() != null && Global.geturrentServer().isSingleCompanySite()) {
      defaultCompanyCode = Global.geturrentServer().getDefaultCompanyCode();

    }
    else {
      defaultCompanyCode = Global.lastLoginCompanyCode;
    }
    _companyCodeController.text = defaultCompanyCode;
    // check if auto login
    if (Global.autoLoginUser != null) {
      _processAutoLogin(Global.autoLoginUser);
    }
    _validWarehouses = [];
    _rfCodeController = TextEditingController(
        text: Global.getLastLoginRFCode());

  }

  @override
  Widget build(BuildContext context) {

    _companyCodeController.text = Global.lastLoginCompanyCode;

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).login)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          // autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[
              Focus(
                child: TextFormField(
                    controller: _companyCodeController,
                    decoration: InputDecoration(
                      labelText: "company code",
                      hintText: "please input your company code",
                      prefixIcon: Icon(Icons.person),
                    ),
                    // 校验company code（不能为空）
                    validator: (v) {
                      return v.trim().isNotEmpty ? null : "company code is required";
                    }),
                onFocusChange: (hasFocus) {
                  if(!hasFocus) {
                      print("V2. validate when leave companyID");
                      _loadWarehouses();
                    // do stuff
                  }
                },
              ),
              Focus(
                child: TextFormField(
                        controller: _unameController,
                        decoration: InputDecoration(
                          labelText: "username",
                          hintText: "please input username",
                          prefixIcon: Icon(Icons.person),
                        ),
                        // 校验用户名（不能为空）
                        validator: (v) {
                          return v.trim().isNotEmpty ? null : "username is required";
                        }),
                onFocusChange: (hasFocus) {
                  if(!hasFocus) {
                    print("V2. validate when leave username");
                    _loadWarehouses();
                    // do stuff
                  }
                },
              ),
              TextFormField(
                controller: _pwdController,
                decoration: InputDecoration(
                    labelText: "password",
                    hintText: "please input password",
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                          pwdShow ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          pwdShow = !pwdShow;
                        });
                      },
                    )),
                obscureText: !pwdShow,
                //校验密码（不能为空）
                validator: (v) {
                  return v.trim().isNotEmpty ? null : "password is required";
                },
              ),
              TextFormField(
                  controller: _rfCodeController, //设置controller
                  decoration: InputDecoration(
                      labelText: "RF code",
                      hintText: "RF code",
                      prefixIcon: Icon(Icons.web)
                  ),
                  //
                  validator: (v) {
                    return v
                        .trim()
                        .length > 0 ? null : "Please input a valid RF";
                  }
              ),
              Row(
                children: <Widget>[
                  Text("Warehouse"),
                  getDropDownButtonsColumnForWarehouse()
                ]
              ),
              Row(
                  children: <Widget>[

                    Checkbox(
                      value: _rememberMe,
                      activeColor: Colors.blue, //选中时的颜色
                      onChanged:(value){
                        //重新构建页面
                        setState(() {
                          _rememberMe=value;
                        });
                      },

                    ),
                    Text("Remember Me"),

                  ]
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: ConstrainedBox(
                  constraints: BoxConstraints.expand(height: 55.0),
                  child: RaisedButton(
                    color: Theme.of(context).primaryColor,
                    onPressed: _onLogin,
                    textColor: Colors.white,
                    child: Text("login"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getDropDownButtonsColumnForWarehouse(){
    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 40 , bottom: 5,top:5),
      child: Container(
        height: 35,  //gives the height of the dropdown button
        width: MediaQuery.of(context).size.width - 175, //gives the width of the dropdown button
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(3)),
            color: Color(0xFFF2F2F2)
        ),
        // padding: const EdgeInsets.symmetric(horizontal: 13), //you can include padding to control the menu items
        child: Theme(
            data: Theme.of(context).copyWith(
                canvasColor: Colors.yellowAccent, // background color for the dropdown items
                buttonTheme: ButtonTheme.of(context).copyWith(
                  alignedDropdown: true,  //If false (the default), then the dropdown's menu will be wider than its button.
                )
            ),
            child: DropdownButtonHideUnderline(  // to hide the default underline of the dropdown button
              child: DropdownButton<String>(
                iconEnabledColor: Color(0xFF595959),  // icon color of the dropdown button
                items: _validWarehouses.isEmpty ?
                [] : _validWarehouses.map((Warehouse warehouse) {
                  print("get name from warehouse:${warehouse.id} / ${warehouse.name}");
                  return new DropdownMenuItem<String>(
                    value: warehouse.id.toString(),
                    child: new Text(warehouse.name),
                  );
                }).toList(),
                hint: Text("empty warehouse",style: TextStyle(color: Color(0xFF8B8B8B),fontSize: 15),),  // setting hint
                onChanged: (String value){
                  setState(() {
                    selectedWarehouse = _validWarehouses.firstWhere((warehouse) => warehouse.name == value);

                  });
                },
                value: selectedWarehouse == null ? null :  selectedWarehouse.id.toString(),  // displaying the selected value
              ),
            )
        ),
      ),
    );
  }

  void _processAutoLogin(User user) async{
    print("start to process auto login with warehouse: ${Global.getAutoLoginWarehouse().id}");
    if (Global.getAutoLoginWarehouse() == null) {
      print("auto login fail as warehouse is not setup");

      showToast("warehouse is not setup for auto login");

    }
    else if (Global.getLastLoginRFCode() == null) {
      print("auto login fail as rf code is not setup");

      showToast("rf code is not setup for auto login");

    }
    else {

      // make sure the rf is still valid
      bool isRFCodeValid = await
          RFService.valdiateRFCode(Global.getAutoLoginWarehouse().id, Global.getLastLoginRFCode());
      if (!isRFCodeValid) {

        print("auto login fail as rf code ${Global.getLastLoginRFCode()} is not valid");

        showToast("rf code  ${Global.getLastLoginRFCode()} is not valid for auto login");
        return;
      }
      try {
        User autoLoginUser =
          await LoginService
              .login(user.companyId, user.username, user.password);

        print("auto login success");
        Global.setCurrentUser(autoLoginUser);

        print("login with user: ${autoLoginUser.username}, token: ${autoLoginUser.token}, into warehouse ${Global.getAutoLoginWarehouse().name}");
        Global.setCurrentWarehouse(Global.getAutoLoginWarehouse());

        // setup current company
        Global.lastLoginCompanyId = user.companyId;
        CompanyService.getCompanyById(user.companyId).then(
                (company) => Global.lastLoginCompanyCode = company.code);



        // TO-DO: as a temporary solution, we will init the
        // start location as the RF. It will be changed when
        // the user start any location based activity like
        // count, deposit, pick, etc.
        WarehouseLocationService.getWarehouseLocationByName(Global.lastLoginRFCode)
            .then((rfLocation) {
          print("start last activity location to ${rfLocation.name}");
          Global.setLastActivityLocation(rfLocation);
        });

        // get the latest app version and see if we will
        // need to upgrade the app
        RFAppVersion latestRFAppVersion = await RFAppVersionService.getLatestRFAppVersion();

        // let's check if we will need to update the
        bool _appNeedUpdate = await _needUpdate(latestRFAppVersion);
        if (_appNeedUpdate) {
          // ok, we will need to update the APP, we will flow into a new form to finish the
          // download and upgrade
          Navigator.of(context).pushNamed("app_upgrade", arguments: latestRFAppVersion);

        }
        else {
          Navigator.pushNamed(context, "menus_page");
        }
      } catch (e) {
        //登录失败则提示
        showToast(e.toString());
      }
    }

  }
  void _onLogin() async {
    // 先验证各个表单字段是否合法
    if ((_formKey.currentState as FormState).validate()) {
      print("start to login");
      showLoading(context);
      User user;
      int companyId;
      try {

        // make sure the rf code is still valid
        bool isRFCodeValid = await
            RFService.valdiateRFCode(selectedWarehouse.id, _rfCodeController.text);
        if (!isRFCodeValid) {

          print("auto login fail as rf code ${_rfCodeController.text} is not valid");

          showToast("rf code ${_rfCodeController.text} is not valid ");
          return;
        }

        print("will need to get company by code: " + _companyCodeController.text);
        companyId =
            await CompanyService.validateCompanyByCode(_companyCodeController.text);
        print("get by code: " + _companyCodeController.text + ", compnay id: " + companyId.toString());
        if (companyId == null) {

          showToast("Can't find company by code: " + _companyCodeController.text);

        }
        else {

          user = await LoginService
              .login(companyId, _unameController.text, _pwdController.text);
        }


      } catch (e) {
        //登录失败则提示
          showToast(e.toString());
      } finally {
        // 隐藏loading框
        Navigator.of(context).pop();
      }
      if (user != null) {
        //

        // 返回
        print("_rememberMe? $_rememberMe");


        // Setup auto login user
        if (_rememberMe) {
          user.password = _pwdController.text;
          user.companyId = companyId;
          Global.addAutoLoginUser(user);
          Global.setAutoLoginWarehouse(selectedWarehouse);
        }

        // setup current user
        Global.setCurrentUser(user);

        Global.setCurrentWarehouse(selectedWarehouse);

        // setup current company
        Global.lastLoginCompanyId = companyId;
        Global.lastLoginCompanyCode = _companyCodeController.text;
        Global.setLastLoginRFCode(_rfCodeController.text);

        // TO-DO: as a temporary solution, we will init the
        // start location as the RF. It will be changed when
        // the user start any location based activity like
        // count, deposit, pick, etc.
        WarehouseLocationService.getWarehouseLocationByName(Global.lastLoginRFCode)
            .then((rfLocation) {
          print("start last activity location to ${rfLocation.name}");
          Global.setLastActivityLocation(rfLocation);
        });


        print("login with user: ${user.username}, token: ${user.token}. companyCode: ${Global.lastLoginCompanyId}, company Id: ${Global.lastLoginCompanyCode}");

        RFAppVersion latestRFAppVersion = await RFAppVersionService.getLatestRFAppVersion();

        bool _appNeedUpdate = await _needUpdate(latestRFAppVersion);
        if (_appNeedUpdate) {
          Navigator.of(context).pushNamed("app_upgrade", arguments: latestRFAppVersion);
        }
        else {
          Navigator.pushNamed(context, "menus_page");
 
        }
        // Navigator.of(context).pop();
      }
    }
  }

  void _loadWarehouses() async {

    if (_companyCodeController.text.isEmpty || _unameController.text.isEmpty) {
      // we will need to get the company code and user name so we can know
      // which warehouse the user has access to
      // simply reset the valid warehouse to empty list will disable the control
      _validWarehouses = [];
      selectedWarehouse = null;
    }
    else {

      List<Warehouse> warehouses = await WarehouseService.getWarehouseByUser(
          _companyCodeController.text, _unameController.text
      );
      print("get ${warehouses.length} warheouses from server: ${warehouses.join('####')}");
      setState(() {

        _validWarehouses = warehouses;

        if (_validWarehouses.isNotEmpty) {
          // automatically select the first warehouse
          selectedWarehouse = _validWarehouses[0];
          print("set selectedWarehouses to ${_validWarehouses[0].name}");
        }
      });
    }
  }


  Future<String> _getCurrentVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;

  }

  Future<bool> _needUpdate(RFAppVersion latestAppVersion) async {
    if (latestAppVersion == null) {
      // we are not able to get the latest version,
      // suppose we are not need to upgrade
      return false;
    }

    String currentVersion = await _getCurrentVersion();
    String serverVersion = latestAppVersion.versionNumber;

    printLongLogMessage("current version: ${currentVersion}");
    printLongLogMessage("server version: ${serverVersion}");

    List<String> currentVersions = currentVersion.split(".");
    List<String> serverVersions = serverVersion.split(".");
    if (currentVersions.length != serverVersions.length) {
      printLongLogMessage("ERROR! current version's length doesn't match with server's version");
      return false;
    }
    for (int i = 0; i < currentVersions.length; i++) {
      if (int.parse(serverVersions[i]) > int.parse(currentVersions[i])) {
        printLongLogMessage("we will need to upgrade current app");
        return true;
      }
    }
    printLongLogMessage("we don't need to upgrade current app");
    return false;
  }
}