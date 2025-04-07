
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


class ProductionLineCheckInPage extends StatefulWidget{

  ProductionLineCheckInPage({Key? key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _ProductionLineCheckInPageState();

}

class _ProductionLineCheckInPageState extends State<ProductionLineCheckInPage> {

  // input batch id
  TextEditingController _usernameController = new TextEditingController();
  FocusNode? _usernameFocusNode;
  bool? _incorrectUsername;
  User? _currentUser;


  // TextEditingController _productionLineNameController = new TextEditingController();
  // FocusNode _productionLineNameNode;
  bool? _incorrectProductionLine;

  WorkOrderLabor? _workOrderLabor;


  List<ProductionLine> _validProductionLines = [];
  ProductionLine? _selectedProductionLine;
  FocusNode? _productionLineNode;

  final  _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _workOrderLabor = null;
    _usernameFocusNode = FocusNode();
    _incorrectUsername = false;
    // _productionLineNameNode = FocusNode();
    _incorrectProductionLine = false;
    _currentUser = null;

    // get all assigned production line for check in
    ProductionLineService.getAllAssignedProductionLines()
        .then((value) {
      setState(() {
        _validProductionLines = value;
        _selectedProductionLine = null;

        // if (_validProductionLines.length > 0) {
        //   _selectedProductionLine = _validProductionLines[0];
        // }
      });
    });

    _usernameFocusNode?.addListener(() {
      print("_usernameFocusNode.hasFocus: ${_usernameFocusNode?.hasFocus}");
      if (!_usernameFocusNode!.hasFocus && _usernameController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _loadUserInformation(_usernameController.text);


      }
    });
  }

  _loadUserInformation(String username) {

    try {

      UserService.findUser(Global.lastLoginCompanyId!, username).then((value)
      {
        setState(() {

          _currentUser = value;
        });
      });
    }
    on WebAPICallException catch(ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context)!.productionLineCheckIn)),
      resizeToAvoidBottomInset: true,
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
                    // Allow the user to choose production line
                    buildTwoSectionInputRow(
                        CWMSLocalizations.of(context)!.productionLine,
                        DropdownButton(
                          focusNode: _productionLineNode,
                          hint: Text(CWMSLocalizations.of(context)!.pleaseSelect),
                          items: _getValidProductionLines(),
                          value: _selectedProductionLine == null ?  null : _selectedProductionLine,
                          elevation: 1,
                          isExpanded: true,
                          icon: Icon(
                            Icons.list,
                            size: 20,
                          ),
                          onChanged: (ProductionLine? value) {
                            printLongLogMessage("user selected ${value}");
                            //下拉菜单item点击之后的回调
                            setState(() {
                              _selectedProductionLine = value;
                              printLongLogMessage("_selectedProductionLine ${_selectedProductionLine?.name}");
                            });
                          },
                        )
                    ),
                    buildTwoSectionInputRow(
                        CWMSLocalizations.of(context)!.userName,
                        TextFormField(
                        focusNode: _usernameFocusNode,
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (_incorrectUsername == true) {
                            return CWMSLocalizations.of(context)!.incorrectValue(CWMSLocalizations.of(context)!.userName);
                          }
                          return v!.trim().isNotEmpty ? null :
                          CWMSLocalizations.of(context)!.missingField(CWMSLocalizations.of(context)!.userName);
                        },
                      ),
                    ),
                    _currentUser == null? new Container() :
                      buildTwoSectionInformationRow(

                        CWMSLocalizations.of(context)!.userName,
                          _currentUser!.username! + " (" + _currentUser!.firstname! + ", " + _currentUser!.lastname! + ")"
                      )
                    /**
                    Padding(
                      padding: EdgeInsets.only(top: 5, bottom: 5),
                      child:
                      Row(
                          children: <Widget>[

                            Padding(
                              padding: EdgeInsets.only(right: 20),
                              child:
                              Text(CWMSLocalizations.of(context)!.productionLine,
                                textAlign: TextAlign.left,
                              ),
                            ),
                            Expanded(
                                child:
                                DropdownButton(
                                  focusNode: _productionLineNode,
                                  hint: Text(CWMSLocalizations.of(context)!.pleaseSelect),
                                  items: _getValidProductionLines(),
                                  value: _selectedProductionLine == null ?  null : _selectedProductionLine,
                                  elevation: 1,
                                  isExpanded: true,
                                  icon: Icon(
                                    Icons.list,
                                    size: 20,
                                  ),
                                  onChanged: (T) {
                                    printLongLogMessage("user selected ${T}");
                                    //下拉菜单item点击之后的回调
                                    setState(() {
                                      _selectedProductionLine = T;
                                      printLongLogMessage("_selectedProductionLine ${_selectedProductionLine.name}");
                                    });
                                  },
                                )
                            )
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
                              Text(CWMSLocalizations.of(context)!.userName,
                                textAlign: TextAlign.left,
                              ),
                            ),

                            Expanded(
                                child:
                                  TextFormField(
                                    focusNode: _usernameFocusNode,
                                    controller: _usernameController,
                                    textInputAction: TextInputAction.next,
                                    validator: (v) {
                                      if (_incorrectUsername) {
                                        return CWMSLocalizations.of(context)!.incorrectValue(CWMSLocalizations.of(context)!.userName);
                                      }
                                      return v.trim().isNotEmpty ? null :
                                          CWMSLocalizations.of(context)!.missingField(CWMSLocalizations.of(context)!.userName);
                                    },
                                ),
                            ),
                          ]
                      ),
                    ),
                     */
                  ]
              )
          )
      );
  }



  List<DropdownMenuItem<ProductionLine>> _getValidProductionLines() {
    List<DropdownMenuItem<ProductionLine>> items = [];
    if (_validProductionLines == null || _validProductionLines.length == 0) {
      return items;
    }
    for (int i = 0; i < _validProductionLines.length; i++) {
      // printLongLogMessage("#${i}: add production line with id: ${ _validProductionLines[i].id}");
      items.add(DropdownMenuItem(
        value: _validProductionLines[i],
        child: Text(_validProductionLines[i].name!),
      ));
    }
    return items;
  }

  Widget _buildButtons(BuildContext context) {

    return
      SizedBox(
        width: double.infinity,
          height: 50,
        child:
          ElevatedButton(
            onPressed:
                _selectedProductionLine == null  ?
                null :
                    () {
                      // clear the data we use to manually show the
                      // error and start validate the form from a
                      // clear start
                      _incorrectProductionLine = false;
                      _incorrectUsername = false;
                      if (_formKey.currentState!.validate()) {
                        print("form validation passed");
                        _onStartCheckIn();
                      }

                    },
            child: Text(CWMSLocalizations.of(context)!.productionLineCheckIn),
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
                  CWMSLocalizations.of(context)!.productionLine,
                  _workOrderLabor?.productionLine?.name ?? ""
              ),
              buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context)!.userName,
                      _workOrderLabor?.username ?? ""
              ),
              buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context)!.transactionTime,
                  _workOrderLabor == null ?
                    "" :
                    DateFormat("MM/dd/yyyy HH:mm:ss").format(_workOrderLabor!.lastCheckInTime!)
              ),

            ]
        ),
      );
  }

  Future<void> _onStartCheckIn() async {

    showLoading(context);
    printLongLogMessage("start to get production line by ${_selectedProductionLine != null? _selectedProductionLine?.name : "" }");
    // ProductionLine productionLine =
    //       await ProductionLineService.getProductionLineByNumber(_productionLineNameController.text);

    // make sure the production line is valid
    if (_selectedProductionLine == null) {
      Navigator.of(context).pop();
      _productionLineNode?.requestFocus();
      _incorrectUsername = false;
      _incorrectProductionLine = true;
      _currentUser = null;
      _formKey.currentState?.validate();
      return;
    }
    // make sure the user name is valid
    User? user = await UserService.findUser(Global.lastLoginCompanyId!, _usernameController.text);
    if (user == null) {

      Navigator.of(context).pop();
      _usernameFocusNode?.requestFocus();
      _incorrectUsername = true;
      _currentUser = null;
      _formKey.currentState?.validate();
      return;
    }
    printLongLogMessage("get production line: ${_selectedProductionLine?.name}");

    // let's get the work order that current is active on this production line
    List<WorkOrder> workOrders =
        await ProductionLineAssignmentService.getAssignedWorkOrderByProductionLine(_selectedProductionLine!);

    if (workOrders.isEmpty) {
      // no work order is assigned yet, there's no need to check in
      // an empty production line
      showToast(CWMSLocalizations.of(context)!.noWorkOrderFoundOnProductionLine);
      Navigator.of(context).pop();
      return;

    }



    try {
      _workOrderLabor =
          await ProductionLineService.checkInUser(_selectedProductionLine!.id!, _usernameController.text);

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

    print("production line check in transaction saved!");

    showToast(CWMSLocalizations.of(context)!.actionComplete);
    _usernameController.clear();
    _usernameFocusNode?.requestFocus();
    _currentUser = null;
    // _selectedProductionLine.clear();
  }








}