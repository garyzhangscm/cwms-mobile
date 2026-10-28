import 'dart:async';
import 'dart:convert';
import 'package:cwms_mobile/workorder/services/rfid_label_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/workorder/routes/rfid_check.dart';
import 'package:cwms_mobile/workorder/models/rfid_check.dart';

void main() {
  const channel = MethodChannel('cwms_mobile/rfid');
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
  testWidgets('Photo requires confirmation; RFID trigger cannot run during review', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var scans = 0;
    const tag = '301800078900030000000001';
    final code = sgtin96ToGtin(tag);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'scan') { scans++; return [tag]; }
      return null;
    });
    final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==');
    await tester.pumpWidget(MaterialApp(home: RfidCheckPage(captureLabel: () async => LabelPhoto(png, [code]))));
    await tester.tap(find.text('Take Photo'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm printed UPC'), findsOneWidget);
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(channel.name,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('trigger')), (_) {});
    await tester.pump();
    expect(scans, 0);
    await tester.tap(find.text('Use this UPC'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, code);
    await tester.ensureVisible(find.text('Read RFID'));
    await tester.tap(find.text('Read RFID')); await tester.pumpAndSettle();
    expect(scans, 1);
    expect(find.text('PASS'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); await tester.pump();
    debugDefaultTargetPlatformOverride = null;
  });
  testWidgets('Invalid UPC cannot start hardware, valid reads show PASS; editing clears it', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var scans = 0;
    const tag = '301800078900030000000001';
    final gtin = sgtin96ToGtin(tag);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'scan') { scans++; return [tag]; }
      return null;
    });
    await tester.pumpWidget(const MaterialApp(home: RfidCheckPage()));
    await tester.tap(find.text('Read RFID')); await tester.pumpAndSettle();
    expect(scans, 0);
    await tester.enterText(find.byType(TextField), gtin);
    await tester.tap(find.text('Read RFID')); await tester.pumpAndSettle();
    expect(find.text('PASS'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '036000291452'); await tester.pump();
    expect(find.text('PASS'), findsNothing);
    await tester.pumpWidget(const SizedBox()); await tester.pump();
    debugDefaultTargetPlatformOverride = null;
  });
  testWidgets('Background cancellation rejects late PASS and allows retry', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final pending = Completer<List<String>>();
    const tag = '301800078900030000000001';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'scan') return pending.future;
      return null;
    });
    await tester.pumpWidget(const MaterialApp(home: RfidCheckPage()));
    await tester.enterText(find.byType(TextField), sgtin96ToGtin(tag));
    await tester.tap(find.text('Read RFID')); await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive); await tester.pump();
    pending.complete([tag]); await tester.pumpAndSettle();
    expect(find.text('PASS'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox()); await tester.pump();
    debugDefaultTargetPlatformOverride = null;
  });
}
