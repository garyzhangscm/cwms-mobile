import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/shared/models/http_response_wrapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

class LaunchPage extends StatefulWidget {
  LaunchPage({Key? key, this.enableDebugAutoConnect = true}) : super(key: key);

  final bool enableDebugAutoConnect;

  @override
  State<StatefulWidget> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage>
    with SingleTickerProviderStateMixin {
  // AutoConnect to certian server
  bool _autoConnect = false;

  TextEditingController? _serverURLController;

  final _formKey = new GlobalKey<FormState>();
  late final AnimationController _splashController;
  late final Animation<double> _splashScale;
  late final Animation<double> _splashFade;
  Timer? _splashTimer;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _splashScale = Tween<double>(begin: .94, end: 1).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeOutCubic),
    );
    _splashFade = CurvedAnimation(
      parent: _splashController,
      curve: Curves.easeOut,
    );
    // Keep the manual server-selection test path immediate while the normal
    // app launch gets the short branded transition.
    if (kDebugMode && !widget.enableDebugAutoConnect) {
      _showSplash = false;
    } else {
      _splashTimer = Timer(const Duration(milliseconds: 460), () {
        if (mounted) setState(() => _showSplash = false);
      });
    }
    CWMSSiteInformation? server = Global.getAutoConnectServer();
    print("get auto connect server? ${server == null ? '' : server.url}");

    if (kDebugMode && widget.enableDebugAutoConnect) {
      String url = 'https://prod.claytechsuite.com/api/';
      // in debug mode
      _serverURLController = TextEditingController(text: url);
      // text: 'http。 ://k8s-staging-zuulserv-707034e5d3-990722035.us-west-1.elb.amazonaws.com/api/');
      _autoConnect = true;
      printLongLogMessage("In debug mode, we will always auto connect");
      _onConnect(url, true);
    } else if (server != null) {
      // _serverURLController =  TextEditingController(text: server.url);
      _serverURLController = TextEditingController(text: server.url);

      _autoConnect = server.autoConnectFlag ?? false;
      _onAutoConnect(server);
    } else {
      _serverURLController =
          TextEditingController(text: 'https://prod.claytechsuite.com/api/');
      _autoConnect = true;
    }
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _splashController.dispose();
    _serverURLController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return _buildSplash();
    return _buildServerSelection();
  }

  Widget _buildSplash() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: Center(
        child: AnimatedBuilder(
          animation: _splashController,
          builder: (context, child) => FadeTransition(
            opacity: _splashFade,
            child: Transform.scale(scale: _splashScale.value, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/icon/claytech_one_grid.png',
                  width: 112,
                  height: 112,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Claytech One',
                style: TextStyle(
                  color: Color(0xFF142D4E),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerSelection() {
    return Scaffold(
      appBar: AppBar(
        title: Text(CWMSLocalizations.of(context).chooseServer),
      ),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: EdgeInsets.all(18),
        child: Form(
          key: _formKey, //设置globalKey，用于后面获取FormState
          autovalidateMode: AutovalidateMode.always, //开启自动校验
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                  autofocus: true,
                  controller: _serverURLController, //设置controller
                  decoration: InputDecoration(
                    labelText: "Server URL",
                    hintText: "Server URL",
                    prefixIcon: Icon(Icons.web),
                    suffixIcon: IconButton(
                      onPressed: () => _clearField(),
                      icon: Icon(Icons.close),
                    ),
                  ),
                  //
                  validator: (v) {
                    return v!.trim().length > 0
                        ? null
                        : "Please input a valid server";
                  }),
              Row(children: <Widget>[
                Checkbox(
                  value: _autoConnect,
                  activeColor: Colors.blue, //选中时的颜色
                  onChanged: (value) {
                    //重新构建页面
                    setState(() {
                      _autoConnect = value ?? false;
                    });
                  },
                ),
                Text("Auto Connect"),
              ]),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
                // color: Colors.blue,
                // highlightColor: Colors.blue[700],
                // colorBrightness: Brightness.dark,
                // splashColor: Colors.grey,
                child: Text("Connect"),
                // shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _onConnect(_serverURLController!.text, _autoConnect);
                  }
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  _clearField() {
    _serverURLController!.text = "";
  }

  void _onAutoConnect(CWMSSiteInformation server) async {
    _onConnect(server.url ?? "", true);
  }

  // connect to the server
  // autoConnecting: Whether we are automatically connecting or user key in the
  //    url and connect
  void _onConnect(String serverUrl, bool autoConnectFlag) async {
    // showLoading(context);
    CWMSSiteInformation? server;
    try {
      print("start to connect to $serverUrl");
      Response response = await Dio().get(serverUrl + "/resource/mobile");

      print("get response from server \n: $response");

      HttpResponseWrapper httpResponseWrapper =
          HttpResponseWrapper.fromJson(json.decode(response.toString()));

      if (httpResponseWrapper.result == 0) {
        // ok, we can connect to the server. Add it to the history
        //
        server = CWMSSiteInformation.fromJson(httpResponseWrapper.data!);

        print("extracted the server");
        // The server will return the name / description / version
        // we will set the url and auto connection flag based on
        // user's input
        if (!serverUrl.endsWith("/")) {
          serverUrl += "/";
        }

        server.url = serverUrl;
        server.autoConnectFlag = autoConnectFlag;
        print("finished setup the server infor");
      }
    } catch (e) {
      //登录失败则提示
      print(e.toString());
      // showToast(e.toString());
      showToast("Can't connect to server $serverUrl");
      return;
    } finally {
      // 隐藏loading框
      // Navigator.of(context).pop();
    }
    if (server != null) {
      // 返回
      Global.addServer(server);
      Global.setCurrentServer(server);

      printLongLogMessage("start login process");
      Navigator.pushNamed(context, "login_page");
    }
  }
}
