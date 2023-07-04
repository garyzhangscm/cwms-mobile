

import 'package:cwms_mobile/common/services/system_controlled_number.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemControllerNumberTextBox extends StatefulWidget {
  SystemControllerNumberTextBox({this.type, this.controller, this.validator, this.readOnly,
  this.showKeyboard = true, this.focusNode, this.autofocus = true, this.onValueChanged}
       ) : super(key: ValueKey(type));


  final String type;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  FormFieldValidator<String> onValueChanged;
  final bool readOnly;

  final FocusNode focusNode;
  final bool autofocus;
  bool showKeyboard;




  @override
  _SystemControllerNumberTextBoxState createState() => _SystemControllerNumberTextBoxState();


}

class _SystemControllerNumberTextBoxState extends State<SystemControllerNumberTextBox> {


  @override
  void initState() {
    super.initState();

    widget.focusNode.addListener(() {
      print("widget.focusNode.hasFocus: ${widget.focusNode.hasFocus}");
      if (widget.focusNode.hasFocus) {
        // if we tab out, then add the LPN to the list
        _showKeyBoard(widget.showKeyboard);
        // _itemFocusNode.requestFocus();

      }
    });
  }
  _generateNextAvailableNumber() {
    SystemControlledNumberService
        .getNextAvailableId(widget.type)
        .then((value)  {
          printLongLogMessage("Get the next number for ${widget.type}, value is ${value}");
          widget.controller.text = value;
          widget.onValueChanged(value);
    });
  }
  _clearField() {

    widget.controller.clear();

    _showKeyBoard(false);
  }
  _changeKeyboardType() {

    _showKeyBoard(!widget.showKeyboard);
  }

  _showKeyBoard(bool showKeyboard) {
    setState(() {
      widget.showKeyboard = showKeyboard;
    });
/**
    widget.focusNode.unfocus();
    Future.delayed(Duration(milliseconds:1), (){
      FocusScope.of(context).requestFocus(widget.focusNode);
    });
    **/
    if (widget.showKeyboard) {
      printLongLogMessage("start to show keyboard");
      Future.delayed(
        Duration(),
            () => SystemChannels.textInput.invokeMethod('TextInput.show'),
      );
      // SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    }
    else {
      printLongLogMessage("start to HIDE keyboard");
      Future.delayed(
        Duration(),
            () => SystemChannels.textInput.invokeMethod('TextInput.hide'),
      );
      // SystemChannels.textInput.invokeMethod('TextInput.hide');
    }
  }


  @override
  Widget build(BuildContext context) {
    return TextFormField(
              controller: widget.controller,
              validator: widget.validator,
              showCursor: true,
              readOnly: widget.readOnly,
              enabled: !widget.readOnly,
              // showKeyboard: widget.showKeyboard,
              autofocus: widget.autofocus,
              focusNode: widget.focusNode,
              decoration: InputDecoration(
                suffixIcon:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                    mainAxisSize: MainAxisSize.min, // added line
                    children: <Widget>[
                      IconButton(
                        onPressed: () => _generateNextAvailableNumber(),
                        icon:  Icon(
                          Icons.double_arrow,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _clearField(),
                        icon: Icon(Icons.close),
                      ),
                      IconButton(
                        onPressed: () => _changeKeyboardType(),
                        icon: Icon(
                          Icons.keyboard_alt,
                        ),
                      ),
                      /**
                      widget.showKeyboard ?
                          Container() :
                          IconButton(
                            onPressed: () => _showKeyBoard(),
                            icon: Icon(
                              Icons.keyboard_alt,
                            ),
                          ),
                          **/
                    ],
                  ),
              )

    );
  }
}
