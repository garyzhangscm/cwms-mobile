
import 'dart:collection';
import 'dart:core';

import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/auth/services/user.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/models/pick_result.dart';
import 'package:cwms_mobile/outbound/services/order.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/outbound/widgets/order_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/bottom_navigation_bar.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/workorder/models/bill_of_material.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/production_line_activity.dart';
import 'package:cwms_mobile/workorder/models/production_line_activity_type.dart';
import 'package:cwms_mobile/workorder/models/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_labor.dart';
import 'package:cwms_mobile/workorder/models/work_order_produce_transaction.dart';
import 'package:cwms_mobile/workorder/services/bill_of_material.dart';
import 'package:cwms_mobile/workorder/services/production_line.dart';
import 'package:cwms_mobile/workorder/services/production_line_activity.dart';
import 'package:cwms_mobile/workorder/services/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/services/work_order.dart';
import 'package:cwms_mobile/workorder/widgets/work_order_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:badges/badges.dart';
import 'package:intl/intl.dart';


class ProductionLineCheckOutPage extends StatefulWidget{

  ProductionLineCheckOutPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _ProductionLineCheckOutPageState();

}

class _ProductionLineCheckOutPageState extends State<ProductionLineCheckOutPage> {

  // input batch id
  TextEditingController _usernameController = new TextEditingController();
  FocusNode _usernameFocusNode;
  bool _incorrectUsername;

  TextEditingController _productionLineNameController = new TextEditingController();
  FocusNode _productionLineNameNode;
  bool _incorrectProductionLinename;

  WorkOrderLabor _workOrderLabor;

  final  _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _workOrderLabor = null;
    _usernameFocusNode = FocusNode();

    _productionLineNameNode = FocusNode();
    _incorrectUsername = false;
    _incorrectProductionLinename = false;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).productionLineCheckOut)),
      body:
          Column(
            children: [
              _buildForm(context),
              _buildButtons(context),
              _buildLastCheckInTransactionDisplay(context)
            ],
          ),
      // bottomNavigationBar: buildBottomNavigationBar(context)
      endDrawer: MyDrawer(),
    );
  }

  // scan in barcode to add a order into current batch
  Widget _buildForm(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
              key: _formKey,
              // autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
              child: Column(
                  children: <Widget>[

                    // scan in production line
                    Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 10),
                      child:
                      Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(right: 20),
                              child:
                              Text(CWMSLocalizations.of(context).productionLine,
                                textAlign: TextAlign.left,
                              ),
                            ),

                            Expanded(
                                child:
                                  TextFormField(
                                    focusNode: _productionLineNameNode,
                                    controller: _productionLineNameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      suffixIcon: IconButton(
                                        onPressed: () => _startProductionLineBarcodeScanner(),
                                        icon: Icon(Icons.scanner),
                                      ),
                                    ),
                                    validator: (v) {

                                      if (_incorrectProductionLinename) {
                                        return CWMSLocalizations.of(context).incorrectValue(CWMSLocalizations.of(context).productionLine);
                                      }
                                      return v.trim().isNotEmpty ? null :
                                          CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).productionLine);
                                    },
                                ),
                            ),
                          ]
                      ),
                    ),

                    // scan in username
                    Padding(
                      padding: EdgeInsets.only(top: 10, bottom: 10),
                      child:
                      Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(right: 20),
                              child:
                              Text(CWMSLocalizations.of(context).userName,
                                textAlign: TextAlign.left,
                              ),
                            ),

                            Expanded(
                                child:
                                  TextFormField(
                                    focusNode: _usernameFocusNode,
                                    controller: _usernameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      suffixIcon: IconButton(
                                        onPressed: () => _startUsernameBarcodeScanner(),
                                        icon: Icon(Icons.scanner),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (_incorrectUsername) {
                                        return CWMSLocalizations.of(context).incorrectValue(CWMSLocalizations.of(context).userName);
                                      }
                                      return v.trim().isNotEmpty ? null :
                                          CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).userName);
                                    },
                                ),
                            ),
                          ]
                      ),
                    ),
                  ]
              )
          )
      );
  }


  Widget _buildButtons(BuildContext context) {

    return
      SizedBox(
        width: double.infinity,
          height: 50,
        child:
          RaisedButton(
            color: Theme.of(context).primaryColor,

            onPressed: () {
              // clear the data we use to manually show the
              // error and start validate the form from a
              // clear start
              _incorrectProductionLinename = false;
              _incorrectUsername = false;
              if (_formKey.currentState.validate()) {
                print("form validation passed");
                _onStartCheckOut();
              }

            },
            textColor: Colors.white,
            child: Text(CWMSLocalizations.of(context).productionLineCheckOut),
          )
        );


  }
  Widget _buildLastCheckInTransactionDisplay(BuildContext context) {

    return
      ListTile(
          dense: true,


          title: _buildTransactionDetails(),

      );

  }

  Widget _buildTransactionDetails() {
    return
      new Container(

        child:
        new Column(
            children: [
              buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context).productionLine,
                  _workOrderLabor == null ? "" : _workOrderLabor.productionLine.name
              ),
              buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context).userName,
                  _workOrderLabor == null ? "" : _workOrderLabor.username
              ),
              buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context).transactionTime,
                  _workOrderLabor == null ?
                  "" :
                  DateFormat("MM/dd/yyyy HH:mm:ss").format(_workOrderLabor.lastCheckInTime)
              ),

            ]
        ),
      );
  }

  Future<void> _onStartCheckOut() async {

    showLoading(context);
    printLongLogMessage("start to get production line by ${_productionLineNameController.text}");
    ProductionLine productionLine =
          await ProductionLineService.getProductionLineByNumber(_productionLineNameController.text);

    // make sure the production line is valid
    if (productionLine == null) {
      Navigator.of(context).pop();
      _productionLineNameNode.requestFocus();
      _incorrectUsername = false;
      _incorrectProductionLinename = true;
      _formKey.currentState.validate();
      return;
    }
    printLongLogMessage("get production line: ${productionLine.name}");




    try {
      _workOrderLabor =
          await ProductionLineService.checkOutUser(productionLine.id, _usernameController.text);

    }
    on WebAPICallException catch(ex) {


      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

    setState(() {
      _workOrderLabor;
    });
    Navigator.of(context).pop();

    print("production line check out transaction saved!");

    showToast(CWMSLocalizations.of(context).actionComplete);

    _usernameController.clear();
    _productionLineNameController.clear();
  }

  _startProductionLineBarcodeScanner() async {
    String productionLineName = await _startBarcodeScanner();
    _productionLineNameController.text = productionLineName;
  }

  _startUsernameBarcodeScanner() async {
    String username = await _startBarcodeScanner();
    _usernameController.text = username;
  }



  Future<String> _startBarcodeScanner() async {
    /**
     *
        String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
        print("barcode scanned: $barcodeScanRes");

        if (barcodeScanRes != "-1") {
        return barcodeScanRes;
        }
        else {
        return "";
        }
      */
  }





}