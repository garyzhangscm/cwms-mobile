import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [220.0, 360.0]) {
    testWidgets('Receiving LPN focus, manual entry and scanner at width $width', (tester) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(width: width,
        child: SystemControllerNumberTextBox(type: 'lpn', controller: controller,
          focusNode: focus, showKeyboard: false, directInput: true)))));
      await tester.tap(find.byIcon(Icons.keyboard_alt));
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      tester.testTextInput.enterText('W00000000001');
      expect(controller.text, 'W00000000001');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(controller.text, isEmpty);
      focus.unfocus();
      await tester.pump();
      final box = tester.getRect(find.byType(EditableText));
      await tester.tapAt(box.centerLeft + const Offset(8, 0));
      await tester.pump();
      expect(focus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyW, character: 'W');
      for (final digit in '00000000001'.split('')) {
        await tester.sendKeyEvent(LogicalKeyboardKey.findKeyByKeyId(digit.codeUnitAt(0))!,character: digit);
      }
      // Flutter test hardware events don't synthesize IME commits on Android.
      tester.testTextInput.updateEditingValue(const TextEditingValue(text:'W00000000001'));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(controller.text,'W00000000001');
      expect(focus.hasFocus,isFalse);
      expect(tester.takeException(),isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      focus.dispose();
    });
  }
}
