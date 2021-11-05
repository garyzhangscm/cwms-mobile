
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

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
import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:open_file/open_file.dart';
import 'dart:convert';

import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_dialog/progress_dialog.dart';



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

  ProgressDialog pr;
  ReceivePort _port = ReceivePort();


  // app name and path
  String _appName ='';
  String _appPath = '';


  @override
  void initState(){
    super.initState();
    CWMSSiteInformation server = Global.getAutoConnectServer();
    print("get auto connect server? ${server == null? '' : server.url}");

    if (server != null) {

      // _serverURLController =  TextEditingController(text: server.url);
      _serverURLController =  TextEditingController(text: server.url);

      _autoConnect = server.autoConnectFlag;
      _onAutoConnect(server);
    }
    else {
      _serverURLController =  TextEditingController(text: 'http://10.0.10.37:30130/api/');
      _autoConnect = true;
    }

    // init tools for the upgrade current app
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen(_updateDownLoadInfo);
    FlutterDownloader.registerCallback(_downLoadCallback);

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
        showToast(e.toString());
      } finally {
        // 隐藏loading框
        // Navigator.of(context).pop();
      }
      if (server != null) {
        // 返回
        Global.addServer(server);
        Global.setCurrentServer(server);
        // let's check if we will need to update the
        bool _appNeedUpdate = await _needUpdate(server.rfAppVersion);
        if (_appNeedUpdate) {
          // install the latest version of the app from server

          _updateApp(context, serverUrl, server.rfAppVersion, server.rfAppName);

        }
        else {

          Navigator.pushNamed(context, "login_page");
        }


      }

  }

  Future<String> _getCurrentVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    printLongLogMessage("package info / appName: ${packageInfo.appName}");
    printLongLogMessage("package info / buildNumber: ${packageInfo.buildNumber}");
    printLongLogMessage("package info / packageName: ${packageInfo.packageName}");
    printLongLogMessage("package info / version: ${packageInfo.version}");
    return packageInfo.version;

  }

  Future<bool> _needUpdate(String serverVersion) async {

    String currentVersion = await _getCurrentVersion();
    printLongLogMessage("start to check if we will need to update");
    printLongLogMessage("current version: ${currentVersion} vs server version: ${serverVersion}");

    List<int> currentVersions = currentVersion.split(".").map((e) => int.parse(e));
    List<int> serverVersions = serverVersion.split(".").map((e) => int.parse(e));
    if (currentVersions.length != serverVersions.length) {
      printLongLogMessage("ERROR! current version's length doesn't match with server's version");
      return false;
    }
    for (int i = 0; i < currentVersions.length; i++) {
      if (serverVersions[i] > currentVersions[i]) {
        printLongLogMessage("we will need to upgrade current app");
        return true;
      }
    }
    printLongLogMessage("we don't need to upgrade current app");
    return false;
  }

  _updateApp(BuildContext context, String serverUrl,
      String serverVersion, String fileName){
    _appName = fileName;
    _downloadLatestApp(context, serverUrl, serverVersion, fileName);

  }
  _downloadLatestApp(BuildContext context, String serverUrl,
      String serverVersion, String fileName) async {

    // show progress dialog
    pr = new ProgressDialog(
      context,
      type: ProgressDialogType.Download,
      isDismissible: true,
      showLogs: true,
    );

    pr.style(message: '准备下载...');
    if (!pr.isShowing()) {
      pr.show();
    }

    final path = await _getAppDownloadLocalPath();
    await FlutterDownloader.enqueue(
        url: serverUrl + "/resource/mobile/app/download?version=" + serverVersion,
        savedDir: path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true
    );
  }
  /// 下载进度回调函数
  static void _downLoadCallback(String id, DownloadTaskStatus status, int progress) {
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  /// 更新下载进度框
  _updateDownLoadInfo(dynamic data) {
    DownloadTaskStatus status = data[1];
    int progress = data[2];
    printLongLogMessage("DownloadTaskStatus: ${status.value}");
    printLongLogMessage("progress: ${progress}");

    if (status == DownloadTaskStatus.running) {
      pr.update(progress: double.parse(progress.toString()), message: "下载中，请稍后…");
    }
    if (status == DownloadTaskStatus.failed) {
      if (pr.isShowing()) {
        pr.hide();
      }
    }

    if (status == DownloadTaskStatus.complete) {
      if (pr.isShowing()) {
        pr.hide();
      }
      _installApk();
    }
  }
  /// 安装apk
  Future<Null> _installApk() async {
    printLongLogMessage("start to install apk from " + _appPath + '/' + _appName);
    // await OpenFile.open(_appPath + '/' + _appName);
  }

  Future<String> _getAppDownloadLocalPath()  async {
    final directory = await getExternalStorageDirectory();
    String path = directory.path  + Platform.pathSeparator + 'Download';
    final savedDir = Directory(path);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      await savedDir.create();
    }
    this.setState((){
      _appPath = path;
    });
    return path;
  }


}
