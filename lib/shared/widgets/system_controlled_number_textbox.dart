

import 'package:cwms_mobile/common/services/system_controlled_number.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SystemControllerNumberTextBox extends StatefulWidget {
  SystemControllerNumberTextBox({this.type, this.controller, this.validator}
       ) : super(key: ValueKey(type));


  final String type;
  final TextEditingController controller;
  final FormFieldValidator<String> validator;




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

  @override
  Widget build(BuildContext context) {
    return TextFormField(
              controller: widget.controller,
              validator: widget.validator,decoration: InputDecoration(
              suffixIcon: IconButton(
                onPressed: () => _generateNextAvailableNumber(),
                icon:  Icon(
                    Icons.double_arrow,
                  ),
              ),
            ),

    );
  }
}
