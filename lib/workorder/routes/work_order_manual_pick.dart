
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
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/services/production_line.dart';
import 'package:cwms_mobile/workorder/services/production_line_assignment.dart';
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


  TextEditingController _productionLineController = new TextEditingController();
  FocusNode _productionLineFocusNode = FocusNode();
  FocusNode _productionLineControllerFocusNode = FocusNode();

  GlobalKey _formKey = new GlobalKey<FormState>();

  WorkOrder _currentWorkOrder;
  // list all the production line that assigned to this work order
  List<ProductionLineAssignment> _productionLineAssignment;
  ProductionLineAssignment _selectedProductionLineAssignment;
  ProductionLine _scannedProductionLine;

  bool _readyToConfirm = true;


  TextEditingController _lpnController = new TextEditingController();
  FocusNode _lpnFocusNode = FocusNode();
  FocusNode _lpnControllerFocusNode = FocusNode();

  List<Inventory>  inventoryOnRF;

  @override
  void initState() {
    super.initState();

    _currentWorkOrder = null;
    _scannedProductionLine = null;
    inventoryOnRF = <Inventory>[];

    _reloadInventoryOnRF();

    _productionLineFocusNode.addListener(() {
      print("_productionLineFocusNode.hasFocus: ${_productionLineFocusNode.hasFocus}");
      if (!_productionLineFocusNode.hasFocus && _productionLineController.text.isNotEmpty) {
        _enterOnProductionLineController(10);
      }
    });

    _workOrderNumberFocusNode.addListener(() {
      print("_workOrderNumberFocusNode.hasFocus: ${_workOrderNumberFocusNode.hasFocus}");
      if (!_workOrderNumberFocusNode.hasFocus && _workOrderNumberController.text.isNotEmpty) {
        _enterOnWorkOrderController(10);
      }
    });
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
              // If the user start with a work order, show the dropdown list to select production line
              // if the user start with a production line, show a text box

              _currentWorkOrder == null || _scannedProductionLine != null ?
                  _buildProductionLineTextBox(context) :
                  _buildProductionLineAssignmentSelection(context),
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
  Widget _buildProductionLineTextBox(BuildContext context) {
    return buildTwoSectionInputRow(
        CWMSLocalizations.of(context).productionLine,
        _getProductionLineInputWidget(context));
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


                // _enterOnWorkOrderController(10);
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


  Widget _getProductionLineInputWidget(BuildContext context) {
    return
      Focus(
          child:
          RawKeyboardListener(
              focusNode: _productionLineFocusNode,
              onKey: (event) {

                if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
                  // Do something


                  // _enterOnProductionLineController(10);
                }
              },
              child:
              TextFormField(
                  controller: _productionLineController,
                  showCursor: true,
                  autofocus: true,
                  focusNode: _productionLineControllerFocusNode,
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
    _productionLineController.text = "";
    _workOrderNumberControllerFocusNode.requestFocus();
    setState(() {
      _currentWorkOrder = null;
      _scannedProductionLine = null;
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
    printLongLogMessage("_enterOnWorkOrderController / _workOrderNumberControllerFocusNode.hasFocus:   ${_workOrderNumberControllerFocusNode.hasFocus}");
    if (_workOrderNumberControllerFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnWorkOrderController(tryTime - 1));

      return;

    }
    showLoading(context);
    _currentWorkOrder = await WorkOrderService.getWorkOrderByNumber(_workOrderNumberController.text);


    Navigator.of(context).pop();
    // make sure the work order already have production line assigned
    if(_currentWorkOrder.productionLineAssignments.isEmpty) {

      showErrorDialog(context, "Work order " + _currentWorkOrder.number + " doesn't have any production line assigned yet");
      _currentWorkOrder = null;
      return;
    }

    _lpnController.text = "";
    setState(()  {
      _currentWorkOrder;
    });
  }

  void _enterOnProductionLineController(int tryTime) async {

    printLongLogMessage("_enterOnProductionLineController");
    // if the user input an empty work order number, then clear the page
    if (_productionLineController.text.isEmpty) {
      _clearField();
      return;
    }
    printLongLogMessage("_enterOnProductionLineController: Start to get production line information, tryTime = $tryTime");
    if (tryTime <= 0) {
      // do nothing as we run out of try time
      return;
    }
    printLongLogMessage("_enterOnWorkOrderController / _productionLineControllerFocusNode.hasFocus:   ${_productionLineControllerFocusNode.hasFocus}");
    if (_productionLineControllerFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnProductionLineController(tryTime - 1));

      return;

    }
    showLoading(context);


    try {
      _scannedProductionLine =
          await ProductionLineService.getProductionLineByNumber(_productionLineController.text);

    }
    on WebAPICallException catch(ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, "can't find production line by name ${_productionLineController.text}");
      return;
    }

    printLongLogMessage("get production line: ${_scannedProductionLine.name}");
    try {
      _currentWorkOrder = await _getAssignedWorkOrder(_scannedProductionLine);

    }
    on WebAPICallException catch(ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;
    }

    printLongLogMessage("get work order: ${_currentWorkOrder.number}");
    _workOrderNumberController.text = _currentWorkOrder.number;
    Navigator.of(context).pop();

    _lpnController.text = "";
    setState(()  {
      _currentWorkOrder;
      _scannedProductionLine;
    });
  }

  Future<WorkOrder> _getAssignedWorkOrder(ProductionLine productionLine) async {

    WorkOrder assignedWorkOrder;
    List<WorkOrder> workOrders =
    await ProductionLineAssignmentService.getAssignedWorkOrderByProductionLine(productionLine);

    printLongLogMessage("workOrders.length: ${workOrders.length}");
    if (workOrders.length == 0) {
      // we should only have one work order that assigned to the specific production line
      // at a time
      throw new WebAPICallException(
          "Can't find any work order that assigned to the production line ${productionLine.name}"
      );

    }
    else if (workOrders.length == 1 ){
      assignedWorkOrder = workOrders[0];
    }
    // we found multiple work order that assigned to the production line, make sure
    // the user specify the work order number as well
    else if (_workOrderNumberController.text.isEmpty) {
      throw new WebAPICallException(
          "multiple work orders found. please specify the work order number as well"
      );
    }
    else {
      // see if the work order number specified by the user matches any of the work order that
      // assigned to the production
      assignedWorkOrder = workOrders.firstWhere((workOrder) => _workOrderNumberController.text == workOrder.number);
    }
    return assignedWorkOrder;
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

  List<DropdownMenuItem> _getProductionLineAssignmentItems()  {
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

    // check if we can fully pick from the LPN
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
    if (_scannedProductionLine == null &&  _selectedProductionLineAssignment == null) {
      showErrorDialog(context, "please select a production line");
      return;
    }

    //verify if we can pick full quantity from the LPN or partial quantity

    showLoading(context);
    bool continuePicking = true;
    bool continueWholeLPN = true;

    ProductionLine productionLine = _scannedProductionLine == null ?
        _selectedProductionLineAssignment.productionLine : _scannedProductionLine;

    try {
      List<Inventory> inventories = await InventoryService.findInventory(lpn: _lpnController.text);

      // check the quantity we can pick from the invenotry
      int pickableQuantity = await WorkOrderService.getPickableQuantityForManualPick(
          _currentWorkOrder.id, _lpnController.text,
          productionLine.id
      );

      // check the total quantity of the LPN
      int inventoryQuantity =  inventories.fold(0, (previous, current) => previous + current.quantity);


      if (pickableQuantity < inventoryQuantity) {

        // ok, we will need to inform the user that it will be a partial pick
        await showYesNoCancelDialog(context, "partial pick",
            "The LPN has quantity of $inventoryQuantity but the work order only requires $pickableQuantity," +
            " do you want to continue with a partial pick? \nYes to pick partial LPN. \nNo to pick whole LPN, \nCancel to cancel the pick",
            () {
                    // the user press Yes, continue with partial quantity
                    continuePicking= true;
                    continueWholeLPN = false;
            },
            () {
              // the user press Yes, continue with partial quantity
              continuePicking= true;
              continueWholeLPN = true;
            },
            ()  => continuePicking = false);
      }
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

    Navigator.of(context).pop();
    if (!continuePicking) {
      return;
    }


    showLoading(context);
    try {
      List<Pick> picks = await WorkOrderService.generateManualPick(
          _currentWorkOrder.id, _lpnController.text,
          productionLine.id, continueWholeLPN

      );
      printLongLogMessage("get ${picks.length} by generating manual pick for the work order ${_currentWorkOrder.number}");

      // let's finish each pick one by one
      for(var i = 0; i < picks.length; i++){

        printLongLogMessage("start to confirm pick # $i, quantity ${picks[i].quantity - picks[i].pickedQuantity}");
        await PickService.confirmPick(
            picks[i], (picks[i].quantity - picks[i].pickedQuantity), _lpnController.text);
      }
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