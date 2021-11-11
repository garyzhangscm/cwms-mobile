
import 'dart:collection';
import 'dart:core';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/models/rf_app_version.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:progress_dialog/progress_dialog.dart';

import '../global.dart';


class AppUpgradePage extends StatefulWidget{

  AppUpgradePage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _AppUpgradePageState();

}

class _AppUpgradePageState extends State<AppUpgradePage> {

  RFAppVersion _latestRFAppVersion;

  ProgressDialog pr;
  ReceivePort _port = ReceivePort();

  String _appLocalPath;


  @override
  void initState() {
    super.initState();

    // init tools for the upgrade current app
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen(_updateDownLoadInfo);
    FlutterDownloader.registerCallback(_downLoadCallback);

  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    _latestRFAppVersion  = ModalRoute.of(context).settings.arguments;
    // downloadingFileSize = _latestRFAppVersion.fileSize;

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).appUpgrade)),
      body:
          Column(
            children: [
              _buildReleaseNoteHeader(context),
              _buildReleaseNote(context),
              _buildButtons(context)
            ],
          ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildReleaseNoteHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 5, bottom: 5),
      child:
        Row(
            children: <Widget>[
              Padding(padding: EdgeInsets.only(left: 10),
                child: Text(CWMSLocalizations.of(context).newReleaseFound + ": ",
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.headline6),
              ),
              Text(_latestRFAppVersion.versionNumber,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.headline6),
            ]
        ),
    );
  }
  Widget _buildReleaseNote(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 5, bottom: 5),
      child:
        Row(
            children: <Widget>[
              Padding(padding: EdgeInsets.only(left: 10),
                child:
                  Text(_latestRFAppVersion.releaseNote,
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.bodyText1,

                      maxLines: 15
                  )
              ),
            ]
        ),
    );


  }

  Widget _buildButtons(BuildContext context) {

    return Column(
      children: [
        buildSingleButtonRow(context,
          ElevatedButton(
              onPressed: _onUpgrade,
              child: Text(CWMSLocalizations.of(context).appUpgrade)
          ),
        ),
      ],
    );
  }

  _onUpgrade() async {

    // first, request the write permission
    bool hasPermission =  await _retryRequestPermission();
    if (hasPermission) {
      printLongLogMessage("We got permission! Let's start update the APP");
      String apkUrl =
          Global.currentServer.url +
              "/resource/rf-apk-files?versionNumber=" + _latestRFAppVersion.versionNumber  +
              "&companyId=" + Global.lastLoginCompanyId.toString();
      printLongLogMessage("start to download from $apkUrl");

      _downloadLatestApp(context, apkUrl);
    }

  }

  _downloadLatestApp(BuildContext context, String serverUrl) async {

    // show progress dialog
    pr = new ProgressDialog(
      context,
      type: ProgressDialogType.Download,
      isDismissible: true,
      showLogs: true,
    );

    pr.style(message: CWMSLocalizations.of(context).startDownloadingAppNewVersion);
    if (!pr.isShowing()) {
      pr.show();
    }
    // remove the file with the same name from the downloading directory
    await _removeExistingDownloadedFile(_appLocalPath + "/" + _latestRFAppVersion.fileName);

    await FlutterDownloader.enqueue(
      url: serverUrl,
      // url: 'http://barbra-coco.dyndns.org/student/learning_android_studio.pdf',
      savedDir: _appLocalPath,
      fileName: _latestRFAppVersion.fileName,
      showNotification: true,
      openFileFromNotification: true,
      saveInPublicStorage: true,
    );
  }

  _removeExistingDownloadedFile(String fileAbsolutePath) async {
    File file = File(fileAbsolutePath);
    bool fileExists = await file.exists();
    if (fileExists) {
      await file.delete();
    }
  }
  /// 下载进度回调函数
  static void _downLoadCallback(String id, DownloadTaskStatus status, int progress) {
    printLongLogMessage("_downLoadCallback: id: ${id}, status: ${status.value}, progress: ${progress}");

    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send([id, status, progress]);
  }

  /// 更新下载进度框
  _updateDownLoadInfo(dynamic data) {
    DownloadTaskStatus status = data[1];
    int progress = data[2];

    if (status == DownloadTaskStatus.running) {

      // NOTE: Since our spring boot server use "Transfer-Encoding: chunked" to compress
      // the response, we won't have the Content-Length in the header, hance the progress
      // is actually the actual size being downloaded, not the percentage of the downloading
      // before I can figure out a better way to handle this, we will have the file size saved
      // in the rfAppVersion object so that we can calcuate the percentage of the files that is
      // already downloaded
      progress = progress * 100 ~/ _latestRFAppVersion.fileSize;
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
    printLongLogMessage("start to install apk from " + _appLocalPath + '/' + _latestRFAppVersion.fileName);
    await OpenFile.open(_appLocalPath + '/' + _latestRFAppVersion.fileName);
  }


  Future<bool> _retryRequestPermission() async {
    final hasGranted = await _checkPermission();
    printLongLogMessage("permissiong granted? ${hasGranted}");

    if (hasGranted) {
      printLongLogMessage("We have permissiong. let's create the local folder");
      await _prepareSaveDir();
    }

    return hasGranted;
  }

  Future<bool> _checkPermission() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt <= 28) {
      final status = await Permission.storage.status;

      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }


  Future<void> _prepareSaveDir() async {
    _appLocalPath = (await _findLocalPath());
    final savedDir = Directory(_appLocalPath);
    printLongLogMessage("we will save to local folder: ${_appLocalPath}");
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      printLongLogMessage("> THe folder is not exists, let's create it");
      savedDir.create();
    }
  }

  Future<String> _findLocalPath() async {
    var externalStorageDirPath;
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      externalStorageDirPath = directory.path;
    } else if (Platform.isIOS) {
      externalStorageDirPath =
          (await getApplicationDocumentsDirectory()).absolute.path;
    }
    return externalStorageDirPath;
  }

}