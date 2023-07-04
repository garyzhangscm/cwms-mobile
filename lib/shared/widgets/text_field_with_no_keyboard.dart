
import 'dart:collection';
import 'dart:core';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/models/rf_app_version.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:progress_dialog/progress_dialog.dart';

import '../global.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart';
class TextFieldWithNoKeyboard extends EditableText {
  TextFieldWithNoKeyboard(
      {@required TextEditingController controller,
        @required TextStyle style,
        @required Function onValueUpdated,
        @required Color cursorColor,
        bool autofocus = false,
        Color selectionColor})
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