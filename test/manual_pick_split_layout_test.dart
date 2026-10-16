import 'dart:io';
import 'dart:ui' as ui;
import 'package:cwms_mobile/outbound/widgets/manual_pick_split_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 430.0]) {
    for (final keep in [false, true]) {
      testWidgets('split dialog fits width $width, original for order=$keep',
          (tester) async {
        tester.view.physicalSize = Size(width, 932);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final output = Platform.environment['MES_SPLIT_PREVIEW_DIR'];
        if (output != null) {
          await tester.runAsync(() async {
            final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
            if (font.existsSync())
              await (FontLoader('SplitPreview')
                    ..addFont(Future.value(
                        ByteData.sublistView(font.readAsBytesSync()))))
                  .load();
          });
        }
        final key = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
            key: key,
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                    fontFamily: output != null ? 'SplitPreview' : null),
                home: const Scaffold(
                    body: Center(
                        child: ManualPickSplitDialog(
                            sourceLpn: 'L000000001',
                            sourceQuantity: 325,
                            pickableQuantity: 40))))));
        await tester.pumpAndSettle();
        if (keep) {
          await tester.tap(find.text('Original LPN goes with this order'));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
        if (output != null && width == 430) {
          await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject() as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            File('$output/split-${keep ? 'original-for-order' : 'original-for-remainder'}.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
          });
        }
      });
    }
  }
}
