import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/shared/updates/ota_update_controller.dart';
import 'package:cwms_mobile/shared/updates/ota_update_gate.dart';
import 'package:cwms_mobile/shared/updates/update_activity.dart';
import 'package:cwms_mobile/shared/updates/update_route_observer.dart';

class FakeGateway implements OtaGateway {
  bool available = true;
  int current = 7;
  int next = 7;
  int downloads = 0;
  Completer<void>? pending;
  bool fail = false;
  Future<int> currentPatch() async => current;
  Future<int> nextPatch() async => next;
  Future<void> download() async {
    downloads++;
    if (pending != null) await pending!.future;
    if (fail) throw Exception('offline');
    next = 8;
  }
}

void main() {
  test('normal update can be deferred; downloaded minimum overrides deferral',
      () async {
    final gateway = FakeGateway();
    var minimum = 0;
    final controller = OtaUpdateController(
        gateway: gateway,
        loadPolicy: () async => OtaPolicy(minimumPatch: minimum));
    await controller.check();
    expect(controller.ready, true);
    expect(controller.mandatory, false);
    controller.defer();
    expect(controller.visible, false);
    minimum = 8;
    await controller.check();
    expect(controller.mandatory, true);
    expect(controller.visible, true);
    controller.defer();
    expect(controller.visible, true);
  });
  test('offline download never locks users out', () async {
    final gateway = FakeGateway()..fail = true;
    final controller = OtaUpdateController(
        gateway: gateway,
        loadPolicy: () async => const OtaPolicy(minimumPatch: 8));
    await controller.check();
    expect(controller.ready, false);
    expect(controller.mandatory, false);
    expect(controller.checking, false);
    expect(controller.error, isNotNull);
    gateway.fail = false;
    await controller.check();
    expect(controller.mandatory, true);
  });
  test('MES policy outage does not stop patch downloads', () async {
    final gateway = FakeGateway();
    final controller = OtaUpdateController(
        gateway: gateway,
        loadPolicy: () async => throw Exception('MES unavailable'));
    await controller.check();
    expect(controller.ready, true);
    expect(controller.mandatory, false);
  });
  test('required patch not yet available cannot lock a device', () async {
    final controller = OtaUpdateController(
        gateway: FakeGateway(),
        loadPolicy: () async => const OtaPolicy(minimumPatch: 9));
    await controller.check();
    expect(controller.ready, true);
    expect(controller.mandatory, false);
  });
  test('simultaneous checks download once', () async {
    final gateway = FakeGateway()..pending = Completer<void>();
    final controller = OtaUpdateController(
        gateway: gateway, loadPolicy: () async => const OtaPolicy());
    final first = controller.check();
    await Future<void>.delayed(Duration.zero);
    await controller.check();
    expect(gateway.downloads, 1);
    gateway.pending!.complete();
    await first;
    expect(controller.checking, false);
  });
  test('unsupported runtime does not check or lock', () async {
    final gateway = FakeGateway()..available = false;
    final controller = OtaUpdateController(
        gateway: gateway,
        loadPolicy: () async => const OtaPolicy(minimumPatch: 8));
    await controller.check();
    expect(gateway.downloads, 0);
    expect(controller.visible, false);
  });
  test('current patch meeting minimum and rollback both remain usable', () {
    final controller = OtaUpdateController(
        gateway: FakeGateway(), loadPolicy: () async => const OtaPolicy());
    controller.current = 8;
    controller.next = 9;
    controller.policy = const OtaPolicy(minimumPatch: 8);
    expect(controller.mandatory, false);
    controller.next = 7;
    expect(controller.visible, false);
  });
  test('policy is isolated by exact release and validates minimum', () {
    expect(
        OtaPolicy.fromJson(
                {'releaseVersion': '1.62.5+6', 'minimumPatch': 8}, '1.62.4+5')
            .minimumPatch,
        0);
    expect(
        () => OtaPolicy.fromJson(
            {'releaseVersion': '1.62.4+5', 'minimumPatch': -1}, '1.62.4+5'),
        throwsFormatException);
  });
  test('nested business operations release protection even on failure',
      () async {
    final activity = UpdateActivity();
    activity.begin();
    await expectLater(
        activity.run(() async => throw Exception('failed')), throwsException);
    expect(activity.busy, true);
    activity.end();
    expect(activity.busy, false);
  });

  Future<void> mount(WidgetTester tester, OtaUpdateController controller,
      {VoidCallback? close,
      VoidCallback? action,
      OtaHostPlatform platform = OtaHostPlatform.android}) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      navigatorObservers: [UpdateRouteObserver()],
      builder: (context, child) => OtaUpdateGate(
          navigatorKey: key,
          child: child!,
          updateController: controller,
          hostPlatform: platform,
          releaseVersion: '1.62.4+5',
          closeApp: close),
      home: Scaffold(
          body: Align(
              alignment: Alignment.topCenter,
              child: TextButton(
                  onPressed: action ?? () {},
                  child: const Text('Business operation')))),
    ));
  }

  testWidgets('iOS offers manual restart instructions and never exits the app',
      (tester) async {
    final controller = OtaUpdateController(
        gateway: FakeGateway(), loadPolicy: () async => const OtaPolicy());
    var closed = false;
    await mount(tester, controller,
        platform: OtaHostPlatform.ios, close: () => closed = true);
    await controller.check();
    await tester.pumpAndSettle();
    expect(find.text('App update ready'), findsOneWidget);
    await tester.tap(find.text('How to apply update'));
    await tester.pumpAndSettle();
    expect(find.text('Apply downloaded update'), findsOneWidget);
    expect(find.textContaining('app switcher'), findsOneWidget);
    expect(find.text('Close app'), findsNothing);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(closed, isFalse);
    expect(find.text('Business operation'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.text('App update ready'), findsNothing);
  });

  testWidgets('non-mobile runtime does not show a mobile update prompt',
      (tester) async {
    final controller = OtaUpdateController(
        gateway: FakeGateway(), loadPolicy: () async => const OtaPolicy());
    await mount(tester, controller, platform: OtaHostPlatform.unsupported);
    await controller.check();
    await tester.pumpAndSettle();
    expect(find.text('App update ready'), findsNothing);
  });

  testWidgets('normal prompt leaves the page usable and Later hides it',
      (tester) async {
    final controller = OtaUpdateController(
        gateway: FakeGateway(), loadPolicy: () async => const OtaPolicy());
    var actions = 0;
    await mount(tester, controller, action: () => actions++);
    await controller.check();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Business operation'));
    expect(actions, 1);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.text('App update ready'), findsNothing);
  });
  testWidgets('mandatory waits for whole operation, then blocks new work',
      (tester) async {
    final controller = OtaUpdateController(
        gateway: FakeGateway(),
        loadPolicy: () async => const OtaPolicy(minimumPatch: 8));
    var actions = 0;
    await mount(tester, controller, action: () => actions++);
    UpdateActivity.instance.begin();
    await controller.check();
    await tester.pumpAndSettle();
    expect(find.text('Required update ready'), findsNothing);
    UpdateActivity.instance.end();
    await tester.pumpAndSettle();
    expect(find.text('Required update ready'), findsOneWidget);
    expect(find.text('Later'), findsNothing);
    await tester.tap(find.text('Business operation'), warnIfMissed: false);
    expect(actions, 0);
    // Background polling cannot remove an already enforced update barrier.
    UpdateActivity.instance.begin();
    await tester.pumpAndSettle();
    expect(find.text('Required update ready'), findsOneWidget);
    UpdateActivity.instance.end();
    await tester.pumpAndSettle();
  });
  testWidgets(
      'close requires explicit confirmation and dialog remains clickable',
      (tester) async {
    final controller = OtaUpdateController(
        gateway: FakeGateway(),
        loadPolicy: () async => const OtaPolicy(minimumPatch: 8));
    var closed = false;
    await mount(tester, controller, close: () => closed = true);
    await controller.check();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close and reopen'));
    await tester.pumpAndSettle();
    expect(closed, false);
    expect(find.text('Close app to apply update?'), findsOneWidget);
    await tester.tap(find.text('Close app'));
    await tester.pumpAndSettle();
    expect(closed, true);
  });
}
