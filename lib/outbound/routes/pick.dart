import 'package:cwms_mobile/inventory/services/cycle_count_request.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/models/pick_result.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
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

  final  _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Pick currentPick  = ModalRoute.of(context).settings.arguments;

    setupControllers(currentPick);

    return Scaffold(
      appBar: AppBar(title: Text("CWMS - Pick")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.always, //开启自动校验
          child: Column(
            children: <Widget>[

              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
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
              ),
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
                  // display the location
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
              ),
              Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child:
                    // confirm the location
                    Row(
                        children: <Widget>[
                          Text("Location:",
                            textAlign: TextAlign.left,
                          ),
                          Expanded(
                            child:
                              Focus(
                                child: TextFormField(
                                    controller: _sourceLocationController,
                                    decoration: InputDecoration(
                                      suffixIcon: IconButton(
                                        onPressed: () => _startLocationBarcodeScanner(),
                                        icon: Icon(Icons.scanner),
                                      ),
                                    ),
                                    // 校验company code（不能为空）
                                    validator: (v) {
                                      if (v.trim().isEmpty) {
                                        return "please scan in location";
                                      }
                                      if (v.trim() != currentPick.sourceLocation.name) {

                                        return "wrong location";
                                      }
                                      return null;

                                    }),
                              ),
                          )
                        ]
                    ),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child:
                    // display the item
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
              ),
              Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child:
                    // confirm the location
                    Row(
                        children: <Widget>[
                          Text("Item Number:",
                            textAlign: TextAlign.left,
                          ),
                          Expanded(
                            child:
                            Focus(
                              child: TextFormField(

                                  controller: _itemController,
                                  decoration: InputDecoration(
                                    suffixIcon: IconButton(
                                      onPressed: () => _startItemBarcodeScanner(),
                                      icon: Icon(Icons.scanner),
                                    ),
                                  ),
                                  // 校验ITEM NUMBER（不能为空）
                                  validator: (v) {

                                    if (v.trim().isEmpty) {
                                      return "please scan in item";
                                    }
                                    if (v.trim() != currentPick.item.name) {

                                      return "wrong item";
                                    }
                                    return null;
                                  }),
                            ),
                          )
                        ]
                    ),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child:
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
              ),
              Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child:
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
              ),
              Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child:
                    // always force the user to input / confirm the quantity
                    // picked this time
                    Row(
                        children: <Widget>[
                          Text("Picking Quantity:",
                            textAlign: TextAlign.left,
                          ),
                          Expanded(
                            child:
                            Focus(
                              child: TextFormField(
                                  keyboardType: TextInputType.number,
                                  controller: _quantityController,
                                  // 校验ITEM NUMBER（不能为空）
                                  validator: (v) {

                                    if (v.trim().isEmpty) {
                                      return "please type in quantity";
                                    }
                                    if (int.parse(v.trim()) >
                                          (currentPick.quantity - currentPick.pickedQuantity)) {

                                      return "over pick is not allowed";
                                    }
                                    return null;
                                  }),
                            ),
                          )
                        ]
                    ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 25),
                child: ConstrainedBox(
                  constraints: BoxConstraints.expand(height: 55.0),
                  child: RaisedButton(
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                       if (_formKey.currentState.validate()) {
                         print("form validation passed");
                         _onPickConfirm(currentPick, int.parse(_quantityController.text));
                       }

                    },
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
  void _onPickConfirm(Pick pick, int confirmedQuantity) async {


    // TO-DO:Current we don't support the location code. Will add
    //      it later


    showLoading(context);
    await PickService.confirmPick(
        pick, confirmedQuantity);
    print("pick confirmed");

    Navigator.of(context).pop();
    showToast("pick confirmed");

    var pickResult = PickResult.fromJson(
        {'result': true, 'confirmedQuantity': confirmedQuantity});

    Navigator.pop(context, pickResult);
  }

  setupControllers(Pick pick) {

    if(pick.confirmItemFlag == false) {
      _itemController.text = pick.item.name;
    }
    if (pick.confirmLocationFlag == false &&
        pick.confirmLocationCodeFlag == false) {
      _sourceLocationController.text = pick.sourceLocation.name;
    }
    if (pick.quantity > pick.pickedQuantity) {

      _quantityController.text = (pick.quantity - pick.pickedQuantity).toString();
    }
    else {
      _quantityController.text = "0";
    }
  }

  _startItemBarcodeScanner()  async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print("barcode scanned: $barcodeScanRes");
    _sourceLocationController.text = barcodeScanRes;

  }
  _startLocationBarcodeScanner() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print("barcode scanned: $barcodeScanRes");
    _itemController.text = barcodeScanRes;

  }


}