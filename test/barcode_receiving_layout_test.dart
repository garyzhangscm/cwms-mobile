import 'package:cwms_mobile/inbound/widgets/barcode_receiving_layout.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(430, 932),
    const Size(1194, 834)
  ]) {
    testWidgets('barcode receiving fits $size with keyboard and long receipt',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
        body: BarcodeReceivingLayout(
          scanTitle: 'Barcode Receiving',
          scanInstructions:
              'Scan in the barcode or click the button to start the camera',
          recentTitle: 'Last received inventory',
          barcodeInput: const TextField(),
          actions: Builder(
              builder: (context) => buildTwoButtonRow(
                  context,
                  ElevatedButton(
                      onPressed: () {}, child: const Text('Start Camera')),
                  ElevatedButton(
                      onPressed: null, child: const Text('Deposit')))),
          recentInventory: const Text(
              'RECPT0000000020\nABS-C-YT-WH-08\nLong item description that must wrap within the card.'),
        ),
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final title = tester.widget<Text>(find.text('Last received inventory'));
      expect(title.style?.decoration, TextDecoration.none);
      await tester.ensureVisible(find.text('Deposit'));
      expect(tester.takeException(), isNull);
    });
  }
}
