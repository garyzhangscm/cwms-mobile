import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/auth/models/menu.dart';
import 'package:cwms_mobile/auth/models/menu_sub_group.dart';
import 'package:cwms_mobile/shared/qc_menu.dart';
import 'package:cwms_mobile/qc_menu_page.dart';

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
}
