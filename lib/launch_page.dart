
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/shared/models/http_response_wrapper.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
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
  TextEditingController _rfCodeController;

  final _formKey= new GlobalKey<FormState>();


  @override
  void initState(){
    super.initState();
    CWMSSiteInformation server = Global.getAutoConnectServer();
    _rfCodeController = TextEditingController(
        text: Global.getLastLoginRFCode());
    print("get auto connect server? ${server == null? '' : server.url}");

    if (server != null) {

      // _serverURLController =  TextEditingController(text: server.url);
      _serverURLController =  TextEditingController(text: server.url);

      _autoConnect = server.autoConnectFlag;
      _onAutoConnect(server);
    }
    else {
      _serverURLController =  TextEditingController(text: '');
      _autoConnect = true;
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CWMSLocalizations.of(context).chooseServer),
      ),
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
                      prefixIcon: Icon(Icons.web)
                  ),
                  //
                  validator: (v) {
                    return v
                        .trim()
                        .length > 0 ? null : "Please input a valid server";
                  }
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
              RaisedButton(
                color: Colors.blue,
                highlightColor: Colors.blue[700],
                colorBrightness: Brightness.dark,
                splashColor: Colors.grey,
                child: Text("Connect"),
                shape:RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
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


  void _onAutoConnect(CWMSSiteInformation server) async  {

    _onConnect(server.url, true);
    /***
    try {
      Response response = await Dio().get(server.url + "/resource/mobile");
      HttpResponseWrapper httpResponseWrapper =
          HttpResponseWrapper.fromJson(json.decode(response.toString()));

      // if we can connect, then flow to
      Global.setCurrentServer(server);
      Global.setCurrentLoginRFCode(Global.getAutoLoginRFCode());
      Navigator.pushNamed(context, "login_page");
    } catch (e) {
      //登录失败则提示
      print(e.toString());
    }
        ***/


  }
  // connect to the server
  // autoConnecting: Whether we are automatically connecting or user key in the
  //    url and connect
  void _onConnect(String serverUrl, bool autoConnectFlag) async {


      // showLoading(context);
      CWMSSiteInformation server;
      String rfCode = _rfCodeController.text;
      try {
        print("start to connect to $serverUrl");
        Response response = await Dio().get(
            serverUrl + "/resource/mobile",
            queryParameters: {"rfCode": rfCode});

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
        showToast(e.toString());
      } finally {
        // 隐藏loading框
        // Navigator.of(context).pop();
      }
      if (server != null) {
        // 返回
        Global.addServer(server);
        Global.setCurrentServer(server);
        Global.setLastLoginRFCode(rfCode);

        Navigator.pushNamed(context, "login_page");
      }

  }


}
