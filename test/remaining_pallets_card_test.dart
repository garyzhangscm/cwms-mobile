import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/outbound/models/remaining_pallet_demand.dart';
import 'package:cwms_mobile/outbound/widgets/remaining_pallets_card.dart';

const lines = [
  RemainingPalletDemand(
      itemName: 'DEMO PRODUCT A',
      quantity: 84,
      unit: 'PCS',
      unitsPerPallet: 36),
  RemainingPalletDemand(
      itemName: 'DEMO PRODUCT B',
      quantity: 400,
      unit: 'PCS',
      unitsPerPallet: 240),
];
void main() {
  Future<void> open(WidgetTester tester, Widget card,
      {String locale = 'en', double scale = 1}) async {
    await tester.pumpWidget(MaterialApp(
        locale: Locale(locale),
        supportedLocales: const [Locale('en'), Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(body: SingleChildScrollView(child: card)))));
    await tester.pumpAndSettle();
  }

  testWidgets('shows total and each full/partial standard pallet breakdown',
      (tester) async {
    await open(tester, const RemainingPalletsCard(lines: lines));
    expect(find.text('Estimated: 5 pallets'), findsOneWidget);
    expect(find.text('2 full pallets + 12 PCS'), findsOneWidget);
    expect(find.text('1 full pallet + 160 PCS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'missing configuration hides total estimate but preserves exact quantity',
      (tester) async {
    await open(
        tester,
        RemainingPalletsCard(lines: [
          lines.first,
          RemainingPalletDemand(itemName: 'NO CONFIG', quantity: 40, unit: null)
        ]));
    expect(find.textContaining('Estimated:'), findsNothing);
    expect(find.text('40 units remaining'), findsOneWidget);
    expect(find.text('Pallet size not configured'), findsOneWidget);
  });
  testWidgets(
      'updating or failed refresh never displays stale counts as current',
      (tester) async {
    await open(
        tester, const RemainingPalletsCard(lines: lines, updating: true));
    expect(find.textContaining('Estimated:'), findsNothing);
    expect(find.text('Updating after confirmation…'), findsOneWidget);
    await open(
        tester, const RemainingPalletsCard(lines: lines, current: false));
    expect(find.textContaining('Estimated:'), findsNothing);
    expect(find.textContaining('Reload the order'), findsOneWidget);
    await open(
        tester,
        const RemainingPalletsCard(
            lines: lines, current: false, pendingConfirmation: true));
    expect(find.textContaining('Finish the pending pick'), findsOneWidget);
    expect(find.textContaining('Estimated:'), findsNothing);
  });
  for (final locale in ['en', 'es']) {
    testWidgets('narrow screen and larger text remain readable ($locale)',
        (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(tester, const RemainingPalletsCard(lines: lines),
          locale: locale, scale: 1.4);
      expect(tester.takeException(), isNull);
      expect(find.text('DEMO PRODUCT A'), findsOneWidget);
    });
  }
}
