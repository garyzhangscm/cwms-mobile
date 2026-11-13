import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/auth/models/menu.dart';
import 'package:cwms_mobile/auth/models/menu_sub_group.dart';
import 'package:cwms_mobile/shared/qc_menu.dart';
import 'package:cwms_mobile/qc_menu_page.dart';

import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/shared/models/factory_profile.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/workorder/routes/qc_production_page.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

Menu item(String route) => Menu()..name=route..text=route..link=route;
MenuSubGroup group(List<String> routes) => MenuSubGroup()..menus=routes.map(item).toList();
void main() {
 test('Copies authorized entries, inherits existing Produce access and keeps original groups', () {
   final inbound = group(['inbound_qc']);
   final work = group(['work_order_produce','work_order_qc','work_order_qc_sampling']);
   final result = qcMenuItems([inbound, work, group(['inbound_qc'])], (_) => true);
   expect(result.map((m)=>m.link), ['inbound_qc','work_order_qc','work_order_qc_sampling','work_order_rfid_check','work_order_rfid_pallet','work_order_defective']);
   expect(inbound.menus.length, 1);
   expect(work.menus.length, 3);
   expect(result.first, same(inbound.menus.first));
 });
 test('Does not grant Produce-derived access to inbound-only users; excludes unsupported routes', () {
   expect(qcMenuItems([group(['inbound_qc'])], (_) => true).map((m)=>m.link), ['inbound_qc']);
   expect(qcMenuItems([group(['work_order_produce'])], (r)=>r=='work_order_produce'), isEmpty);
   expect(qcMenuItems([group(['pick_by_work_order'])], (_) => true), isEmpty);
 });
 testWidgets('Quality checks and reporting are separated and reuse the registered route', (tester) async {
   TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('cwms_mobile/rfid'), (_) async => 'unsupported');
   await tester.pumpWidget(MaterialApp(
     routes: {'inbound_qc': (_) => const Scaffold(body: Text('Existing inbound page')),
       'work_order_defective': (_) => const SizedBox()},
     home: QcMenuPage(menus: [item('inbound_qc'), item('work_order_defective')])));
   await tester.pumpAndSettle();
   expect(find.text('Quality checks'), findsOneWidget);
   expect(find.text('Defective reporting'), findsOneWidget);
   expect(find.text('Records defective output and updates inventory and work order quantities.'), findsOneWidget);
   await tester.tap(find.text('Inbound QC'));
   await tester.pumpAndSettle();
   expect(find.text('Existing inbound page'), findsOneWidget);
 });

 testWidgets('Production confirmation sits above quality checks and opens both scan flows', (tester) async {
   if (FactoryProfile.qcPreviewUrl.isEmpty) return;
   SharedPreferences.setMockInitialValues({});
   Global.currentServer = CWMSSiteInformation()..url = FactoryProfile.qcPreviewUrl;
   Global.currentWarehouse = Warehouse()..id = 1;
   addTearDown(() {
     Global.currentServer = null;
     Global.currentWarehouse = null;
   });
   CWMSHttpClient.resetDio();
   CWMSHttpClient.getDio().interceptors.add(InterceptorsWrapper(
     onRequest: (request, handler) => handler.resolve(Response(
       requestOptions: request,
       statusCode: 200,
       data: {'result': 0, 'data': {'enabled': true, 'actor': 'qc-test'}},
     )),
   ));
   await tester.pumpWidget(MaterialApp(
     routes: {'inbound_qc': (_) => const SizedBox()},
     home: QcMenuPage(menus: [item('inbound_qc')]),
   ));
   await tester.pumpAndSettle();
   final heading = find.text('Production Confirmation');
   final checks = find.text('Quality checks');
   expect(tester.getTopLeft(heading).dy, lessThan(tester.getTopLeft(checks).dy));
   await tester.tap(find.text('Confirm'));
   await tester.pumpAndSettle();
   expect(tester.widget<QcProductionPage>(find.byType(QcProductionPage)).withdraw, isFalse);
   await tester.pageBack();
   await tester.pumpAndSettle();
   await tester.tap(find.text('Production Pallet Exception'));
   await tester.pumpAndSettle();
   expect(tester.widget<QcProductionPage>(find.byType(QcProductionPage)).withdraw, isTrue);
 }, variant: const TargetPlatformVariant({TargetPlatform.android, TargetPlatform.iOS}));
}
