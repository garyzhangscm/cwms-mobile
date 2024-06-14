
import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/auth/services/login.dart';
import 'package:cwms_mobile/common/services/rf.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/models/rf_app_version.dart';
import 'package:cwms_mobile/shared/services/rf_app_version.dart';
import 'package:cwms_mobile/shared/services/rf_configuration.dart';
import 'package:cwms_mobile/shared/services/warehouse_configuration.dart';


import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/services/company.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

import '../../shared/models/rf.dart';
import '../../warehouse_layout/models/warehouse_location.dart';

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
  TextEditingController _currentLocationController = new TextEditingController();
  List<Warehouse> _validWarehouses = [];
  Warehouse selectedWarehouse;
  bool pwdShow = false;
  GlobalKey _formKey = new GlobalKey<FormState>();

  bool _rememberMe = false;
  String defaultCompanyCode = "";

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
    if (_companyCodeController.text.isNotEmpty) {
      _loadWarehouses();
    }
    _rfCodeController = TextEditingController(
        text: Global.getLastLoginRFCode());

  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).login)),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          // autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[
              _buildCompanyCodeControl(context),
              _buildUserNameControl(context),
              _buildPasswordControl(context),
              _buildRFCodeControl(context),
              _buildWarehouseControl(context),
              _buildCurrentLocationControl(context),
              _buildRememberMeControl(context),
              _buildButtons(context)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context){
    return
      Padding(
        padding: const EdgeInsets.only(top: 5),
        child: ConstrainedBox(
          constraints: BoxConstraints.expand(height: 55.0),
          child: ElevatedButton(

            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).primaryColor,
            ),
            onPressed: selectedWarehouse == null ?  null : _onLogin,
            child: Text("login"),
          ),
        ),
      );
  }
  Widget _buildRememberMeControl(BuildContext context){
    return
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
      );
  }
  Widget _buildWarehouseControl(BuildContext context){
    return
      Row(
          children: <Widget>[
            Text("Warehouse"),
            getDropDownButtonsColumnForWarehouse()
          ]
      );
  }
  Widget _buildRFCodeControl(BuildContext context){

    return
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
      );
  }
  Widget _buildCurrentLocationControl(BuildContext context){

    return
      TextFormField(
          controller: _currentLocationController, //设置controller
          decoration: InputDecoration(
              labelText: CWMSLocalizations
                  .of(context)
                  .currentLocation,
              hintText: CWMSLocalizations
                  .of(context)
                  .inputLocationHint,
              prefixIcon: Icon(Icons.web)
          ),
          //
          validator: (v) {
            return v
                .trim()
                .length > 0 ? null : "Please input a valid location";
          }
      );
  }
  Widget _buildPasswordControl(BuildContext context){

    return TextFormField(
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
    );
  }
  Widget _buildUserNameControl(BuildContext context){
    return
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
      );
  }

  Widget _buildCompanyCodeControl(BuildContext context){
    return Focus(
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
    else if (Global.getAutoLoginCompany() == null) {
      print("auto login fail as company is not setup");

      showToast("company is not setup for auto login");

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
      setState(() {
          selectedWarehouse = Global.getAutoLoginWarehouse();
          _rfCodeController.text = Global.getLastLoginRFCode();

          _companyCodeController.text = Global.getAutoLoginCompany().code;
          _unameController.text = user.username;
          _pwdController.text = user.password;
          _rememberMe = true;
        });

        _onLogin();

        /**
         * User autoLoginUser =
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
            RFAppVersion latestRFAppVersion = await RFAppVersionService.getLatestRFAppVersion(Global.lastLoginRFCode);

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
         *
         */
    }

  }
  void _onLogin() async {
    // 先验证各个表单字段是否合法
    if ((_formKey.currentState as FormState).validate()) {
      print("start to login");
      showLoading(context);
      User user;
      int companyId;

      WarehouseLocation currentLocation;

      try {
        // make sure the rf code is still valid

        bool isRFCodeValid = await
            RFService.valdiateRFCode(selectedWarehouse.id, _rfCodeController.text);

        if (!isRFCodeValid) {

          print("login fail as rf code ${_rfCodeController.text} is not valid");

          showToast("rf code ${_rfCodeController.text} is not valid ");
          return;
        }


        print("start to validate the location ${_currentLocationController.text}");
        bool isLocationValid = await
            WarehouseLocationService.valdiateLocation(selectedWarehouse.id, _currentLocationController.text);

        if (!isLocationValid) {

          print("login fail as location  ${_currentLocationController.text} is not valid");

          showToast("location ${_currentLocationController.text} is not valid ");
          return;
        }

        print("will need to get company by code: " + _companyCodeController.text);
        companyId =
            await CompanyService.validateCompanyByCode(_companyCodeController.text);
        print("get by code: ${_companyCodeController.text}, companyId id: $companyId ");
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
        showLoading(context);

        // 返回
        print("_rememberMe? $_rememberMe");

        // setup current user
        Global.setCurrentUser(user);
        Global.setCurrentWarehouse(selectedWarehouse);
        // setup current company
        Global.lastLoginCompanyId = companyId;
        Global.lastLoginCompanyCode = _companyCodeController.text;


        Global.setLastLoginRFCode(_rfCodeController.text);

        // setup the http client with auth information
        Global.setupHttpClient();

        // load the configuration and cache
        Global.initInventoryConfiguration();


        // setup the rf and location

        RF rf = await RFService.getRFByCodeAndWarehouseId(
            selectedWarehouse.id, _rfCodeController.text);

        WarehouseLocation currentLocation = await WarehouseLocationService.getWarehouseLocationByWarehouseIdAndName(
                  selectedWarehouse.id, _currentLocationController.text);

        Global.setLastActivityLocation(currentLocation);
        rf = await RFService.changeRFLocation(selectedWarehouse.id, rf.id, currentLocation.id);
        Global.setLastLoginRF(rf);


        // Setup auto login user
        if (_rememberMe) {
          user.password = _pwdController.text;
          user.companyId = companyId;
          Global.addAutoLoginUser(user);
          Global.setAutoLoginWarehouse(selectedWarehouse);
          CompanyService.getCompanyByCode(_companyCodeController.text)
              .then((company)  {
                Global.setAutoLoginCompany(company);
                printLongLogMessage("auto login company is setup to ${company.name}");
              });

        }


        print("login with user: ${user.username}, token: ${user.token}. companyCode: ${Global.lastLoginCompanyId}, company Id: ${Global.lastLoginCompanyCode}");

        // load the rf configuration
        try {

          RFConfigurationService.getRFConfiguration(Global.lastLoginRFCode).then((rfConfiguration) {
              // if the configuration is not setup yet, use the default one
            // which should be already setup when we launch the app
              if (rfConfiguration != null) {

                Global.setRFConfiguration(rfConfiguration);
              }
          });
        }
        on WebAPICallException catch(ex) {
          // ignore the except and continue with the default configuration

        }
        // load the warehouse configuration
        try {

          WarehouseConfigurationService.getWarehouseConfiguration().then((warehouseConfiguration) {
            // if the configuration is not setup yet, use the default one
            // which should be already setup when we launch the app
            if (warehouseConfiguration != null) {

              Global.setWarehouseConfiguration(warehouseConfiguration);
            }
          });
        }
        on WebAPICallException catch(ex) {
          // ignore the except and continue with the default configuration

        }

        RFAppVersion latestRFAppVersion = await RFAppVersionService.getLatestRFAppVersion(Global.lastLoginRFCode);

        printLongLogMessage("latestRFAppVersion: ${latestRFAppVersion == null ? "N/A" : latestRFAppVersion.versionNumber}");

        bool _appNeedUpdate = false;
        if (latestRFAppVersion == null) {
          _appNeedUpdate = false;
        }
        else {
          _appNeedUpdate = await _needUpdate(latestRFAppVersion);
        }
        Navigator.of(context).pop();

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
      setState(() {
        _validWarehouses = [];
        selectedWarehouse = null;

      });
    }
    else {

      showLoading(context);
      List<Warehouse> warehouses = await WarehouseService.getWarehouseByUser(
          _companyCodeController.text, _unameController.text
      );
      Navigator.of(context).pop();

      if (warehouses == null || warehouses.isEmpty) {
        showErrorToast(CWMSLocalizations.of(context).cannotFindWarehouse);
        setState(() {
          _validWarehouses = [];
          selectedWarehouse = null;

        });
        return;

      }
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
      else if (int.parse(serverVersions[i]) < int.parse(currentVersions[i])) {
        // local version is greater than the server version, we will stop here
        // we don't need to compare the lower version digit
        return false;
      }
      // if the version digit is the same for local version and server version,
      // let's continue with the next minor version number
    }
    printLongLogMessage("we don't need to upgrade current app");
    return false;
  }
}