import 'dart:io';

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
import 'package:cwms_mobile/shared/workspace_ui.dart';

import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/services/company.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:collection/collection.dart';

import '../../shared/models/rf.dart';
import '../../warehouse_layout/models/warehouse_location.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController _companyCodeController = new TextEditingController();
  TextEditingController _unameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  TextEditingController _rfCodeController = new TextEditingController();
  TextEditingController _currentLocationController =
      new TextEditingController();
  List<Warehouse> _validWarehouses = [];
  Warehouse? selectedWarehouse;
  bool pwdShow = false;
  GlobalKey _formKey = new GlobalKey<FormState>();

  bool _rememberMe = false;
  String defaultCompanyCode = "";

  @override
  void initState() {
    super.initState();
    // check if this is a single company site

    if (Global.geturrentServer().isSingleCompanySite() == true) {
      defaultCompanyCode = Global.geturrentServer().getDefaultCompanyCode()!;
    } else {
      defaultCompanyCode = Global.lastLoginCompanyCode ?? "";
    }
    _companyCodeController.text = defaultCompanyCode;
    // check if auto login
    printLongLogMessage("see if we can auto login");

    if (Global.autoLoginUser != null) {
      _processAutoLogin(Global.autoLoginUser!);
    }
    _validWarehouses = [];

    if (_companyCodeController.text.isNotEmpty) {
      printLongLogMessage("start to load warehouse");
      _loadWarehouses();
    }
    _rfCodeController =
        TextEditingController(text: Global.getLastLoginRFCode());
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CWMSLocalizations.of(context);
    final serverUrl = Global.geturrentServer().url ?? '';
    return Scaffold(
      backgroundColor: workspaceBackground,
      appBar: AppBar(
        title: Text(localizations.login),
        backgroundColor: workspaceBackground,
        foregroundColor: workspaceNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLoginHero(context, serverUrl),
                  const SizedBox(height: 12),
                  Theme(
                    data: Theme.of(context).copyWith(
                      inputDecorationTheme: InputDecorationTheme(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0xFFE3E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: workspaceBlue, width: 1.5)),
                        errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFFD85D67))),
                        focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Color(0xFFD85D67), width: 1.5)),
                        prefixIconColor: const Color(0xFF73839A),
                        labelStyle: const TextStyle(color: Color(0xFF73839A)),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .72),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFE4E9F1))),
                        child: Column(children: [
                          _buildSectionLabel(context, 'Account & access'),
                          _buildCompanyCodeControl(context),
                          const SizedBox(height: 8),
                          _buildUserNameControl(context),
                          const SizedBox(height: 8),
                          _buildPasswordControl(context),
                          const SizedBox(height: 14),
                          _buildSectionLabel(context, 'Workstation'),
                          _buildRFCodeControl(context),
                          const SizedBox(height: 8),
                          _buildWarehouseControl(context),
                          const SizedBox(height: 4),
                          _buildCurrentLocationControl(context),
                          const SizedBox(height: 6),
                          _buildRememberMeControl(context),
                          const SizedBox(height: 6),
                          _buildButtons(context),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                      child: Text('Secure access to your operations',
                          style: TextStyle(
                              color: Color(0xFF8A97A9), fontSize: 12))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginHero(BuildContext context, String serverUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: workspaceNavy, borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.layers_rounded,
                color: Color(0xFFBBD2FF), size: 22)),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Claytech One',
                style: TextStyle(
                    color: workspaceNavy,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
            const SizedBox(height: 3),
            Text(
                workspaceIsChinese(context)
                    ? '欢迎回来，登录以继续工作'
                    : 'Welcome back. Sign in to continue.',
                style: const TextStyle(color: Color(0xFF7B8798), fontSize: 12)),
            if (serverUrl.isNotEmpty)
              Text(serverUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFF9AA8B9), fontSize: 10)),
          ]),
        ),
        if (serverUrl.isNotEmpty)
          const Icon(Icons.verified_user_outlined,
              color: Color(0xFF9AA8B9), size: 18),
      ]),
      /*
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.layers_rounded,
                  color: Color(0xFFBBD2FF), size: 25)),
          const SizedBox(width: 12),
            const Text('Claytech One',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2)),
        ]),
        const SizedBox(height: 24),
        Text(workspaceIsChinese(context) ? '欢迎回来' : 'Welcome back',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
            workspaceIsChinese(context)
                ? '登录以继续管理你的仓储作业。'
                : 'Sign in to continue managing your operations.',
            style: const TextStyle(color: Color(0xFFC3D3EA), fontSize: 14)),
        if (serverUrl.isNotEmpty) ...[
          const SizedBox(height: 18),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.cloud_done_outlined,
                    color: Color(0xFF9BC3FF), size: 16),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(serverUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFFC3D3EA), fontSize: 12)))
              ])),
        ],
      ]),*/
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) => Align(
      alignment: Alignment.centerLeft,
      child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(label.toUpperCase(),
              style: const TextStyle(
                  color: Color(0xFF7B8BA1),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2))));

  Widget _buildButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: workspaceBlue,
          disabledBackgroundColor: const Color(0xFFB9C5D8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: selectedWarehouse == null ? null : _onLogin,
        child: Text(CWMSLocalizations.of(context).login,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildRememberMeControl(BuildContext context) {
    return Row(children: <Widget>[
      Checkbox(
        value: _rememberMe,
        activeColor: workspaceBlue,
        onChanged: (value) {
          //重新构建页面
          setState(() {
            _rememberMe = value!;
          });
        },
      ),
      const Text("Remember Me", style: TextStyle(color: Color(0xFF61718A))),
    ]);
  }

  Widget _buildWarehouseControl(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.only(left: 4, bottom: 6),
        child: Text('Warehouse',
            style: TextStyle(color: Color(0xFF73839A), fontSize: 12)),
      ),
      getDropDownButtonsColumnForWarehouse(),
    ]);
  }

  Widget _buildRFCodeControl(BuildContext context) {
    return TextFormField(
        controller: _rfCodeController, //设置controller
        decoration: InputDecoration(
            labelText: "RF code",
            hintText: "RF code",
            prefixIcon: Icon(Icons.web)),
        //
        validator: (v) {
          return v!.trim().length > 0 ? null : "Please input a valid RF";
        });
  }

  Widget _buildCurrentLocationControl(BuildContext context) {
    return TextFormField(
        controller: _currentLocationController, //设置controller
        decoration: InputDecoration(
            labelText: CWMSLocalizations.of(context).currentLocation,
            hintText: CWMSLocalizations.of(context).inputLocationHint,
            prefixIcon: Icon(Icons.web)),
        //
        validator: (v) {
          return v!.trim().length > 0 ? null : "Please input a valid location";
        });
  }

  Widget _buildPasswordControl(BuildContext context) {
    return TextFormField(
      controller: _pwdController,
      decoration: InputDecoration(
          labelText: "password",
          hintText: "please input password",
          prefixIcon: Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(pwdShow ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                pwdShow = !pwdShow;
              });
            },
          )),
      obscureText: !pwdShow,
      //校验密码（不能为空）
      validator: (v) {
        return v!.trim().isNotEmpty ? null : "password is required";
      },
    );
  }

  Widget _buildUserNameControl(BuildContext context) {
    return Focus(
      child: TextFormField(
          controller: _unameController,
          decoration: InputDecoration(
            labelText: "username",
            hintText: "please input username",
            prefixIcon: Icon(Icons.person),
          ),
          // 校验用户名（不能为空）
          validator: (v) {
            return v!.trim().isNotEmpty ? null : "username is required";
          }),
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          print("V2. validate when leave username");
          _loadWarehouses();
          // do stuff
        }
      },
    );
  }

  Widget _buildCompanyCodeControl(BuildContext context) {
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
            return v!.trim().isNotEmpty ? null : "company code is required";
          }),
      onFocusChange: (hasFocus) {
        if (!hasFocus) {
          print("V2. validate when leave companyID");
          _loadWarehouses();
          // do stuff
        }
      },
    );
  }

  Widget getDropDownButtonsColumnForWarehouse() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFFF8F9FB),
            border: Border.all(color: const Color(0xFFE3E8F0))),
        // padding: const EdgeInsets.symmetric(horizontal: 13), //you can include padding to control the menu items
        child: Theme(
            data: Theme.of(context).copyWith(
                canvasColor: Colors.white,
                buttonTheme: ButtonTheme.of(context).copyWith(
                  alignedDropdown:
                      true, //If false (the default), then the dropdown's menu will be wider than its button.
                )),
            child: DropdownButtonHideUnderline(
              // to hide the default underline of the dropdown button
              child: DropdownButton<String>(
                iconEnabledColor: const Color(0xFF73839A),
                items: _validWarehouses.isEmpty
                    ? []
                    : _validWarehouses.map((Warehouse warehouse) {
                        print(
                            "get name from warehouse:${warehouse.id} / ${warehouse.name}");
                        return new DropdownMenuItem<String>(
                          value: warehouse.id.toString(),
                          child: new Text(warehouse.name ?? ""),
                        );
                      }).toList(),
                hint: Text(
                  "empty warehouse",
                  style:
                      const TextStyle(color: Color(0xFF8B8B8B), fontSize: 14),
                ), // setting hint
                onChanged: (String? value) {
                  setState(() {
                    selectedWarehouse = _validWarehouses.firstWhereOrNull(
                        (warehouse) => warehouse.name == value);
                  });
                },
                value: selectedWarehouse == null
                    ? null
                    : selectedWarehouse!.id
                        .toString(), // displaying the selected value
              ),
            )),
      ),
    );
  }

  void _processAutoLogin(User user) async {
    print(
        "start to process auto login with warehouse: ${Global.getAutoLoginWarehouse().id}");
// make sure the rf is still valid
    bool isRFCodeValid = await RFService.valdiateRFCode(
        Global.getAutoLoginCompany().id!,
        Global.getAutoLoginWarehouse().id!,
        Global.getLastLoginRFCode());
    if (!isRFCodeValid) {
      print(
          "auto login fail as rf code ${Global.getLastLoginRFCode()} is not valid");

      showToast(
          "rf code  ${Global.getLastLoginRFCode()} is not valid for auto login");
      return;
    }
    setState(() {
      selectedWarehouse = Global.getAutoLoginWarehouse();
      _rfCodeController.text = Global.getLastLoginRFCode();

      _companyCodeController.text = Global.getAutoLoginCompany().code!;
      _unameController.text = user.username!;
      _pwdController.text = user.password!;
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

  void _onLogin() async {
    // 先验证各个表单字段是否合法
    if ((_formKey.currentState as FormState).validate()) {
      print("start to login");
      showLoading(context);
      User? user;
      int? companyId;

      WarehouseLocation currentLocation;

      try {
        // make sure the rf code is still valid

        print(
            "will need to get company by code: " + _companyCodeController.text);
        companyId = await CompanyService.validateCompanyByCode(
            _companyCodeController.text);
        print(
            "get by code: ${_companyCodeController.text}, companyId id: $companyId ");

        if (companyId == null) {
          showToast(
              "Can't find company by code: " + _companyCodeController.text);
          return;
        }

        printLongLogMessage(
            "start to validate rf code ${_rfCodeController.text}");
        bool isRFCodeValid = await RFService.valdiateRFCode(
            companyId, selectedWarehouse!.id!, _rfCodeController.text);

        if (!isRFCodeValid) {
          print("login fail as rf code ${_rfCodeController.text} is not valid");

          showToast("rf code ${_rfCodeController.text} is not valid ");
          return;
        }

        print(
            "start to validate the location ${_currentLocationController.text}");
        bool isLocationValid = await WarehouseLocationService.valdiateLocation(
            companyId, selectedWarehouse!.id!, _currentLocationController.text);

        if (!isLocationValid) {
          print(
              "login fail as location  ${_currentLocationController.text} is not valid");

          showToast(
              "location ${_currentLocationController.text} is not valid ");
          return;
        }
        user = await LoginService.login(
            companyId, _unameController.text, _pwdController.text);

        printLongLogMessage("user ${user.username} login successfully ");
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
        Global.setCurrentWarehouse(selectedWarehouse!);
        // setup current company
        Global.lastLoginCompanyId = companyId!;
        Global.lastLoginCompanyCode = _companyCodeController.text;

        Global.setLastLoginRFCode(_rfCodeController.text);

        // setup the http client with auth information
        Global.setupHttpClient();

        // load the configuration and cache
        Global.initInventoryConfiguration();

        // setup the rf and location

        RF rf = await RFService.getRFByCodeAndWarehouseId(
            selectedWarehouse!.id!, _rfCodeController.text);

        WarehouseLocation currentLocation = await WarehouseLocationService
            .getWarehouseLocationByWarehouseIdAndName(
                selectedWarehouse!.id!, _currentLocationController.text);

        Global.setLastActivityLocation(currentLocation);
        printLongLogMessage(
            "start to change rf ${rf.rfCode}'s current location to ${currentLocation.id} / ${currentLocation.name}");
        rf = await RFService.changeRFLocation(
            selectedWarehouse!.id!, rf.id!, currentLocation.id!);
        print(
            ">>> rf ${rf.rfCode}'s current location is changed to ${rf.currentLocation?.name}");

        Global.setLastLoginRF(rf);

        // Setup auto login user
        if (_rememberMe) {
          user.password = _pwdController.text;
          user.companyId = companyId;
          Global.addAutoLoginUser(user);
          Global.setAutoLoginWarehouse(selectedWarehouse!);
          CompanyService.getCompanyByCode(_companyCodeController.text)
              .then((company) {
            Global.setAutoLoginCompany(company!);
            printLongLogMessage(
                "auto login company is setup to ${company.name}");
          });
        }

        print(
            "login with user: ${user.username}, token: ${user.token}. companyCode: ${Global.lastLoginCompanyId}, company Id: ${Global.lastLoginCompanyCode}");

        // load the rf configuration
        try {
          final rfConfiguration =
              await RFConfigurationService.getRFConfiguration(
                  Global.lastLoginRFCode!);
          // If the configuration is not setup yet, keep the default one.
          if (rfConfiguration != null) {
            Global.setRFConfiguration(rfConfiguration);
            printLongLogMessage(
                "rf configuration is setup to ${rfConfiguration.toJson()}");
          }
        } on WebAPICallException {
          // ignore the except and continue with the default configuration
        }
        // load the warehouse configuration
        try {
          WarehouseConfigurationService.getWarehouseConfiguration()
              .then((warehouseConfiguration) {
            // if the configuration is not setup yet, use the default one
            // which should be already setup when we launch the app
            if (warehouseConfiguration != null) {
              Global.setWarehouseConfiguration(warehouseConfiguration);
            }
          });
        } on WebAPICallException {
          // ignore the except and continue with the default configuration
        }

        RFAppVersion? latestRFAppVersion =
            await RFAppVersionService.getLatestRFAppVersion(
                Global.lastLoginRFCode!);

        printLongLogMessage(
            "latestRFAppVersion: ${latestRFAppVersion == null ? "N/A" : latestRFAppVersion.versionNumber}");

        bool _appNeedUpdate = false;
        if (latestRFAppVersion == null) {
          _appNeedUpdate = false;
        } else {
          _appNeedUpdate = await _needUpdate(latestRFAppVersion);
        }
        Navigator.of(context).pop();

        if (_appNeedUpdate) {
          Navigator.of(context)
              .pushNamed("app_upgrade", arguments: latestRFAppVersion);
        } else {
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
    } else {
      showLoading(context);
      List<Warehouse> warehouses = await WarehouseService.getWarehouseByUser(
          _companyCodeController.text, _unameController.text);
      Navigator.of(context).pop();

      if (warehouses.isEmpty) {
        showErrorToast(CWMSLocalizations.of(context).cannotFindWarehouse);
        setState(() {
          _validWarehouses = [];
          selectedWarehouse = null;
        });
        return;
      }
      print(
          "get ${warehouses.length} warheouses from server: ${warehouses.join('####')}");
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
    // iOS updates are distributed through MDM, TestFlight, or the App Store.
    // The server-provided package handled below is an Android APK.
    if (Platform.isIOS) {
      return false;
    }

    String currentVersion = await _getCurrentVersion();
    String serverVersion = latestAppVersion.versionNumber!;

    printLongLogMessage("current version: ${currentVersion}");
    printLongLogMessage("server version: ${serverVersion}");

    List<String> currentVersions = currentVersion.split(".");
    List<String> serverVersions = serverVersion.split(".");
    if (currentVersions.length != serverVersions.length) {
      printLongLogMessage(
          "ERROR! current version's length doesn't match with server's version");
      return false;
    }
    for (int i = 0; i < currentVersions.length; i++) {
      if (int.parse(serverVersions[i]) > int.parse(currentVersions[i])) {
        printLongLogMessage("we will need to upgrade current app");
        return true;
      } else if (int.parse(serverVersions[i]) < int.parse(currentVersions[i])) {
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
