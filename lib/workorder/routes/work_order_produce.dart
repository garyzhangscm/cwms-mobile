
import 'dart:collection';
import 'dart:core';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/services/item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_status.dart';
import 'package:cwms_mobile/workorder/services/production_line.dart';
import 'package:cwms_mobile/workorder/services/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/services/work_order.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class WorkOrderProducePage extends StatefulWidget{

  WorkOrderProducePage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _WorkOrderProducePageState();

}

class _WorkOrderProducePageState extends State<WorkOrderProducePage> {

  // input batch id
  TextEditingController _workOrderNumberController = new TextEditingController();
  FocusNode _workOrderNumberFocusNode = FocusNode();
  FocusNode _workOrderNumberControllerFocusNode = FocusNode();


  TextEditingController _productionLineController = new TextEditingController();
  FocusNode _productionLineFocusNode = FocusNode();
  FocusNode _productionLineControllerFocusNode = FocusNode();

  WorkOrder _currentWorkOrder;
  ProductionLine _scannedProductionLine;
  ProductionLine _assignedProductionLine;
  ProductionLineAssignment _selectedProductionLineAssignment;


  @override
  void initState() {
    super.initState();

    _currentWorkOrder = null;
    _scannedProductionLine = null;

    _productionLineFocusNode.addListener(() {
      // print("_productionLineFocusNode.hasFocus: ${_productionLineFocusNode.hasFocus}");
      if (!_productionLineFocusNode.hasFocus && _productionLineController.text.isNotEmpty) {
        _enterOnProductionLineController(10);
      }
    });

    _workOrderNumberFocusNode.addListener(() {
      // print("_workOrderNumberFocusNode.hasFocus: ${_workOrderNumberFocusNode.hasFocus}");
      if (!_workOrderNumberFocusNode.hasFocus && _workOrderNumberController.text.isNotEmpty) {
        _enterOnWorkOrderController(10);
      }
    });

  }


  GlobalKey _formKey = new GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {

    // printLongLogMessage("rebuild work order produce");

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context)!.workOrderProduce)),
      resizeToAvoidBottomInset: true,
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

              // _buildWorkOrderNumberAndProductionLineScanner(context),
              _buildButtons(context)
            ],
          ),
      // bottomNavigationBar: buildBottomNavigationBar(context)
      endDrawer: MyDrawer(),
    );
  }

  // scan in barcode to add a order into current batch
  /***
  Widget _buildWorkOrderNumberAndProductionLineScanner(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
              key: _formKey,
              // autovalidateMode: AutovalidateMode.always, //开启自动校验
              child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _workOrderNumberController,
                      decoration: InputDecoration(
                        labelText: CWMSLocalizations
                            .of(context)
                            .workOrderNumber,
                        hintText: CWMSLocalizations
                            .of(context)
                            .inputWorkOrderNumberHint,
                        suffixIcon: IconButton(
                          onPressed: () => _startBarcodeScanner(),
                          icon: Icon(Icons.scanner),
                        ),
                      ),
                    ),

                    TextFormField(
                      controller: _productionLineNameController,
                      decoration: InputDecoration(
                        labelText: CWMSLocalizations
                            .of(context)
                            .productionLine,
                        hintText: CWMSLocalizations
                            .of(context)
                            .inputProductionLineHint,
                        suffixIcon: IconButton(
                          onPressed: () => _startBarcodeScanner(),
                          icon: Icon(Icons.scanner),
                        ),
                      ),
                    ),
                  ]
              )
          )
      );
  }
**/

  Widget _buildWorkOrderNumberInput(BuildContext context) {
    return buildTwoSectionInputRow(
        CWMSLocalizations.of(context)!.workOrderNumber,
        _getWorkOrderInputWidget(context));
  }

  Widget _getWorkOrderInputWidget(BuildContext context) {
    return
      Focus(
          child:
          RawKeyboardListener(
              focusNode: _workOrderNumberFocusNode,
              onKey: (event) {

                printLongLogMessage("event: ${event.logicalKey}");
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

  Widget _buildProductionLineTextBox(BuildContext context) {
    return buildTwoSectionInputRow(
        CWMSLocalizations.of(context)!.productionLine,
        _getProductionLineInputWidget(context));
  }

  Widget _getProductionLineInputWidget(BuildContext context) {
    return
      Focus(
          child:
          RawKeyboardListener(
              focusNode: _productionLineFocusNode,

              onKey: (event) {

                printLongLogMessage("event: ${event.logicalKey}");
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


  Widget _buildProductionLineAssignmentSelection(BuildContext context) {
    return buildTwoSectionInputRow(
        CWMSLocalizations.of(context)!.productionLine,
        DropdownButton(
          hint: Text(CWMSLocalizations.of(context)!.pleaseSelect),
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
              _assignedProductionLine = _selectedProductionLineAssignment.productionLine;

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

      printLongLogMessage("setup the _assignedProductionLine to ${_selectedProductionLineAssignment.productionLine.name}");
      _assignedProductionLine = _selectedProductionLineAssignment.productionLine;
    }
    return items;
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
    printLongLogMessage("_enterOnProductionLineController / _productionLineControllerFocusNode.hasFocus:   ${_productionLineControllerFocusNode.hasFocus}");
    if (_productionLineControllerFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnProductionLineController(tryTime - 1));

      return;

    }

    showLoading(context);


    try {
      printLongLogMessage("start to get the production line by name ${_productionLineController.text}");
      _scannedProductionLine =
          await ProductionLineService.getProductionLineByNumber(_productionLineController.text, loadDetails : false, loadWorkOrderDetails: false);

      printLongLogMessage("## Production line ${_productionLineController.text} found!");
    }
    on WebAPICallException catch(ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, "can't find production line by name ${_productionLineController.text}");
      return;
    }
    if(_scannedProductionLine == null) {

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
    _assignedProductionLine = _scannedProductionLine;

    printLongLogMessage("get work order: ${_currentWorkOrder.number}");
    _workOrderNumberController.text = _currentWorkOrder.number;
    Navigator.of(context).pop();

    if (_currentWorkOrder.item == null) {

      ItemService.getItemById(_currentWorkOrder.itemId).then((item) => _currentWorkOrder.item = item);
    }

    setState(()  {
      _currentWorkOrder;
      _scannedProductionLine;
      _assignedProductionLine;
    });
  }

  _clearField() {
    _workOrderNumberController.text = "";
    _productionLineController.text = "";
    _workOrderNumberControllerFocusNode.requestFocus();
    setState(() {
      _currentWorkOrder = null;
      _scannedProductionLine = null;
      _assignedProductionLine = null;
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

    try {
      _currentWorkOrder = await WorkOrderService.getWorkOrderByNumber(_workOrderNumberController.text);

    }
    on WebAPICallException catch(ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;
    }

    Navigator.of(context).pop();


    if(_currentWorkOrder == null) {

      showErrorDialog(context, "can't find Work order with number ${_workOrderNumberController.text}");
      return;
    }
    // make sure the work order already have production line assigned
    if(_currentWorkOrder.productionLineAssignments.isEmpty) {

      showErrorDialog(context, "Work order " + _currentWorkOrder.number + " doesn't have any production line assigned yet");
      setState(()  {
        _currentWorkOrder = null;
      });
      return;
    }
    if (_currentWorkOrder.status == WorkOrderStatus.CANCELLED || _currentWorkOrder.status == WorkOrderStatus.CLOSED
           || _currentWorkOrder.status == WorkOrderStatus.COMPLETED) {


      showErrorDialog(context, "Work order ${_currentWorkOrder.number} " +
          " is already ${_currentWorkOrder.status.toString().split(".").last}");
      setState(()  {
        _currentWorkOrder = null;
      });
      return;
    }

    //printLongLogMessage("start to work on work order ${_currentWorkOrder.number} with item ${_currentWorkOrder.item.id}");

    if (_currentWorkOrder.item == null) {

      ItemService.getItemById(_currentWorkOrder.itemId).then((item) => _currentWorkOrder.item = item);
    }

    setState(()  {
      _currentWorkOrder;
    });
  }

  Widget _buildButtons(BuildContext context) {

    return
      SizedBox(
        width: double.infinity,
          height: 50,
        child:
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).primaryColor,
            ),
            onPressed: _currentWorkOrder == null || _assignedProductionLine == null ? null : _onStartProduce,
            child: Text(CWMSLocalizations.of(context)!.workOrderProduce),
          )
        );
  }

  Future<void> _onStartProduce() async {

    if (_currentWorkOrder == null || _assignedProductionLine == null) {
      showErrorDialog(context, "can't get the work order or production line information from the input" +
      ".please try again");
      return ;
    }
    Map argumentMap = new HashMap();
    argumentMap['workOrder'] = _currentWorkOrder;
    argumentMap['productionLine'] = _assignedProductionLine;
    _clearField();

    printLongLogMessage("flow to produce inventory page");

    await Navigator.of(context).pushNamed("work_order_produce_inventory", arguments: argumentMap);
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
    // make sure the assigned work has BOM assigned.
    // right now we are only allow the user to consume the material by BOM

    /*
    if (assignedWorkOrder.materialConsumeTime != null &&
        assignedWorkOrder.materialConsumeTime == MaterialConsumeTiming..assignedWorkOrder.consumeByBomOnly == false || assignedWorkOrder.consumeByBom == null) {

      throw new WebAPICallException(
          "There's no BOM setup for the work order ${assignedWorkOrder.number} on this production line ${productionLine.name}"
      );
    }
    */
    return assignedWorkOrder;
  }





  Future<void> _startBarcodeScanner() async {
    // String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
    //     "#ff6666", "Cancel", true, ScanMode.BARCODE);
    // print("barcode scanned: $barcodeScanRes");
    // _workOrderNumberController.text = barcodeScanRes;

  }





}