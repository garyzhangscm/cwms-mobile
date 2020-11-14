import 'dart:io';

import 'package:webview_flutter/webview_flutter.dart';

import 'package:cwms_mobile/sub_menus.dart';
import 'package:flutter/material.dart';

import 'auth/routes/login.dart';
import 'common/global.dart';
import 'inventory/routes/cycle_count_batch.dart';
import 'inventory/routes/cycle_count_request.dart';
import 'launch_page.dart';
import 'menus.dart';

void main() {
  Global.init().then((e) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CWMS',
      initialRoute:"/",
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.green,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      //注册路由表
      routes:{
        "login_page":(context) => LoginPage(),
        "menus_page":(context) => Menus(),
        "sub_menus_page":(context) => SubMenus(),
        "cycle_cycle_batch":(context) => CycleCountBatchPage(),
        "cycle_cycle_request":(context) => CycleCountRequestPage(),
        "/":(context) => LaunchPage(), //注册首页路由
        // "/":(context) => WebViewExample(), //注册首页路由
      },
    );
  }
}

class WebViewExample extends StatefulWidget {
  @override
  WebViewExampleState createState() => WebViewExampleState();
}

class WebViewExampleState extends State<WebViewExample> {
  @override
  void initState() {
    super.initState();
    // Enable hybrid composition.
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: 'https://www.youtube.com/',
    );
  }
}