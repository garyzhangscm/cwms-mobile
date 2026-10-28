import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/shared/scanning/server_connection.dart';
import 'package:cwms_mobile/shared/scanning/scan_app_bar.dart';

void main() {
  const a = ConnectionProfile(
      'https://example.test/api/', 1, 1, 'TEST-RF', 'token-a');
  const b =
      ConnectionProfile('https://other.test/api/', 2, 1, 'TEST-RF', 'token-b');
  testWidgets(
      'checks actual server, handles disconnect and restore; keeps menu',
      (tester) async {
    var status = 200;
    final monitor =
        ServerConnectionMonitor(profile: () => a, probe: (_) async => status);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            appBar: AppBar(
                actions: [ServerConnectionIndicator(monitor: monitor)]))));
    await tester.pump();
    expect(monitor.state, ServerConnectionState.connected);
    expect(find.text('Connected'), findsOneWidget);
    status = 503;
    await monitor.check();
    await tester.pump();
    expect(find.text('Offline'), findsOneWidget);
    status = 200;
    await monitor.check();
    await tester.pump();
    expect(find.text('Connected'), findsOneWidget);
    monitor.didChangeAppLifecycleState(AppLifecycleState.paused);
    status = 503;
    await monitor.check();
    expect(monitor.state, ServerConnectionState.connected);
    monitor.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(monitor.state, ServerConnectionState.disconnected);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'old factory result cannot mark the newly selected factory connected',
      (tester) async {
    var current = a;
    final first = Completer<int>();
    var calls = 0;
    final m = ServerConnectionMonitor(
        profile: () => current,
        probe: (_) async {
          calls++;
          return calls == 1 ? await first.future : 200;
        });
    await tester.pumpWidget(MaterialApp(
        home: Material(child: ServerConnectionIndicator(monitor: m))));
    await tester.pump();
    current = b;
    await m.check();
    expect(m.visibleState, ServerConnectionState.checking);
    first.complete(503);
    await tester.pump();
    await tester.pump();
    expect(m.state, ServerConnectionState.connected);
    expect(calls, 2);
    m.note(a.server, 503, scope: a.scope);
    expect(m.state, ServerConnectionState.connected);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('background probe cannot override a more recent request result',
      (tester) async {
    final gate = Completer<int>();
    final m =
        ServerConnectionMonitor(profile: () => a, probe: (_) => gate.future);
    await tester.pumpWidget(MaterialApp(
        home: Material(child: ServerConnectionIndicator(monitor: m))));
    await tester.pump();
    m.note(a.server, 200, scope: a.scope);
    gate.complete(503);
    await tester.pump();
    expect(m.state, ServerConnectionState.connected);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('401 asks for sign-in and does not pretend Wi-Fi is disconnected',
      (tester) async {
    final m =
        ServerConnectionMonitor(profile: () => a, probe: (_) async => 401);
    await tester.pumpWidget(MaterialApp(
        home: Material(child: ServerConnectionIndicator(monitor: m))));
    await tester.pump();
    expect(find.text('Sign in'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'automatic status checks reuse recent queue responses, manual check stays immediate',
      (tester) async {
    var now = DateTime(2026, 10, 26);
    var calls = 0;
    final m = ServerConnectionMonitor(
        profile: () => a,
        now: () => now,
        probe: (_) async {
          calls++;
          return 200;
        });
    await tester.pumpWidget(MaterialApp(
        home: Material(child: ServerConnectionIndicator(monitor: m))));
    await tester.pump();
    expect(calls, 1);
    for (var i = 0; i < 6; i++) {
      now = now.add(const Duration(seconds: 5));
      m.note(a.server, 200, scope: a.scope);
      await tester.pump(const Duration(seconds: 5));
    }
    expect(calls, 1);
    await m.check();
    expect(calls, 2);
    now = now.add(const Duration(seconds: 15));
    await tester.pump(const Duration(seconds: 15));
    expect(calls, 3);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('new factory ignores freshness of previous factory responses',
      (tester) async {
    var current = a;
    var calls = 0;
    final m = ServerConnectionMonitor(
        profile: () => current,
        probe: (_) async {
          calls++;
          return 200;
        });
    await tester.pumpWidget(MaterialApp(
        home: Material(child: ServerConnectionIndicator(monitor: m))));
    await tester.pump();
    m.note(a.server, 200, scope: a.scope);
    current = b;
    await m.check(force: false);
    expect(calls, 2);
    expect(m.visibleState, ServerConnectionState.connected);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('narrow scan app bar retains its drawer button', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            appBar: ScanAppBar(title: const Text('Manual Pick')),
            endDrawer: const Drawer(child: Text('Test menu')))));
    expect(find.byType(EndDrawerButton), findsOneWidget);
    await tester.tap(find.byType(EndDrawerButton));
    await tester.pumpAndSettle();
    expect(find.text('Test menu'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
