import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cwms_mobile/launch_page.dart';
import 'package:cwms_mobile/auth/routes/login.dart';
import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/models/cwms_site_information.dart';
import 'package:cwms_mobile/shared/models/factory_profile.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';

Widget app(Future<CWMSSiteInformation> Function(FactoryProfile) connect) =>
    MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          CWMSLocalizationsDelegate()
        ],
        home: LaunchPage(enableDebugAutoConnect: false, connector: connect),
        routes: {
          'login_page': (_) => LoginPage(warehouseLoader: (_, __) async => [])
        });
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Global.currentFactory = null;
    Global.autoLoginUser = null;
    Global.currentWarehouse = null;
    Global.currentUser = null;
  });
  test('fixed approved company and server mappings', () {
    expect(FactoryProfile.values.map((f) => f.companyCode), [
      const String.fromEnvironment('INJECTION_COMPANY_CODE'),
      const String.fromEnvironment('INJECTION_COMPANY_CODE'),
      const String.fromEnvironment('INJECTION_COMPANY_CODE'),
      const String.fromEnvironment('LUGGAGE_COMPANY_CODE')
    ]);
    expect(FactoryProfile.values.first.url,
        const String.fromEnvironment('COLTON_API_URL'));
    expect(FactoryProfile.values[1].url,
        const String.fromEnvironment('FAY_API_URL'));
    expect(FactoryProfile.values[2].url, FactoryProfile.values[1].url);
    expect(FactoryProfile.values.last.url,
        const String.fromEnvironment('LUGGAGE_API_URL'));
  });
  test('changing factory clears credentials even at identical URL', () async {
    final first = FactoryProfile.values[1], second = FactoryProfile.values[2];
    await Global.selectFactory(first, CWMSSiteInformation()..url = first.url);
    Global.currentUser = User()..token = 'test-only';
    Global.autoLoginUser = User();
    Global.currentWarehouse = Warehouse()..id = 9;
    Global.lastLoginRFCode = 'RF-test';
    await Global.selectFactory(second, CWMSSiteInformation()..url = second.url);
    expect(Global.currentUser, isNull);
    expect(Global.autoLoginUser, isNull);
    expect(Global.currentWarehouse, isNull);
    expect(Global.lastLoginRFCode, isNull);
    expect(
        (await SharedPreferences.getInstance()).getString('selected_factory'),
        second.id);
  });
  testWidgets('login locks factory company and switch returns to selection',
      (tester) async {
    await tester.pumpWidget(app((_) async => CWMSSiteInformation()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('colton-injection')));
    await tester.pumpAndSettle();
    final field =
        tester.widget<TextFormField>(find.byType(TextFormField).first);
    expect(field.controller!.text, FactoryProfile.values.first.companyCode);
    expect(
        tester.widget<EditableText>(find.byType(EditableText).first).readOnly,
        true);
    expect(find.text('Colton Injection'), findsOneWidget);
    await tester.tap(find.text('Switch factory'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your factory'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('connection failure does not save a factory', (tester) async {
    await tester.pumpWidget(app((_) async => throw StateError('offline')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fay-recycle')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cannot connect'), findsOneWidget);
    expect(Global.currentFactory, isNull);
    expect(
        (await SharedPreferences.getInstance()).getString('selected_factory'),
        isNull);
  });
  testWidgets('all factory cards fit a scrollable small scanner screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app((_) async => CWMSSiteInformation()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('mira-loma-luggage')));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'remembered luggage factory remains selected with locked company code',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {'selected_factory': 'mira-loma-luggage'});
    await tester.pumpWidget(app((_) async => CWMSSiteInformation()));
    await tester.pumpAndSettle();
    expect(find.text('Last selected'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('mira-loma-luggage')));
    await tester.tap(find.byKey(const ValueKey('mira-loma-luggage')));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        FactoryProfile.values.last.companyCode);
    expect(
        tester.widget<EditableText>(find.byType(EditableText).first).readOnly,
        true);
  });
}
