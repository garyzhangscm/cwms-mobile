
import 'dart:core';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class TextFieldWithNoKeyboard extends EditableText {
  TextFieldWithNoKeyboard(
      {required TextEditingController controller,
        required TextStyle style,
        required Function onValueUpdated,
        required Color cursorColor,
        bool autofocus = false,
        required Color selectionColor})
      : super(
      controller: controller,
      focusNode: TextfieldFocusNode(),
      style: style,
      cursorColor: cursorColor,
      autofocus: autofocus,
      selectionColor: selectionColor,
      backgroundCursorColor: Colors.black,
      onChanged: (value) {
        onValueUpdated(value);
      });

  @override
  EditableTextState createState() {
    return TextFieldEditableState();
  }
}

//This is to hide keyboard when user tap on textfield.
class TextFieldEditableState extends EditableTextState {
  @override
  void requestKeyboard() {
    super.requestKeyboard();
    //hide keyboard
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }
}

// This hides keyboard from showing on first focus / autofocus
class TextfieldFocusNode extends FocusNode {
  @override
  bool consumeKeyboardToken() {
    return false;
  }
}