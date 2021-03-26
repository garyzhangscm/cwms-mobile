import 'package:cwms_mobile/inventory/services/cycle_count_request.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


class PickPage extends StatefulWidget{

  PickPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _PickPageState();

}

class _PickPageState extends State<PickPage> {

  // input batch id
  TextEditingController _itemController = new TextEditingController();
  TextEditingController _sourceLocationController = new TextEditingController();
  TextEditingController _quantityController = new TextEditingController();

  GlobalKey _formKey = new GlobalKey<FormState>();
  int pickedQuantity = 10;

  @override
  Widget build(BuildContext context) {
    Pick currentPick  = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(title: Text("CWMS - Pick")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.always, //开启自动校验
          child: Column(
            children: <Widget>[

              Row(
                  children: <Widget>[
                      Text("Work Number:",
                        textAlign: TextAlign.left,
                      ),
                      Text(currentPick.number,
                        textAlign: TextAlign.left,
                      ),
                  ]
              ),
              Row(
                  children: <Widget>[
                    Text("Location:",
                      textAlign: TextAlign.left,
                    ),
                    Text(currentPick.sourceLocation.name,
                      textAlign: TextAlign.left,
                    ),
                  ]
              ),
              Row(
                  children: <Widget>[
                    Text("Item Number:",
                      textAlign: TextAlign.left,
                    ),
                    Text(currentPick.item.name,
                      textAlign: TextAlign.left,
                    ),
                  ]
              ),
              Row(
                  children: <Widget>[
                    Text("Pick Quantity:",
                      textAlign: TextAlign.left,
                    ),
                    Text(currentPick.quantity.toString(),
                      textAlign: TextAlign.left,
                    ),
                  ]
              ),
              Row(
                  children: <Widget>[
                    Text("Picked Quantity:",
                      textAlign: TextAlign.left,
                    ),
                    Text(currentPick.pickedQuantity.toString(),
                      textAlign: TextAlign.left,
                    ),
                  ]
              ),

              Padding(
                padding: const EdgeInsets.only(top: 25),
                child: ConstrainedBox(
                  constraints: BoxConstraints.expand(height: 55.0),
                  child: RaisedButton(
                    color: Theme.of(context).primaryColor,
                    onPressed: _onPickConfirm,
                    textColor: Colors.white,
                    child: Text("Confirm"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _onPickConfirm() {
    Navigator.pop(context, pickedQuantity);
  }

}