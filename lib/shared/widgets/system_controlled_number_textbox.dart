

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
  }
  _showKeyBoard() {
    printLongLogMessage("Start to show keyboard");
    setState(() {
      widget.showKeyboard = true;
    });
    // SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  @override
  Widget build(BuildContext context) {
    // print("system_controlled_number_textbox: widget.showKeyboard: ${widget.showKeyboard}");
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
                      widget.showKeyboard ?
                          Container() :
                          IconButton(
                            onPressed: () => _showKeyBoard(),
                            icon: Icon(
                              Icons.keyboard_alt,
                            ),
                          ),
                    ],
                  ),
              )

    );
  }
}
