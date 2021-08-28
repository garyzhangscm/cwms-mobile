import 'dart:convert';

import 'package:badges/badges.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inbound/models/receipt.dart';
import 'package:cwms_mobile/inbound/models/receipt_line.dart';
import 'package:cwms_mobile/inbound/services/receipt.dart';
import 'package:cwms_mobile/inbound/widgets/receipt_line_list_item.dart';
import 'package:cwms_mobile/inbound/widgets/receipt_list_item.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:cwms_mobile/workorder/models/bill_of_material.dart';
import 'package:cwms_mobile/workorder/models/bill_of_material_line.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_kpi_transaction_action.dart';
import 'package:cwms_mobile/workorder/models/work_order_line_consume_transaction.dart';
import 'package:cwms_mobile/workorder/models/work_order_produce_transaction.dart';
import 'package:cwms_mobile/workorder/models/work_order_produced_inventory.dart';
import 'package:cwms_mobile/workorder/services/bill_of_material.dart';
import 'package:cwms_mobile/workorder/services/production_line_assignment.dart';
import 'package:cwms_mobile/workorder/services/work_order.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


class WorkOrderProduceInventoryPage extends StatefulWidget{

  WorkOrderProduceInventoryPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _WorkOrderProduceInventoryPageState();

}

class _WorkOrderProduceInventoryPageState extends State<WorkOrderProduceInventoryPage> {

  // input batch id

  TextEditingController _itemController = new TextEditingController();
  TextEditingController _quantityController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();

  WorkOrder _currentWorkOrder;
  ProductionLine _currentProductionLine;

  List<InventoryStatus> _validInventoryStatus;
  InventoryStatus _selectedInventoryStatus;
  ItemPackageType _selectedItemPackageType;

  BillOfMaterial _matchedBillOfMaterial;
  FocusNode lpnFocusNode = FocusNode();



  @override
  void initState() {
    super.initState();
    _currentWorkOrder = new WorkOrder();
    _selectedInventoryStatus = new InventoryStatus();
    _selectedItemPackageType = new ItemPackageType();

    // get all inventory status to display
    InventoryStatusService.getAllInventoryStatus()
        .then((value) {
          setState(() {
            _validInventoryStatus = value;
            if (_validInventoryStatus.length > 0) {
              _selectedInventoryStatus = _validInventoryStatus[0];
            }
          });
    });
  }
  final  _formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {

    Map arguments  = ModalRoute.of(context).settings.arguments as Map ;
    _currentWorkOrder = arguments['workOrder'];
    
    _currentProductionLine = arguments['productionLine'];

    _matchedBillOfMaterial = arguments['billOfMaterial'];


    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).workOrderProduce)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          //autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[

              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                          Text(CWMSLocalizations.of(context).workOrderNumber,
                            textAlign: TextAlign.left,
                          ),
                      ),
                      Text(_currentWorkOrder.number,
                        textAlign: TextAlign.left,
                      ),
                    ]
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                // confirm the location
                Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                            Text(CWMSLocalizations.of(context).item,
                              textAlign: TextAlign.left,
                            ),
                      ),
                      Text(_currentWorkOrder.item.name,
                        textAlign: TextAlign.left,
                      ),
                    ]
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                // confirm the location
                Row(
                    children: <Widget>[

                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                            Text(CWMSLocalizations.of(context).item,
                              textAlign: TextAlign.left,
                            ),
                      ),
                      Text(_currentWorkOrder.item.description,
                        textAlign: TextAlign.left,
                      ),
                    ]
                ),
              ),
              // display the item
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                            Text(CWMSLocalizations.of(context).expectedQuantity,
                              textAlign: TextAlign.left,
                            ),
                      ),
                      Text(_currentWorkOrder.expectedQuantity.toString(),
                        textAlign: TextAlign.left,
                      ),
                    ]
                ),
              ),
             // show the matched BOM
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                        Text(CWMSLocalizations.of(context).billOfMaterial,
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Text(_matchedBillOfMaterial == null ? "" : _matchedBillOfMaterial.number,
                        textAlign: TextAlign.left,
                      ),
                    ]
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                Row(
                    children: <Widget>[

                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                            Text(CWMSLocalizations.of(context).producedQuantity,
                              textAlign: TextAlign.left,
                            ),
                      ),
                      Text(_currentWorkOrder.producedQuantity.toString(),
                        textAlign: TextAlign.left,
                      ),
                    ]
                ),
              ),
              // Allow the user to choose item package type
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                            Text(CWMSLocalizations.of(context).itemPackageType,
                              textAlign: TextAlign.left,
                            ),
                      ),
                      Expanded(
                          child:
                          DropdownButton(
                            hint: Text("请选择"),
                            items: _getItemPackageTypeItems(),
                            value: _selectedItemPackageType,
                            elevation: 1,
                            isExpanded: true,
                            icon: Icon(
                              Icons.list,
                              size: 20,
                            ),
                            onChanged: (T) {
                              //下拉菜单item点击之后的回调
                              setState(() {
                                _selectedItemPackageType = T;
                              });
                            },
                          )
                      )
                    ]
                ),
              ),
              // Allow the user to choose inventory status
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                Row(
                    children: <Widget>[

                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                            Text(CWMSLocalizations.of(context).inventoryStatus,
                              textAlign: TextAlign.left,
                            ),
                      ),
                      Expanded(
                          child:
                          DropdownButton(
                            hint: Text("请选择"),
                            items: _getInventoryStatusItems(),
                            value: _selectedInventoryStatus,
                            elevation: 1,
                            isExpanded: true,
                            icon: Icon(
                              Icons.list,
                              size: 20,
                            ),
                            onChanged: (T) {
                              //下拉菜单item点击之后的回调
                              setState(() {
                                _selectedInventoryStatus = T;
                              });
                            },
                          )
                      )
                    ]
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                // always force the user to input / confirm the quantity
                // picked this time
                Row(
                    children: <Widget>[

                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                            Text(CWMSLocalizations
                                .of(context)
                                .producingQuantity + ": ",
                              textAlign: TextAlign.left,
                            ),
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

                                return null;
                              }),
                        ),
                      )
                    ]
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                // always force the user to input / confirm the quantity
                // picked this time
                Row(
                    children: <Widget>[

                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                            Text(CWMSLocalizations
                                .of(context)
                                .lpn+ ": ",
                              textAlign: TextAlign.left,
                            ),
                      ),
                      Expanded(
                        child:
                        Focus(
                          child:
                          RawKeyboardListener(
                              focusNode: lpnFocusNode,
                              onKey: (event) {

                                printLongLogMessage("user pressed : ${event.logicalKey}");
                                if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
                                  // Do something
                                  printLongLogMessage("user pressed enter");
                                }
                              },
                              child:
                                SystemControllerNumberTextBox(
                                  type: "lpn",
                                  controller: _lpnController,
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
                      )
                    ]
                ),
              ),
              _buildButtons(context)

            ],
          ),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }
  Widget _buildButtons(BuildContext context) {
    return
      SizedBox(
        width: double.infinity,
        height: 50,
            child:
                Row(
                  children: <Widget> [
                    Expanded(
                      child:
                        Padding(
                            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                            child:
                              RaisedButton(
                                color: Theme.of(context).primaryColor,
                                onPressed: () {
                                  if (_formKey.currentState.validate()) {
                                    print("form validation passed");
                                    _onWorkOrderProduceConfirm(_currentWorkOrder,
                                        int.parse(_quantityController.text),
                                        _lpnController.text);
                                  }

                                },
                                textColor: Colors.white,
                                child: Text(CWMSLocalizations
                                    .of(context)
                                    .confirm),
                              ),
                        ),
                    ),
                    /***
                     * Remove the KPI button as of 06/22/2021
                    Expanded(
                      child:
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                          child:
                            RaisedButton(
                              color: Theme.of(context).primaryColor,
                              onPressed: () {
                                if (_formKey.currentState.validate()) {
                                  print("form validation passed");
                                  _onWorkOrderProduceWithKPI(_currentWorkOrder,
                                      int.parse(_quantityController.text),
                                      _lpnController.text);
                                }

                              },
                              textColor: Colors.white,
                              child: Text(CWMSLocalizations
                                  .of(context)
                                  .kpi),
                            ),
                        ),
                    ),
                    **/

                  ]
                )

      );
  }




  List<DropdownMenuItem> _getInventoryStatusItems() {
    List<DropdownMenuItem> items = new List();
    if (_validInventoryStatus == null || _validInventoryStatus.length == 0) {
      return items;
    }

    _selectedInventoryStatus = _validInventoryStatus[0];
    for (int i = 0; i < _validInventoryStatus.length; i++) {
      print("start to create download list for _getInventoryStatusItems: ");
      items.add(DropdownMenuItem(
        value: _validInventoryStatus[i],
        child: Text(_validInventoryStatus[i].description),
      ));
    }
    return items;
  }

  List<DropdownMenuItem> _getItemPackageTypeItems() {
    List<DropdownMenuItem> items = new List();

    print("_currentReceiptLine.item.itemPackageTypes.length: ${_currentWorkOrder.item.itemPackageTypes.length}");
    if (_currentWorkOrder.item.itemPackageTypes.length > 0) {
      _selectedItemPackageType = _currentWorkOrder.item.itemPackageTypes[0];

      for (int i = 0; i < _currentWorkOrder.item.itemPackageTypes.length; i++) {

        items.add(DropdownMenuItem(
          value: _currentWorkOrder.item.itemPackageTypes[i],
          child: Text(_currentWorkOrder.item.itemPackageTypes[i].description),
        ));
      }
    }
    return items;
  }


  Future<void> _onWorkOrderProduceWithKPI(WorkOrder workOrder, int confirmedQuantity,
      String lpn) async {


    showLoading(context);

    WorkOrderProduceTransaction workOrderProduceTransaction =
        await generateWorkOrderProduceTransaction(
        _lpnController.text, _selectedInventoryStatus,
        _selectedItemPackageType, int.parse(_quantityController.text)
    );

    Navigator.of(context).pop();
    // flow to the KPI capture page

    final result = await Navigator.of(context).pushNamed(
        "work_order_produce_kpi", arguments: workOrderProduceTransaction);


    if (result ==  null) {
      // the user press Return, let's do nothing

      return null;
    }

    if ((result as WorkOrderKPITransactionAction) == WorkOrderKPITransactionAction.CANCELLED) {
      // THE USER cancelled the KPI transaction, let's do nothing and wait the user
      // to either start a new KPI capture transaction, or confirm without KPI
      return null;
    }
    else {
      // The user confirmed the whole produce transaction with KPI, let's
      // clear the page

      _lpnController.clear();
      _quantityController.clear();
    }
  }



  void _onWorkOrderProduceConfirm(WorkOrder workOrder, int confirmedQuantity,
      String lpn) async {



    showLoading(context);

    // make sure the user input a valid LPN
    try {
      bool validLpn = await InventoryService.validateNewLpn(lpn);
      if (!validLpn) {
        Navigator.of(context).pop();
        showErrorDialog(context, "LPN is not valid, please make sure it follow the right format");
        return;
      }
      printLongLogMessage("LPN ${lpn} passed the validation");
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

    printLongLogMessage("Start to prepare the work order produce transaction");

    WorkOrderProduceTransaction workOrderProduceTransaction =
        await generateWorkOrderProduceTransaction(
            _lpnController.text, _selectedInventoryStatus,
            _selectedItemPackageType, int.parse(_quantityController.text)
        );

    try {
      await WorkOrderService.saveWorkOrderProduceTransaction(
          workOrderProduceTransaction
      );
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

    print("inventory produced!");
    // refresh the work order to reflect the produced quantity
    _refreshWorkOrderInformation();
   //  printLongLogMessage("start to print lpn label: $lpn, findPrinterBy: ${workOrderProduceTransaction.productionLine.name}");
    // InventoryService.printLPNLabel(lpn, workOrderProduceTransaction.productionLine.name);

    Navigator.of(context).pop();
    showToast("inventory produced");
    // we will allow the user to continue receiving with the same
    // receipt and line
    _lpnController.clear();
    _quantityController.clear();


  }

  _refreshWorkOrderInformation() {
    WorkOrderService.getWorkOrderByNumber(_currentWorkOrder.number)
        .then((workOrder)  { 

            setState(() {
              _currentWorkOrder.producedQuantity = workOrder.producedQuantity;
            });
        });


  }
  Future<WorkOrderProduceTransaction> generateWorkOrderProduceTransaction(
      String lpn, InventoryStatus selectedInventoryStatus,
      ItemPackageType selectedItemPackageType, int quantity) async {
    WorkOrderProduceTransaction workOrderProduceTransaction = new WorkOrderProduceTransaction();
    workOrderProduceTransaction.workOrder = _currentWorkOrder;
    workOrderProduceTransaction.productionLine = _currentProductionLine;

    workOrderProduceTransaction.workOrderKPITransactions = [];

    WorkOrderProducedInventory workOrderProducedInventory = new WorkOrderProducedInventory();
    workOrderProducedInventory.lpn = lpn;
    workOrderProducedInventory.quantity = quantity;
    workOrderProducedInventory.inventoryStatus = selectedInventoryStatus;
    workOrderProducedInventory.inventoryStatusId = selectedInventoryStatus.id;
    workOrderProducedInventory.itemPackageType = selectedItemPackageType;
    workOrderProducedInventory.itemPackageTypeId = selectedItemPackageType.id;
    List<WorkOrderProducedInventory> workOrderProducedInventoryList = new List<WorkOrderProducedInventory>();
    workOrderProducedInventoryList.add(workOrderProducedInventory);

    workOrderProduceTransaction.workOrderProducedInventories = workOrderProducedInventoryList;

    List<WorkOrderLineConsumeTransaction> workOrderLineConsumeTransactions =
       [];
    workOrderProduceTransaction.consumeByBomQuantity = true;
    workOrderProduceTransaction.consumeByBom = _matchedBillOfMaterial;

    // We are now only allow consume by BOM when producing from mobile
    // in case of consuming by BOM, we won't have to setup the
    // WorkOrderLineConsumeTransaction
    // setup the work order line consume transaction based on teh 
    // matched bom
    /**
     *
        _currentWorkOrder.workOrderLines.forEach((workOrderLine) {

        WorkOrderLineConsumeTransaction workOrderLineConsumeTransaction
        = new WorkOrderLineConsumeTransaction();
        workOrderLineConsumeTransaction.workOrderLine = workOrderLine;
        if (_matchedBillOfMaterial != null) {

        printLongLogMessage("matchedBillOfMaterial: ${_matchedBillOfMaterial.toJson()}");
        printLongLogMessage("matchedBillOfMaterial.billOfMaterialLines: ${_matchedBillOfMaterial.billOfMaterialLines.length}");


        BillOfMaterialLine matchedBillOfMaterialLine =
        _matchedBillOfMaterial.billOfMaterialLines.firstWhere((billOfMaterialLine)  {
        printLongLogMessage("billOfMaterialLine.itemId: ${billOfMaterialLine.itemId}");
        printLongLogMessage("workOrderLine.itemId: ${workOrderLine.itemId}");
        return billOfMaterialLine.itemId == workOrderLine.itemId;
        }
        );

        workOrderLineConsumeTransaction.consumedQuantity =
        ((matchedBillOfMaterialLine.expectedQuantity * quantity) /
        _matchedBillOfMaterial.expectedQuantity).round();
        workOrderLineConsumeTransactions.add(workOrderLineConsumeTransaction);
        }
        else {

        workOrderLineConsumeTransaction.consumedQuantity = 0;
        workOrderLineConsumeTransactions.add(workOrderLineConsumeTransaction);
        }

        });
     */
    printLongLogMessage("workOrderLineConsumeTransactions.length: ${workOrderLineConsumeTransactions.length}");
    workOrderProduceTransaction.workOrderLineConsumeTransactions =
        workOrderLineConsumeTransactions;
    
    

    return workOrderProduceTransaction;
  }


}