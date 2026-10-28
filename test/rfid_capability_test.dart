import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/shared/rfid_capability.dart';
import 'package:cwms_mobile/shared/menu_navigation.dart';

void main() {
 const channel = MethodChannel('cwms_mobile/rfid');
 TestWidgetsFlutterBinding.ensureInitialized();
 tearDown(() {
   debugDefaultTargetPlatformOverride = null;
   RfidCapability.state.value = RfidHardware.checking;
   TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
 });
 test('Non-Android devices do not invoke reader SDK and hide RFID', () async {
   debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
   var calls = 0;
   TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async { calls++; return 'available'; });
   await RfidCapability.check(retry: true);
   expect(calls, 0);
   expect(RfidCapability.visible, false);
 });
 test('Verified reader stays visible on transient error; unknown/unsupported are hidden', () async {
   debugDefaultTargetPlatformOverride = TargetPlatform.android;
   var response = 'available';
   TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async {
     if (response == 'error') throw PlatformException(code: 'BUSY');
     return response;
   });
   await RfidCapability.check(retry:true);
   expect(RfidCapability.visible, true);
   response = 'error';
   await RfidCapability.check(retry:true);
   expect(RfidCapability.state.value, RfidHardware.unavailable);
   expect(RfidCapability.visible, true);
   response = 'unsupported';
   await RfidCapability.check(retry:true);
   expect(RfidCapability.visible, false);
   response = 'unknown';
   await RfidCapability.check(retry:true);
   expect(RfidCapability.visible, false);
   response = 'available';
   await RfidCapability.check(retry:true);
   expect(RfidCapability.visible, true);
 });
 testWidgets('Menu gates both RFID routes and preserves ordinary QC', (tester) async {
   debugDefaultTargetPlatformOverride = TargetPlatform.android;
   TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async => 'unsupported');
   RfidCapability.state.value = RfidHardware.unsupported;
   await tester.pumpWidget(MaterialApp(routes: {
     'work_order_rfid_check': (_) => const SizedBox(),
     'work_order_rfid_pallet': (_) => const SizedBox(),
     'inbound_qc': (_) => const SizedBox(),
   }, home: RfidMenuGate(builder: (context) => Column(children: [
     for (final route in ['work_order_rfid_check','work_order_rfid_pallet','inbound_qc'])
       if (hasRegisteredMenuRoute(context, route)) Text(route),
   ]))));
   await tester.pumpAndSettle();
   expect(find.text('inbound_qc'), findsOneWidget);
   expect(find.text('work_order_rfid_check'), findsNothing);
   expect(find.text('work_order_rfid_pallet'), findsNothing);
   RfidCapability.state.value = RfidHardware.available;
   await tester.pump();
   expect(find.text('work_order_rfid_check'), findsOneWidget);
   expect(find.text('work_order_rfid_pallet'), findsOneWidget);
   await tester.pumpWidget(const SizedBox()); await tester.pump();
   debugDefaultTargetPlatformOverride = null;
 });
}
