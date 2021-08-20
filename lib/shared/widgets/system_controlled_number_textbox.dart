

import 'package:cwms_mobile/common/services/system_controlled_number.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SystemControllerNumberTextBox extends StatefulWidget {
  SystemControllerNumberTextBox({this.type, this.controller, this.validator, this.readOnly,
  this.showKeyboard = true}
       ) : super(key: ValueKey(type));


  final String type;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final bool readOnly;
  final bool showKeyboard;




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
    });
  }
  _clearField() {

    widget.controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    // print("system_controlled_number_textbox: widget.showKeyboard: ${widget.showKeyboard}");
    return TextFormField(
              controller: widget.controller,
              validator: widget.validator,
              showCursor: true,
              readOnly: widget.readOnly,
              showKeyboard: widget.showKeyboard,
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
                    ],
                  ),
              )

    );
  }
}
