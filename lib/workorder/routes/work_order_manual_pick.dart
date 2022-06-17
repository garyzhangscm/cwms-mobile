
import 'dart:collection';
import 'dart:core';

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
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:cwms_mobile/workorder/models/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/services/work_order.dart';
import 'package:cwms_mobile/workorder/widgets/work_order_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:badges/badges.dart';
import 'package:flutter/services.dart';


class WorkOrderManualPickPage extends StatefulWidget{

  WorkOrderManualPickPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _WorkOrderManualPickPageState();

}

class _WorkOrderManualPickPageState extends State<WorkOrderManualPickPage> {

  // input batch id
  TextEditingController _workOrderNumberController = new TextEditingController();
  FocusNode _workOrderNumberFocusNode = FocusNode();
  FocusNode _workOrderNumberControllerFocusNode = FocusNode();

  GlobalKey _formKey = new GlobalKey<FormState>();

  WorkOrder _currentWorkOrder;
  // list all the production line that assigned to this work order
  List<ProductionLineAssignment> _productionLineAssignment;
  ProductionLineAssignment _selectedProductionLineAssignment;

  bool _readyToConfirm = true;


  TextEditingController _lpnController = new TextEditingController();
  FocusNode _lpnFocusNode = FocusNode();
  FocusNode _lpnControllerFocusNode = FocusNode();

  List<Inventory>  inventoryOnRF;

  @override
  void initState() {
    super.initState();

    _currentWorkOrder = null;
    inventoryOnRF = <Inventory>[];

    _reloadInventoryOnRF();

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).pickByWorkOrder)),
      body:
          Column(
            children: [

              // input controller for work order number
              _buildWorkOrderNumberInput(context),
              // dropdown list to select production line
              _currentWorkOrder == null ? Container() : _buildProductionLineAssignmentSelection(context),
              // allow user to scan in LPN
              _currentWorkOrder == null ? Container() : _buildLPNInput(context),
              // allow user to input LPN
              _buildButtons(context),
            ],
          ),
      // bottomNavigationBar: buildBottomNavigationBar(context)
      endDrawer: MyDrawer(),
    );
  }
  Widget _buildWorkOrderNumberInput(BuildContext context) {
    return buildTwoSectionInputRow(
              CWMSLocalizations.of(context).workOrderNumber,
              _getWorkOrderInputWidget(context));
  }

  Widget _getWorkOrderInputWidget(BuildContext context) {
    return
      Focus(
        child:
          RawKeyboardListener(
            focusNode: _workOrderNumberFocusNode,
            onKey: (event) {

              if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
                // Do something


                _enterOnWorkOrderController(10);
              }
            },
            child:
                TextFormField(
                  controller: _workOrderNumberController,
                  showCursor: true,
                  autofocus: true,
                  focusNode: _workOrderNumberControllerFocusNode,
                  decoration: InputDecoration(
                  suffixIcon:
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                      mainAxisSize: MainAxisSize.min, // added line
                      children: <Widget>[
                        IconButton(
                          onPressed: () => _clearField(),
                          icon: Icon(Icons.close),
                          ),
                      ],
                    ),
                  )

                )
          )
      );


  }

  _clearField() {
    _workOrderNumberController.text = "";
    _workOrderNumberControllerFocusNode.requestFocus();
    setState(() {
      _currentWorkOrder = null;
    });
  }

  void _enterOnWorkOrderController(int tryTime) async {

    // if the user input an empty work order number, then clear the page
    if (_workOrderNumberController.text.isEmpty) {
      _clearField();
      return;
    }
    printLongLogMessage("_enterOnWorkOrderController: Start to get work order information, tryTime = $tryTime");
    if (tryTime <= 0) {
      // do nothing as we run out of try time
      return;
    }
    printLongLogMessage("_enterOnWorkOrderController / _workOrderNumberFocusNode.hasFocus:   ${_workOrderNumberFocusNode.hasFocus}");
    if (_workOrderNumberControllerFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnWorkOrderController(tryTime - 1));

      return;

    }
    showLoading(context);
    _currentWorkOrder = await WorkOrderService.getWorkOrderByNumber(_workOrderNumberController.text);

    setState(()  {
      _currentWorkOrder;
    });

    Navigator.of(context).pop();
  }

  Widget _buildProductionLineAssignmentSelection(BuildContext context) {
    return buildTwoSectionInputRow(
        CWMSLocalizations.of(context).productionLine,
        DropdownButton(
          hint: Text(CWMSLocalizations.of(context).pleaseSelect),
          items: _getProductionLineAssignmentItems(),
          value: _selectedProductionLineAssignment,
          elevation: 1,
          isExpanded: true,
          icon: Icon(
            Icons.list,
            size: 20,
          ),
          onChanged: (T) {
            //下拉菜单item点击之后的回调
            setState(() {
              _selectedProductionLineAssignment = T;
            });
          },
        )
    );
  }

  List<DropdownMenuItem> _getProductionLineAssignmentItems() {
    List<DropdownMenuItem> items = [];
    if (_currentWorkOrder.productionLineAssignments == null || _currentWorkOrder.productionLineAssignments.length == 0) {
      return items;
    }

    // _selectedInventoryStatus = _validInventoryStatus[0];
    for (int i = 0; i < _currentWorkOrder.productionLineAssignments.length; i++) {
      items.add(DropdownMenuItem(
        value: _currentWorkOrder.productionLineAssignments[i],
        child: Text(_currentWorkOrder.productionLineAssignments[i].productionLine.name),
      ));
    }

    if (_currentWorkOrder.productionLineAssignments.length == 1 ||
        _selectedProductionLineAssignment == null) {
      // if we only have one valid inventory status, then
      // default the selection to it
      // if the user has not select any inventdry status yet, then
      // default the value to the first option as well
      _selectedProductionLineAssignment = _currentWorkOrder.productionLineAssignments[0];
    }
    return items;
  }

  Widget _buildLPNInput(BuildContext context) {
    return
      buildTwoSectionInputRow(
        CWMSLocalizations.of(context).lpn,
        Focus(
            child:
            RawKeyboardListener(
              focusNode: _lpnFocusNode,
              onKey: (event) {

                if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
                  // Do something

                  setState(() {
                    // disable the confirm button
                    _readyToConfirm = false;
                  });

                  printLongLogMessage("user pressed enter, lpn is: ${_lpnController.text}");
                  _enterOnLPNController(10);
                }
              },
              child:
                SystemControllerNumberTextBox(
                    type: "lpn",
                    controller: _lpnController,
                    focusNode: _lpnControllerFocusNode,
                    readOnly: false,
                    showKeyboard: false,
                    validator: (v) {
                      if (v.trim().isEmpty) {
                        return CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).lpn);
                      }

                      return null;
                    }),
            )
        ),
      );
  }

  void _enterOnLPNController(int tryTime) async {
    // we may come here when the user scan / press
    // enter in the LPN controller. In either case, we will need to make sure
    // the lpn doesn't have focus before we start confirm

    printLongLogMessage("_enterOnLPNController: Start to confirm work order produced inventory, tryTime = $tryTime");
    if (tryTime <= 0) {
      // do nothing as we run out of try time

      setState(() {
        // enable the confirm button
        _readyToConfirm = true;
      });
      return;
    }
    printLongLogMessage("_enterOnLPNController / lpnFocusNode.hasFocus:   ${_lpnFocusNode.hasFocus}");
    if (_lpnFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnLPNController(tryTime - 1));

      return;

    }
    // if we are here, then it means we already have the full LPN
    // due to how  flutter handle the input, we will get the enter
    // action listner handler fired before the input characters are
    // full assigned to the lpnController.

      printLongLogMessage("2. form passed validation");
      printLongLogMessage("2. _readyToConfirm? $_readyToConfirm");
      // set ready to confirm to fail so other trigger point
      // won't process the receiving request
      // the issue happens when we have 2 trigger point to process
      // the receiving request
      // 1. LPN blur
      // 2. confirm button click
      // so when we blur the LPN controller by clicking the confirm button, the
      // _onRecevingConfirm function will be fired twice
      printLongLogMessage("2. set _readyToConfirm to false");
      _readyToConfirm = false;
      _onWorkOrderMaualPickConfirm();


  }


  Widget _buildButtons(BuildContext context) {

    return Column(
      children: [

        buildTwoButtonRow(context,
            ElevatedButton(
                onPressed: _currentWorkOrder == null ? null : _onWorkOrderMaualPickConfirm,
                child: Text(CWMSLocalizations.of(context).confirm),
            ),
            Badge(
              showBadge: true,
              padding: EdgeInsets.all(8),
              badgeColor: Colors.deepPurple,
              badgeContent: Text(
                inventoryOnRF.length.toString(),
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              child:
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: ElevatedButton(
                    onPressed: inventoryOnRF.length == 0 ? null : _startDeposit,
                    child: Text(CWMSLocalizations.of(context).depositInventory),
                  ),
                ),
            )
        )
      ],
    );

  }

  _onWorkOrderMaualPickConfirm() async {

    // make sure the user input an valid LPN
    if (_lpnController.text.isEmpty) {
      showErrorDialog(context, "LPN is required");
      _lpnControllerFocusNode.requestFocus();
      return;
    }

    // make sure the user select a production line
    if (_selectedProductionLineAssignment == null) {
      showErrorDialog(context, "please select a production line");
      return;
    }
    showLoading(context);
    try {
      await WorkOrderService.processManualPick(
          _currentWorkOrder.id, _lpnController.text,
          _selectedProductionLineAssignment.productionLine.id

      );
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      _lpnControllerFocusNode.requestFocus();
      return;

    }

    Navigator.of(context).pop();
    _refreshScreenAfterPickConfirm();

  }
  _refreshScreenAfterPickConfirm(){
    // after we sucessfully pick the LPN, clear the LPN field
    _lpnController.text = "";
    _lpnControllerFocusNode.requestFocus();
    _reloadInventoryOnRF();
  }

  void _reloadInventoryOnRF() {

    InventoryService.getInventoryOnCurrentRF()
        .then((value) {
      setState(() {
        inventoryOnRF = value;
      });
    });

  }

  // call the deposit form to deposit the inventory on the RF
  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the inventory on the RF
    _reloadInventoryOnRF();
  }



}