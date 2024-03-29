import 'dart:io';

import 'package:cwms_mobile/inbound/routes/barcode_receiving.dart';
import 'package:cwms_mobile/inbound/routes/reverse_receiving.dart';
import 'package:cwms_mobile/inventory/routes/audit_count_batch.dart';
import 'package:cwms_mobile/inventory/routes/audit_count_request.dart';
import 'package:cwms_mobile/inventory/routes/inventory_lost_and_found.dart';
import 'package:cwms_mobile/inventory/routes/inventory_detail.dart';
import 'package:cwms_mobile/inventory/routes/item_sampling.dart';
import 'package:cwms_mobile/inventory/routes/lpn_capture.dart';
import 'package:cwms_mobile/outbound/routes/bulk_pick.dart';
import 'package:cwms_mobile/outbound/routes/list_pick.dart';
import 'package:cwms_mobile/outbound/routes/pick_by_batch.dart';
import 'package:cwms_mobile/outbound/routes/pick_by_bulk.dart';
import 'package:cwms_mobile/outbound/routes/pick_by_order.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/language.dart';
import 'package:cwms_mobile/shared/routes/app_upgrade.dart';
import 'package:cwms_mobile/shared/routes/qr_code_view.dart';
import 'package:cwms_mobile/shared/work_profile_information.dart';
import 'package:cwms_mobile/states/profile_change_notifier.dart';
import 'package:cwms_mobile/work/routes/system_driven_work.dart';
import 'package:cwms_mobile/workorder/routes/pick_by_work_order.dart';
import 'package:cwms_mobile/workorder/routes/production_line_check_in.dart';
import 'package:cwms_mobile/workorder/routes/production_line_check_out.dart';
import 'package:cwms_mobile/workorder/routes/reverse_production.dart';
import 'package:cwms_mobile/workorder/routes/work_order_manual_pick.dart';
import 'package:cwms_mobile/workorder/routes/work_order_produce.dart';
import 'package:cwms_mobile/workorder/routes/work_order_produce_inventory.dart';
import 'package:cwms_mobile/workorder/routes/work_order_produce_kpi.dart';
import 'package:cwms_mobile/workorder/routes/work_order_qc.dart';
import 'package:cwms_mobile/workorder/routes/work_order_qc_sampling.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:cwms_mobile/sub_menus.dart';
import 'package:flutter/material.dart';

import 'auth/routes/login.dart';

import 'i18n/localization_intl.dart';
import 'inbound/routes/receiving.dart';
import 'inventory/routes/cycle_count_batch.dart';
import 'inventory/routes/cycle_count_request.dart';
import 'inventory/routes/inventory_deposit.dart';
import 'inventory/routes/inventory_putaway.dart';
import 'inventory/routes/inventory_qc.dart';
import 'inventory/routes/inventory_query.dart';
import 'inventory/routes/partial_inventory_move.dart';
import 'inventory/routes/qc_inspection.dart';
import 'launch_page.dart';
import 'menus.dart';
import 'outbound/routes/pick.dart';

import 'package:flutter/rendering.dart';

import 'outbound/routes/pick_by_list.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  // debugPaintSizeEnabled = true;
  Global.init().then((e) => runApp(MyApp()));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider.value(value: ThemeModel()),
        ChangeNotifierProvider.value(value: UserModel()),
        ChangeNotifierProvider.value(value: LocaleModel()),
      ],
      child: Consumer2<ThemeModel, LocaleModel>(
        builder: (BuildContext context, themeModel, localeModel, Widget child) {
          return MaterialApp(
            theme: ThemeData(
              primarySwatch: themeModel.theme,
            ),
            navigatorKey: navigatorKey,
            onGenerateTitle: (context) {
              return CWMSLocalizations
                  .of(context)
                  .title;
            },
            home: LaunchPage(),
            locale: localeModel.getLocale(),
            //我们只支持美国英语和中文简体
            supportedLocales: [
              const Locale('en', 'US'), // 美国英语
              const Locale('zh', 'CN'), // 中文简体
              //其它Locales
            ],
            localizationsDelegates: [
              // 本地化的代理类
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              CWMSLocalizationsDelegate()
            ],
            localeResolutionCallback:
                (Locale _locale, Iterable<Locale> supportedLocales) {
              if (localeModel.getLocale() != null) {
                //如果已经选定语言，则不跟随系统
                return localeModel.getLocale();
              }
              else {
                //跟随系统
                Locale locale;
                if (supportedLocales.contains(_locale)) {
                  locale = _locale;
                }
                else {
                  //如果系统语言不是中文简体或美国英语，则默认使用美国英语
                  locale = Locale('en', 'US');
                }
                return locale;
              }
            },
            routes: {
              "login_page": (context) => LoginPage(),
              "language": (context) => LanguageRoute(),
              "work_profile": (context) => WorkProfileInfoPage(),
              "menus_page": (context) => Menus(),
              "sub_menus_page": (context) => SubMenus(),
              "cycle_count_batch": (context) => CycleCountBatchPage(),
              "cycle_count_request": (context) => CycleCountRequestPage(),
              "audit_count_batch": (context) => AuditCountBatchPage(),
              "audit_count_request": (context) => AuditCountRequestPage(),
              "pick_by_order": (context) => PickByOrderPage(),
              "pick": (context) => PickPage(),
              "inventory_deposit": (context) => InventoryDepositPage(),
              // "inventory_adjust": (context) => InventoryAdjustmentPage(),
              "inventory_lost_and_found": (context) => InventoryLostFoundPage(),
              "receive": (context) => ReceivingPage(),
              "inventory": (context) => InventoryQueryPage(),
              "inventory_display": (context) => InventoryDetailPage(),
              "inventory_putaway": (context) => InventoryPutawayPage(),
              "pick_by_work_order": (context) => PickByWorkOrderPage(),
              "work_order_produce": (context) => WorkOrderProducePage(),
              "work_order_qc": (context) => WorkOrderQCPage(),
              "work_order_produce_inventory": (context) => WorkOrderProduceInventoryPage(),
              "work_order_produce_kpi":(context) => WorkOrderKPIPage(),
              "production_line_check_in":(context) => ProductionLineCheckInPage(),
              "production_line_check_out":(context) => ProductionLineCheckOutPage(),
              "qc_inspection":(context) => QCInspectionPage(),
              "inventory_qc":(context) => InventoryQCPage(),
              "app_upgrade":(context) => AppUpgradePage(),
              "lpn_capture":(context) => LpnCapturePage(),
              "work_order_qc_sampling":(context) => WorkOrderQCSamplingPage(),
              "item_sampling":(context) => ItemSamplingPage(),
              "work_order_manual_pick":(context) => WorkOrderManualPickPage(),
              "qr_code_view":(context) => QRCodeView(),
              "barcode_receiving":(context) => BarcodeReceivingPage(),
              "system_driven_work":(context) => SystemDrivenWork(),
              "bulk_pick":(context) => BulkPickPage(),
              "pick_by_bulk":(context) => PickByBulkPage(),
              "partial_inventory_move":(context) => PartialInventoryMovePage(),
              "work_order_reverse_production":(context) => ReverseProductionPage(),
              "reverse_receiving":(context) => ReverseReceivingPage(),
              "pick_by_list":(context) => PickByListPage(),
              "pick_by_number":(context) => PickByBatchPage(),
              // "/": (context) => LaunchPage(), //注册首页路由
              // "/":(context) => WebViewExample(), //注册首页路由
            },
          );
        },
      ),
    );
  }
}
/***
  return MaterialApp(
      title: 'CWMS',
      initialRoute:"/",
      locale: localeModel.getLocale(),
      //我们只支持美国英语和中文简体
      supportedLocales: [
        const Locale('en', 'US'), // 美国英语
        const Locale('zh', 'CN'), // 中文简体
        //其它Locales
      ],
      localizationsDelegates: [
        // 本地化的代理类
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        DecLocalizationsDelegate()
      ],
      localeResolutionCallback:
          (Locale _locale, Iterable<Locale> supportedLocales) {
        if (localeModel.getLocale() != null) {
          //如果已经选定语言，则不跟随系统
          return localeModel.getLocale();
        } else {
          //跟随系统
          Locale locale;
          if (supportedLocales.contains(_locale)) {
            locale= _locale;
          } else {
            //如果系统语言不是中文简体或美国英语，则默认使用美国英语
            locale= Locale('en', 'US');
          }
          return locale;
        }
      },
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
        "pick_by_order":(context) => PickByOrderPage(),
        "pick":(context) => PickPage(),
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
    **/