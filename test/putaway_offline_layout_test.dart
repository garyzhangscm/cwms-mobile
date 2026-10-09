import 'package:cwms_mobile/inventory/routes/inventory_putaway.dart';
import 'package:cwms_mobile/inventory/services/putaway_sync_queue.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'small-screen scans stay saved offline, clear does not delete queue, reopening restores them',
      (tester) async {
    String? saved;
    final queue = PutawaySyncQueue(
        read: () async => saved,
        write: (v) async {
          saved = v;
        },
        sessionMatches: () => true,
        probe: () async {
          throw PutawaySyncFailure('offline', retryable: true);
        },
        synchronize: (_) async => PutawaySyncResult(1, 'I'));
    await queue.initialize(startTimer: false);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.reset);
    Widget page() => MaterialApp(
        locale: const Locale('en', 'US'),
        supportedLocales: const [Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          CWMSLocalizationsDelegate()
        ],
        home: InventoryPutawayPage(queueLoader: () async => queue));
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'L0000108453');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(queue.pendingCount, 1);
    expect(saved, contains('L0000108453'));
    expect(tester.takeException(), isNull);
    await tester.enterText(
        find.byType(TextFormField), 'qrcode:lpn=L0000108452;');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(queue.pendingCount, 2);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '');
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(queue.pendingCount, 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(queue.pendingCount, 2);
    expect(find.textContaining('2 pending'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    queue.dispose();
  });
}
