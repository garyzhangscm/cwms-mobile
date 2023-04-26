
import 'dart:ui';

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/models/cwms_http_client_wrapper.dart';
import 'package:cwms_mobile/shared/models/cwms_http_config.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/shared/models/http_response_wrapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';




class LaunchPage extends StatefulWidget{

  LaunchPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _LaunchPageState();

}

class _LaunchPageState extends State<LaunchPage> {

  // AutoConnect to certian server
  bool _autoConnect;

  TextEditingController _serverURLController;

  final _formKey= new GlobalKey<FormState>();



  @override
  void initState(){
    super.initState();
    CWMSSiteInformation server = Global.getAutoConnectServer();
    print("get auto connect server? ${server == null? '' : server.url}");

    if (kDebugMode) {

      // in debug mode
      _serverURLController =  TextEditingController(
          text: 'https://prod.claytechsuite.com/api/');
          // text: 'http。 ://k8s-staging-zuulserv-707034e5d3-990722035.us-west-1.elb.amazonaws.com/api/');
      _autoConnect = true;
      printLongLogMessage("In debug mode, we will always auto connect");
      _onAutoConnect(server);
    }
    else if (server != null) {

      // _serverURLController =  TextEditingController(text: server.url);
      _serverURLController =  TextEditingController(text: server.url);

      _autoConnect = server.autoConnectFlag;
      _onAutoConnect(server);
    }
    else {
      _serverURLController =  TextEditingController(text: 'http://10.0.10.37:32262/api/');
      _autoConnect = true;
    }
  }


  @override
  Widget build(BuildContext context) {
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
                      suffixIcon:
                        IconButton(
                          onPressed: () => _clearField(),
                          icon: Icon(Icons.close),
                        ),
                  ),
                  //
                  validator: (v) {
                    return v
                        .trim()
                        .length > 0 ? null : "Please input a valid server";
                  }
              ),
              Row(
                  children: <Widget>[

                    Checkbox(
                      value: _autoConnect,
                      activeColor: Colors.blue, //选中时的颜色
                      onChanged:(value){
                        //重新构建页面
                        setState(() {
                          _autoConnect=value;
                        });
                      },

                    ),
                    Text("Auto Connect"),

                  ]
              ),
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
                  if (_formKey.currentState.validate()) {
                     _onConnect(_serverURLController.text, _autoConnect);

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
    _serverURLController.text = "";
  }

  void _onAutoConnect(CWMSSiteInformation server) async  {

    _onConnect(server.url, true);

  }
  // connect to the server
  // autoConnecting: Whether we are automatically connecting or user key in the
  //    url and connect
  void _onConnect(String serverUrl, bool autoConnectFlag) async {


      // showLoading(context);
      CWMSSiteInformation server;
      try {
        print("start to connect to $serverUrl");
        Response response = await Dio().get(
            serverUrl + "/resource/mobile");

        print("get response: $response");


        HttpResponseWrapper httpResponseWrapper =
            HttpResponseWrapper.fromJson(json.decode(response.toString()));

        if (httpResponseWrapper.result == 0) {
          // ok, we can connect to the server. Add it to the history
          //
          server = CWMSSiteInformation.fromJson(httpResponseWrapper.data);

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


        Navigator.pushNamed(context, "login_page");


      }

  }




}
