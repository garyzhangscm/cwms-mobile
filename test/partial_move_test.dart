import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cwms_mobile/inventory/routes/partial_inventory_move.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoveAdapter implements HttpClientAdapter {
 final calls=<RequestOptions>[];
 bool moved=false, missing=false, duplicate=false, failLookup=false, failRefresh=false, timeoutMove=false;
 Completer<void>? gate;
 Map<String,dynamic> row(String lpn,int qty) => {'id':7,'lpn':lpn,'quantity':qty,'warehouseId':1,'item':{'id':2,'name':'ITEM-A','description':'Material A','defaultItemPackageType':{'id':1,'itemUnitOfMeasures':[{'id':1,'quantity':10,'unitOfMeasure':{'id':1,'name':'CASE'}}]}},'inventoryStatus':{'id':1,'name':'Available'},'location':{'id':4,'name':'RF-TEST'}};
 @override Future<ResponseBody> fetch(RequestOptions o,Stream<Uint8List>? b,Future<void>? c) async {
 calls.add(o);dynamic data=[];int result=0;
 if(o.path.endsWith('/inventory/move')) {
  if(gate!=null) await gate!.future;
  if(timeoutMove) throw DioException(requestOptions:o,type:DioExceptionType.receiveTimeout);
  moved=true;data=[row('NEW-LPN',20)];
 } else if(o.path.endsWith('/layout/locations')) {data=[{'id':4,'name':'RF-TEST','warehouseId':1}];}
 else if(o.path.endsWith('/inventories')) {
  final lpn=o.queryParameters['lpn'];
  if(lpn=='SOURCE') {data=missing?[]:[row('SOURCE',100)];if(failLookup)result=1;}
  else if(lpn=='NEW-LPN') {data=duplicate?[row('NEW-LPN',10)]:[];}
  else {data=moved?[row('NEW-LPN',20)]:[];if(moved&&failRefresh)result=1;}
 }
 return ResponseBody.fromString(jsonEncode({'result':result,'message':result==0?'':'Lookup failed','data':data}),200,headers:{Headers.contentTypeHeader:['application/json']});
 }
 @override void close({bool force=false}){}
}
void main(){
 late MoveAdapter a;
 setUp((){
 SharedPreferences.setMockInitialValues({});Global.currentFactory=null;
 Global.currentServer=CWMSSiteInformation()..url='https://example.test/api/';
 Global.currentWarehouse=Warehouse()..id=1;Global.lastLoginRFCode='RF-TEST';
 CWMSHttpClient.resetDio();a=MoveAdapter();CWMSHttpClient.getDio().httpClientAdapter=a;
 TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('PonnamKarthik/fluttertoast'),(_)async=>true);
 });
 Future<void> open(WidgetTester t)async{
 t.view.physicalSize=const Size(1100,1500);t.view.devicePixelRatio=1;addTearDown(t.view.reset);
 await t.pumpWidget(MaterialApp(locale:const Locale('en'),localizationsDelegates:const [GlobalMaterialLocalizations.delegate,GlobalCupertinoLocalizations.delegate,GlobalWidgetsLocalizations.delegate,CWMSLocalizationsDelegate()],home:PartialInventoryMovePage(),onGenerateRoute:(s)=>MaterialPageRoute(settings:s,builder:(_)=>Scaffold(body:Text('Deposit '+(s.arguments as List<Inventory>).first.lpn!)))));await t.pumpAndSettle();
 }
 Future<void> scan(WidgetTester t)async{await t.enterText(find.byKey(const ValueKey('partial-source-lpn')),'SOURCE');await t.testTextInput.receiveAction(TextInputAction.done);await t.pumpAndSettle();}
 Future<void> prepare(WidgetTester t)async{await scan(t);await t.enterText(find.byKey(const ValueKey('partial-quantity')),'2');await t.enterText(find.byKey(const ValueKey('partial-new-lpn')),'NEW-LPN');await t.pumpAndSettle();}
 testWidgets('quantity updates Add and split request carries base quantity and new LPN without whole-row ID',(t)async{
 await open(t);await prepare(t);
 expect(t.widget<ElevatedButton>(find.byKey(const ValueKey('partial-add'))).onPressed,isNotNull);
 await t.tap(find.byKey(const ValueKey('partial-add')));await t.pumpAndSettle();
 final move=a.calls.singleWhere((o)=>o.path.endsWith('/inventory/move'));
 expect(move.queryParameters['quantity'],20);expect(move.queryParameters['destinationLpn'],'NEW-LPN');expect(move.queryParameters.containsKey('inventoryId'),false);expect(move.queryParameters.containsKey('unitOfMeasure'),false);
 expect(find.textContaining('NEW-LPN'),findsWidgets);expect(t.takeException(),isNull);
 final deposit=find.widgetWithText(ElevatedButton,CWMSLocalizations.of(t.element(find.byType(PartialInventoryMovePage))).depositInventory);
 await t.tap(deposit);await t.pumpAndSettle();expect(find.text('Deposit NEW-LPN'),findsOneWidget);
 });
 testWidgets('missing LPN and lookup failures keep the page usable without a stuck modal',(t)async{
 a.missing=true;await open(t);await scan(t);expect(find.textContaining('was not found'),findsOneWidget);expect(find.byType(AlertDialog),findsNothing);
 a.missing=false;a.failLookup=true;await scan(t);expect(find.textContaining('Unable to load LPN'),findsOneWidget);expect(t.takeException(),isNull);
 });
 testWidgets('invalid quantity cannot submit; duplicate new label is blocked',(t)async{
 await open(t);await prepare(t);await t.enterText(find.byKey(const ValueKey('partial-quantity')),'11');await t.pump();expect(t.widget<ElevatedButton>(find.byKey(const ValueKey('partial-add'))).onPressed,isNull);
 await t.enterText(find.byKey(const ValueKey('partial-quantity')),'2');await t.pump();a.duplicate=true;await t.tap(find.byKey(const ValueKey('partial-add')));await t.pumpAndSettle();expect(find.textContaining('already in use'),findsOneWidget);expect(a.calls.where((o)=>o.path.endsWith('/inventory/move')),isEmpty);
 });
 testWidgets('RF refresh failure after successful move does not resubmit or allow stale Deposit',(t)async{
 await open(t);await prepare(t);a.failRefresh=true;await t.tap(find.byKey(const ValueKey('partial-add')));await t.pumpAndSettle();expect(a.calls.where((o)=>o.path.endsWith('/inventory/move')).length,1);expect(find.textContaining('Could not refresh inventory'),findsOneWidget);expect(t.takeException(),isNull);
 });
 testWidgets('phone wizard keeps each step separate with keyboard visible',(t) async {
 await open(t);
 t.view.physicalSize=const Size(430,932);
 await t.pumpAndSettle();
 expect(find.text('Scan the original pallet'),findsOneWidget);
 expect(find.byKey(const ValueKey('partial-new-lpn')),findsNothing);
 await scan(t);
 expect(find.text('Enter split details'),findsOneWidget);
 expect(find.byKey(const ValueKey('partial-source-lpn')),findsNothing);
 t.view.viewInsets=FakeViewPadding(bottom:300);
 await t.enterText(find.byKey(const ValueKey('partial-quantity')),'2');
 await t.ensureVisible(find.byKey(const ValueKey('partial-new-lpn')));
 await t.enterText(find.byKey(const ValueKey('partial-new-lpn')),'NEW-LPN');
 await t.pumpAndSettle();
 await t.ensureVisible(find.byKey(const ValueKey('partial-add')));
 await t.pumpAndSettle();
 await t.tap(find.byKey(const ValueKey('partial-add')));
 await t.pumpAndSettle();
 expect(find.text('Split completed'),findsOneWidget);
 expect(find.byKey(const ValueKey('partial-new-lpn')),findsNothing);
 expect(t.takeException(),isNull);
 });

}
