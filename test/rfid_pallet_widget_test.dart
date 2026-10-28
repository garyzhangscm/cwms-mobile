import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cwms_mobile/workorder/models/rfid_pallet.dart';
import 'package:cwms_mobile/workorder/routes/rfid_pallet_scan.dart';
import 'rfid_pallet_test.dart' show tag;

void main() {
  const channel = MethodChannel('cwms_mobile/rfid');
  const codec = StandardMethodCodec();
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> event(int session, List<String> epcs) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
            channel.name,
            codec.encodeMethodCall(
                MethodCall('palletTags', {'session': session, 'epcs': epcs})),
            (_) {});
  }

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  testWidgets(
      'No catalog download on entry; UPCs are batched and repeated tags do not query again',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var session = 0;
    final calls = <Set<String>>[];
    final scan = Completer<Map<String, dynamic>>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'scanPallet') {
        session = (call.arguments as Map)['session'] as int;
        return scan.future;
      }
      return null;
    });
    await tester.pumpWidget(MaterialApp(
        home: RfidPalletScanPage(
            scopeKey: () => 'test',
            loadBatch: (codes) async {
              calls.add(codes);
              return RfidCatalog([]);
            })));
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    await tester.ensureVisible(find.text('Start scan'));
    await tester.tap(find.text('Start scan'));
    await tester.pump();
    await event(session, [tag(1), tag(2), tag(3, item: 222)]);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(calls.length, 1);
    expect(calls.single.length, 2);
    await event(session, [tag(1), tag(4)]);
    await tester.pump(const Duration(milliseconds: 400));
    expect(calls.length, 1);
    debugDefaultTargetPlatformOverride = null;
    scan.complete({'epcs': [], 'reason': 'stopped'});
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('Stop/continue deduplicates, reset rejects old callbacks',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var session = 0;
    Object? activation;
    Completer<Map<String, dynamic>>? pending;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'activate') activation = call.arguments;
      if (call.method == 'scanPallet') {
        session = (call.arguments as Map)['session'] as int;
        pending = Completer();
        return pending!.future;
      }
      if (call.method == 'stopPallet')
        pending?.complete({
          'epcs': [tag(1)],
          'reason': 'stopped'
        });
      return null;
    });
    await tester.pumpWidget(MaterialApp(
        home: RfidPalletScanPage(
            scopeKey: () => 'scope',
            loadCatalog: () async => RfidCatalog([]))));
    await tester.pumpAndSettle();
    expect(activation, {'palletMode': true});
    expect(find.text('Whole pallet mode · Checking reader power…'),
        findsOneWidget);
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
            channel.name,
            codec
                .encodeMethodCall(const MethodCall('readerPower', {'dbm': 20})),
            (_) {});
    await tester.pump();
    expect(find.text('Whole pallet mode · 20 dBm'), findsOneWidget);
    await tester.ensureVisible(find.text('Start scan'));
    await tester.tap(find.text('Start scan'));
    await tester.pump();
    final old = session;
    await event(session, [tag(1), tag(1), tag(2)]);
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.text('Stop scan'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.text('Continue scan'));
    await tester.pump();
    await event(session, [tag(1), tag(3)]);
    await tester.pump();
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.text('Stop scan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New pallet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    await event(old, [tag(4)]);
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;
  });
  testWidgets('Small Spanish screen remains usable when catalog fails',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        locale: const Locale('es'),
        supportedLocales: const [Locale('en'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: RfidPalletScanPage(
            scopeKey: () => 'scope',
            loadCatalog: () async => throw StateError('offline'))));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar escaneo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets(
      'Power choice is verified, disabled during scan and confirms clearing counts',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    var powerCalls = 0;
    var session = 0;
    Completer<Map<String, dynamic>>? pending;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'setPalletPower') {
        powerCalls++;
        final dbm = (call.arguments as Map)['dbm'];
        if (dbm == 25) throw PlatformException(code: 'POWER_FAILED');
        return dbm;
      }
      if (call.method == 'scanPallet') {
        session = (call.arguments as Map)['session'];
        pending = Completer();
        return pending!.future;
      }
      if (call.method == 'stopPallet')
        pending!.complete({
          'epcs': [tag(1)],
          'reason': 'stopped'
        });
      return null;
    });
    await tester.pumpWidget(MaterialApp(
        home: RfidPalletScanPage(
            scopeKey: () => 'scope',
            loadCatalog: () async => RfidCatalog([]))));
    await tester.pumpAndSettle();
    DropdownButtonFormField<int> selector() =>
        tester.widget(find.byType(DropdownButtonFormField<int>));
    selector().onChanged!(10);
    await tester.pumpAndSettle();
    expect(find.text('Whole pallet mode · 10 dBm'), findsOneWidget);
    await tester.ensureVisible(find.text('Start scan'));
    await tester.tap(find.text('Start scan'));
    await tester.pump();
    expect(selector().onChanged, isNull);
    await event(session, [tag(1)]);
    await tester.pump();
    await tester.tap(find.text('Stop scan'));
    await tester.pumpAndSettle();
    selector().onChanged!(15);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(powerCalls, 1);
    expect(find.text('1'), findsOneWidget);
    selector().onChanged!(15);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(powerCalls, 2);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Whole pallet mode · 15 dBm'), findsOneWidget);
    selector().onChanged!(25);
    await tester.pumpAndSettle();
    expect(find.text('Power change failed. Try again before scanning.'),
        findsOneWidget);
    expect(find.text('Whole pallet mode · 25 dBm'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    debugDefaultTargetPlatformOverride = null;
  });
}
