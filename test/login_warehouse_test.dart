import 'dart:async';
import 'package:cwms_mobile/auth/routes/login.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Warehouse warehouse(int id, String name) => Warehouse()
  ..id = id
  ..name = name;

Future<void> openLogin(WidgetTester tester,
    Future<List<Warehouse>> Function(String, String) loader) async {
  Global.currentServer = CWMSSiteInformation()
    ..url = 'https://example.com/api/';
  Global.lastLoginCompanyCode = null;
  Global.autoLoginUser = null;
  tester.view.physicalSize = const Size(1200, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en', 'US'),
    supportedLocales: const [Locale('en', 'US')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      CWMSLocalizationsDelegate(),
    ],
    home: LoginPage(warehouseLoader: loader),
  ));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), '20905');
  await tester.enterText(find.byType(TextFormField).at(1), 'review-user');
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('automatically selects first warehouse and selection uses ID',
      (tester) async {
    await openLogin(tester,
        (_, __) async => [warehouse(7, 'ECML'), warehouse(9, 'SECOND')]);
    expect(
        tester
            .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
            .value,
        '7');
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SECOND').last);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
            .value,
        '9');
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed load shows retry and successful retry selects warehouse',
      (tester) async {
    var fail = true;
    await openLogin(tester, (_, __) async {
      if (fail) throw Exception('network unavailable');
      return [warehouse(7, 'ECML')];
    });
    expect(
        find.text(
            'Could not load warehouses. Check your connection and retry.'),
        findsOneWidget);
    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
            .value,
        '7');
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('older account response cannot overwrite current warehouses',
      (tester) async {
    final pending = <Completer<List<Warehouse>>>[];
    await openLogin(tester, (_, __) {
      final request = Completer<List<Warehouse>>();
      pending.add(request);
      return request.future;
    });
    await tester.enterText(find.byType(TextFormField).at(1), 'different-user');
    await tester.pump(const Duration(milliseconds: 500));
    pending.last.complete([warehouse(9, 'NEW')]);
    await tester.pumpAndSettle();
    for (final request in pending.where((r) => !r.isCompleted)) {
      request.complete([warehouse(7, 'OLD')]);
    }
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
            .value,
        '9');
    expect(tester.takeException(), isNull);
  });
}
