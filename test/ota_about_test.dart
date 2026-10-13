import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cwms_mobile/shared/routes/app_information.dart';
import 'package:cwms_mobile/shared/updates/ota_update_controller.dart';
import 'package:cwms_mobile/shared/updates/ota_update_scope.dart';

class AboutGateway implements OtaGateway {
  bool get available => true;
  int downloads = 0;
  bool fail = false;
  Future<int> currentPatch() async => 9;
  Future<int> nextPatch() async => 9;
  Future<void> download() async {
    downloads++;
    if (fail) throw Exception('offline');
  }
}

void main() {
  setUp(() => PackageInfo.setMockInitialValues(
      appName: 'Claytech One',
      packageName: 'test.app',
      version: '1.62.4',
      buildNumber: '5',
      buildSignature: 'test'));
  testWidgets('About shows actual active patch after explicit check',
      (tester) async {
    final gateway = AboutGateway();
    final controller = OtaUpdateController(
        gateway: gateway,
        loadPolicy: () async => const OtaPolicy(minimumPatch: 9));
    await tester.pumpWidget(OtaUpdateScope(
        controller: controller,
        child: const MaterialApp(home: AppInformationPage())));
    await tester.pumpAndSettle();
    expect(find.text('1.62.4 (5)'), findsOneWidget);
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(gateway.downloads, 1);
    expect(find.text('1.62.4 (5) · Patch 9'), findsOneWidget);
    expect(find.text('App is up to date'), findsOneWidget);
  });
  testWidgets('About permits retry after failed update check', (tester) async {
    final gateway = AboutGateway()..fail = true;
    final controller = OtaUpdateController(
        gateway: gateway, loadPolicy: () async => const OtaPolicy());
    await tester.pumpWidget(OtaUpdateScope(
        controller: controller,
        child: const MaterialApp(home: AppInformationPage())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(
        find.text('Unable to check for updates. We will retry when connected.'),
        findsOneWidget);
    gateway.fail = false;
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(gateway.downloads, 2);
    expect(find.text('App is up to date'), findsOneWidget);
  });
}
