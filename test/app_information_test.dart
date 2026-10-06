import 'package:cwms_mobile/shared/routes/app_information.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('about page shows installed build and opens bundled licenses', (tester) async {
    PackageInfo.setMockInitialValues(appName: 'Claytech One',
        packageName: 'com.olivetinternational.claytechone', version: '1.62.3',
        buildNumber: '4', buildSignature: '');
    await tester.pumpWidget(const MaterialApp(home: AppInformationPage()));
    await tester.pumpAndSettle();
    expect(find.text('1.62.3 (4)'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Technical Support'), findsOneWidget);
    await tester.tap(find.text('Open-source Licenses'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
