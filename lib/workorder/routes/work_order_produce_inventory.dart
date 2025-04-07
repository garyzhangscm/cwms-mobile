
import 'package:cwms_mobile/common/models/reason_code.dart';
import 'package:cwms_mobile/common/models/reason_code_type.dart';
import 'package:cwms_mobile/common/services/reason_code.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/models/item_unit_of_measure.dart';
import 'package:cwms_mobile/inventory/models/lpn_capture_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/models/cwms_http_exception.dart';
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:cwms_mobile/workorder/models/bill_of_material.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_kpi_transaction_action.dart';
import 'package:cwms_mobile/workorder/models/work_order_line_consume_transaction.dart';
import 'package:cwms_mobile/workorder/models/work_order_produce_transaction.dart';
import 'package:cwms_mobile/workorder/models/work_order_produced_inventory.dart';
import 'package:cwms_mobile/workorder/services/bill_of_material.dart';
import 'package:cwms_mobile/workorder/services/work_order.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

import '../../shared/global.dart';
import '../../shared/models/printing_strategy.dart';



class WorkOrderProduceInventoryPage extends StatefulWidget{

  WorkOrderProduceInventoryPage({Key? key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _WorkOrderProduceInventoryPageState();

}

class _WorkOrderProduceInventoryPageState extends State<WorkOrderProduceInventoryPage> {

  // input batch id

  TextEditingController _quantityController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();

  WorkOrder? _currentWorkOrder;
  ProductionLine? _currentProductionLine;

  List<InventoryStatus> _validInventoryStatus = [];
  InventoryStatus? _selectedInventoryStatus;
  ItemPackageType? _selectedItemPackageType;
  ItemUnitOfMeasure? _selectedItemUnitOfMeasure;
  ProgressDialog? _progressDialog;

  BillOfMaterial? _matchedBillOfMaterial;
  FocusNode lpnFocusNode = FocusNode();
  FocusNode _lpnControllerFocusNode = FocusNode();
  FocusNode quantityFocusNode = FocusNode();
  bool _readyToConfirm = true; // whether we can confirm the produced inventory


  List<ReasonCode> _validReasonCodes = [];
  ReasonCode? _selectedReasonCode;

  // we will force the user to receive by LPN quantity
  bool _forceLPNReceiving = true;

  @override
  void initState() {
    super.initState();


    _currentWorkOrder = new WorkOrder();
    _selectedInventoryStatus = null;
    _selectedItemPackageType = null;

    // get all inventory status to display
    InventoryStatusService.getAllInventoryStatus()
        .then((value) {
          setState(() {
            _validInventoryStatus = value;
            _selectedInventoryStatus = InventoryStatusService.getDefaultInventoryStatusForNewInventory(_validInventoryStatus);
            /**
            if (_validInventoryStatus.length > 0) {
              _selectedInventoryStatus = _validInventoryStatus[0];
            }
                **/
          });
    });

    ReasonCodeService.getReasonCodes(ReasonCodeType.Inventory_Status.name)
        .then((value) {
      setState(() {
        _validReasonCodes = value;
        _selectedReasonCode = null;
      });
    });


    quantityFocusNode.requestFocus();
    // default quantity to 1
    _quantityController.text = "1";
  }
  final  _formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {

    Map arguments  = ModalRoute.of(context)?.settings.arguments as Map ;
    _currentWorkOrder = arguments['workOrder'];

    _currentProductionLine = arguments['productionLine'];

    _loadMatchedBillOfMaterial();
  }
  _loadMatchedBillOfMaterial() {
    if (_matchedBillOfMaterial != null) {
      return;
    }
    else if (_currentWorkOrder?.consumeByBom != null) {
      _matchedBillOfMaterial = _currentWorkOrder?.consumeByBom;
    }
    else {

      BillOfMaterialService.findMatchedBillOfMaterial(_currentWorkOrder!).then((value) => _matchedBillOfMaterial = value);

    }

  }

  @override
  Widget build(BuildContext context) {



    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context)!.workOrderProduce)),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          //autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[

              buildTwoSectionInformationRowWithWidget(
                  CWMSLocalizations.of(context)!.workOrderNumber,
                  _getWorkOrderDisplayWidget(context, _currentWorkOrder!)),
              buildTwoSectionInformationRowWithWidget(
                  CWMSLocalizations.of(context)!.item,
                  _getItemDisplayWidget(context, _currentWorkOrder!.item!)),
/**
              buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context)!.expectedQuantity,
                _currentWorkOrder.expectedQuantity.toString()),
              buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context)!.billOfMaterial,
                  _matchedBillOfMaterial == null ? "" : _matchedBillOfMaterial.number),
              // show the matched BOM
              buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context)!.producedQuantity,
                  _currentWorkOrder.producedQuantity.toString()),
    **/
              // Allow the user to choose item package type
              buildTwoSectionInputRow(
                  CWMSLocalizations.of(context)!.itemPackageType,

                  DropdownButton(
                    hint: Text(CWMSLocalizations.of(context)!.pleaseSelect),
                    items: _getItemPackageTypeItems(),
                    value: _selectedItemPackageType,
                    elevation: 1,
                    isExpanded: true,
                    icon: Icon(
                      Icons.list,
                      size: 20,
                    ),
                    onChanged: (ItemPackageType? value) {
                      //下拉菜单item点击之后的回调
                      setState(() {
                        _selectedItemPackageType = value;
                      });
                    },
                  )
              ),
              // Allow the user to choose inventory status
              buildTwoSectionInputRow(
                  CWMSLocalizations.of(context)!.inventoryStatus,
                  DropdownButton(
                    hint: Text(CWMSLocalizations.of(context)!.pleaseSelect),
                    items: _getInventoryStatusItems(),
                    value: _selectedInventoryStatus,
                    elevation: 1,
                    isExpanded: true,
                    icon: Icon(
                      Icons.list,
                      size: 20,
                    ),
                    onChanged: (InventoryStatus? value) {
                      //下拉菜单item点击之后的回调
                      setState(() {
                        _selectedInventoryStatus = value;
                      });
                    },
                  )
              ),
              _selectedInventoryStatus != null &&
                  (_selectedInventoryStatus?.reasonRequiredWhenProducing == true
                      ||  _selectedInventoryStatus?.reasonOptionalWhenProducing == true) ?
                  _buildReasonCodeDropdown() : Container(),
              /***
               *
                  buildTwoSectionInputRow(
                  CWMSLocalizations.of(context)!.producingQuantity,
                  Focus(
                  child:
                  TextFormField(
                  keyboardType: TextInputType.number,
                  controller: _quantityController,
                  focusNode: quantityFocusNode,
                  // 校验ITEM NUMBER（不能为空）
                  validator: (v) {
                  if (v.trim().isEmpty) {
                  return "please type in quantity";
                  }
                  return null;
                  }),
                  )
                  ),
               */
              Container(
                color: _forceLPNReceiving ? Colors.black26 : Colors.transparent,
                child:
                    buildFourSectionRow(
                      Checkbox(
                          value: !_forceLPNReceiving,
                          onChanged: (bool? value) {
                            setState(() {
                              _forceLPNReceiving = (value == false);
                            });
                          },
                      ),
                      Expanded (
                        child: Text(CWMSLocalizations.of(context)!.quantity + ": ", textAlign: TextAlign.left ),
                      ),
                      _forceLPNReceiving ?
                        SizedBox(
                            width: 20,
                            child: Text("1", textAlign: TextAlign.left )
                        )
                            :
                        SizedBox(
                          height: 20,
                          width: 110,
                          child:
                              TextFormField(
                                  keyboardType: TextInputType.number,
                                  controller: _quantityController,

                                  enabled: _forceLPNReceiving ? false : true,
                                  textInputAction: TextInputAction.next,
                                  autofocus: _forceLPNReceiving ? false : true,
                                  focusNode: quantityFocusNode,
                                  onFieldSubmitted: (v){

                                    _lpnControllerFocusNode.requestFocus();

                                  },
                                  decoration: InputDecoration(
                                    isDense: true,
                                    fillColor: _forceLPNReceiving ? Colors.black12 : Colors.white,
                                    filled: true,
                                  ),
                                  // 校验ITEM NUMBER（不能为空）
                                  validator: (v) {
                                    if (v!.trim().isEmpty) {
                                      return "please type in quantity";
                                    }
                                    return null;
                                  }),
                      ),
                      _getItemUnitOfMeasures().isEmpty ?
                        Container() :
                        _forceLPNReceiving ?
                          SizedBox(
                              width: 60,
                              child:
                                Text(_getLPNUOMName() ?? "",
                                    textAlign: TextAlign.left )
                          )
                            :
                          SizedBox(
                            height: 38,
                            width: 90,
                            child:
                            DropdownButton(

                                      hint: Text(CWMSLocalizations.of(context)!.pleaseSelect),
                                      items: _getItemUnitOfMeasures(),
                                      value: _selectedItemUnitOfMeasure,
                                      elevation: 1,
                                      isExpanded: true,
                                      icon: Icon(
                                        Icons.list,
                                        size: 20,
                                      ),
                                      underline: Container(
                                        height: 0,
                                        color: Colors.deepPurpleAccent,
                                      ),
                                      onChanged: (ItemUnitOfMeasure? value) {
                                        //下拉菜单item点击之后的回调
                                        setState(() {
                                          _selectedItemUnitOfMeasure = value;
                                        });
                                      },
                                    )
                        )
                    )
              ),
              buildTwoSectionInputRow(
                CWMSLocalizations.of(context)!.lpn,
                Focus(
                    child:
                    RawKeyboardListener(
                      focusNode: lpnFocusNode,
                      onKey: (event) {

                        if (event.isKeyPressed(LogicalKeyboardKey.enter) && _readyToConfirm) {
                          // Do something

                          setState(() {
                            // disable the confirm button
                            _readyToConfirm = false;
                          });

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
                              if (v!.trim().isEmpty &&
                                  _getRequiredLPNCount(int.parse(_quantityController.text) * _selectedItemUnitOfMeasure!.quantity!) == 1) {
                                return CWMSLocalizations.of(context)!.missingField(CWMSLocalizations.of(context)!.lpn);
                              }

                              return null;
                            }),
                    )
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
    return buildSingleButtonRow(context,
      ElevatedButton(
        onPressed: !_readyToConfirm ? null : () {

          _readyToConfirm = false;


          if (_formKey.currentState!.validate()) {
            _onWorkOrderProduceConfirm();
/**
            print("1. _readyToConfirm? $_readyToConfirm");
            if (_readyToConfirm == true) {
              _readyToConfirm = false;
              print("1. form validation passed");
              print("1. set _readyToConfirm to false");
              _onWorkOrderProduceConfirm();
            }
    **/
          }
        },
        child: Text(CWMSLocalizations
            .of(context)
            .confirm),
      )
    );

  }

  Widget _buildReasonCodeDropdown() {
    // Allow the user to choose inventory status
    return buildTwoSectionInputRow(
        CWMSLocalizations.of(context)!.reason,
        DropdownButton(
          hint: Text(CWMSLocalizations.of(context)!.pleaseSelect),
          items: _getReasonCodeItems(),
          value: _selectedReasonCode,
          elevation: 1,
          isExpanded: true,
          icon: Icon(
            Icons.list,
            size: 20,
          ),
          onChanged: (ReasonCode? value) {
            //下拉菜单item点击之后的回调
            setState(() {
              _selectedReasonCode = value;
            });
          },
        )
    );

  }


  String? _getLPNUOMName() {

    ItemUnitOfMeasure? lpnUOM = _getLPNUOM();
    if ( lpnUOM == null) {
      return "";
    }
    return lpnUOM.unitOfMeasure?.name;

  }
  ItemUnitOfMeasure? _getLPNUOM() {

    if ( _selectedItemPackageType == null || _selectedItemPackageType?.itemUnitOfMeasures == null ||
        _selectedItemPackageType?.itemUnitOfMeasures.length == 0 || _selectedItemPackageType?.trackingLpnUOM == null) {
      return null;
    }
    return _selectedItemPackageType?.trackingLpnUOM;

  }
  List<DropdownMenuItem<ItemUnitOfMeasure>> _getItemUnitOfMeasures() {
    List<DropdownMenuItem<ItemUnitOfMeasure>> items = [];

    if ( _selectedItemPackageType == null || _selectedItemPackageType?.itemUnitOfMeasures == null ||
        _selectedItemPackageType?.itemUnitOfMeasures.length == 0) {
      // if the user has not selected any item package type yet
      // return nothing
      return items;
    }

    for (int i = 0; i < _selectedItemPackageType!.itemUnitOfMeasures.length; i++) {

      items.add(DropdownMenuItem(
        value:  _selectedItemPackageType?.itemUnitOfMeasures[i],
        child: Text( _selectedItemPackageType?.itemUnitOfMeasures[i].unitOfMeasure?.name ?? ""),
      ));
    }

    // we may have _selectedItemUnitOfMeasure setup by previous item package type.
    // or manually by user. If it is setup by the user, then we won't refresh it
    // otherwise, we will reload the default receiving uom
    // if _selectedItemPackageType.itemUnitOfMeasures doesn't containers the _selectedItemUnitOfMeasure
    // then we know that we just changed the item package type or item, so we will need
    // to refresh the _selectedItemUnitOfMeasure to the default inbound receiving uom as well
    if (_selectedItemUnitOfMeasure == null ||
        !_selectedItemPackageType!.itemUnitOfMeasures.any((element) => element.hashCode == _selectedItemUnitOfMeasure.hashCode)) {
      // if the user has not select any item unit of measure yet, then
      // default the value to the one marked as 'default for inbound receiving'

      // printLongLogMessage("_currentWorkOrder.item: ${_currentWorkOrder.item.toJson()}");
      // printLongLogMessage("_selectedItemPackageType: ${_selectedItemPackageType.toJson()}");
      _selectedItemUnitOfMeasure = _selectedItemPackageType?.itemUnitOfMeasures
          .firstWhereOrNull((element) => element.id == _selectedItemPackageType?.defaultWorkOrderReceivingUOM?.id);
    }

    return items;
  }

  Widget _getItemDisplayWidget(BuildContext context, Item item) {
    return new RichText(
        text: new TextSpan(
                  text: item.name,
                  style: new TextStyle(color: Colors.blue),
                  recognizer: new TapGestureRecognizer()
                    ..onTap = () {
                      showInformationDialog(
                        context, item.name ?? "", Column(
                          children: <Widget>[
                            buildTwoSectionInformationRow(
                                CWMSLocalizations.of(context)!.item,
                                _currentWorkOrder?.item?.name ?? ""),
                            buildTwoSectionInformationRow(
                                CWMSLocalizations.of(context)!.item,
                                _currentWorkOrder?.item?.description ?? ""),

                          ]),
                          verticalPadding: 175.0,
                          horizontalPadding: 50.0

                      );
                    },
    ));

  }
  Widget _getWorkOrderDisplayWidget(BuildContext context, WorkOrder workOrder) {
    return new RichText(
        text: new TextSpan(
          text: workOrder.number,
          style: new TextStyle(color: Colors.blue),
          recognizer: new TapGestureRecognizer()
            ..onTap = () {
              showInformationDialog(
                  context, workOrder.number ?? "", Column(
                  children: <Widget>[

                    buildTwoSectionInformationRow(
                        CWMSLocalizations.of(context)!.expectedQuantity,
                        workOrder.expectedQuantity.toString()),
                    buildTwoSectionInformationRow(
                        CWMSLocalizations.of(context)!.billOfMaterial,
                        _matchedBillOfMaterial?.number ?? ""),
                    // show the matched BOM
                    buildTwoSectionInformationRow(
                        CWMSLocalizations.of(context)!.producedQuantity,
                        workOrder.producedQuantity.toString()),

                  ]),

                  verticalPadding: 175.0,
                  horizontalPadding: 50.0
              );
            },
        ));

  }


  List<DropdownMenuItem<ReasonCode>> _getReasonCodeItems() {

    List<DropdownMenuItem<ReasonCode>> items = [];
    if (_validReasonCodes == null || _validReasonCodes.length == 0) {
      _selectedReasonCode = null;
      return items;
    }

    // _selectedInventoryStatus = _validInventoryStatus[0];
    for (int i = 0; i < _validReasonCodes.length; i++) {
      items.add(DropdownMenuItem(
        value: _validReasonCodes[i],
        child: Text(_validReasonCodes[i].name ?? ""),
      ));
    }
    return items;
  }


  List<DropdownMenuItem<InventoryStatus>> _getInventoryStatusItems() {
    List<DropdownMenuItem<InventoryStatus>> items = [];
    if (_validInventoryStatus == null || _validInventoryStatus.length == 0) {
      return items;
    }

    // _selectedInventoryStatus = _validInventoryStatus[0];
    for (int i = 0; i < _validInventoryStatus.length; i++) {
      items.add(DropdownMenuItem(
        value: _validInventoryStatus[i],
        child: Text(_validInventoryStatus[i].description ?? ""),
      ));
    }

    if (_validInventoryStatus.length == 1 ||
        _selectedInventoryStatus == null) {
      // if we only have one valid inventory status, then
      // default the selection to it
      // if the user has not select any inventdry status yet, then
      // default the value to the first option as well
      _selectedInventoryStatus = _validInventoryStatus[0];
    }
    return items;
  }

  List<DropdownMenuItem<ItemPackageType>> _getItemPackageTypeItems() {
    List<DropdownMenuItem<ItemPackageType>> items = [];


    if ((_currentWorkOrder?.item?.itemPackageTypes.length ?? 0) > 0) {
      // _selectedItemPackageType = _currentWorkOrder.item.itemPackageTypes[0];

      for (int i = 0; i < _currentWorkOrder!.item!.itemPackageTypes.length; i++) {

        // printLongLogMessage("_currentWorkOrder.item.itemPackageTypes[i]: ${_currentWorkOrder.item.itemPackageTypes[i].toJson()}");
        items.add(DropdownMenuItem(
          value: _currentWorkOrder!.item!.itemPackageTypes[i],
          child: Text(_currentWorkOrder!.item!.itemPackageTypes[i]!.description ?? ""),
        ));
      }
      if (_currentWorkOrder!.item!.itemPackageTypes.length == 1 ||
          _selectedItemPackageType == null) {
        // if we only have one item package type for this item, then
        // default the selection to it
        // if the user has not select any item package type yet, then
        // default the value to the first option as well
        _selectedItemPackageType = _currentWorkOrder!.item!.itemPackageTypes[0];
      }
    }
    return items;
  }


  Future<void> _onWorkOrderProduceWithKPI(WorkOrder workOrder, int confirmedQuantity,
      String lpn) async {


    showLoading(context);

    WorkOrderProduceTransaction workOrderProduceTransaction =
        await generateWorkOrderProduceTransaction(
        _lpnController.text, _selectedInventoryStatus!,
        _selectedItemPackageType!, int.parse(_quantityController.text),
            _getReasonCodeForProducingInventory()!
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
      // default the quantity to 1
      _quantityController.text = "1";
    }
  }



  void _enterOnLPNController(int tryTime) async {
    // we may come here when the user scan / press
    // enter in the LPN controller. In either case, we will need to make sure
    // the lpn doesn't have focus before we start confirm

    if (tryTime <= 0) {
      // do nothing as we run out of try time

      setState(() {
        // enable the confirm button
        _readyToConfirm = true;
      });
      return;
    }

    if (lpnFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnLPNController(tryTime - 1));

      return;

    }
    // if we are here, then it means we already have the full LPN
    // due to how  flutter handle the input, we will get the enter
    // action listner handler fired before the input characters are
    // full assigned to the lpnController.

    // printLongLogMessage("lpn controller lost focus, its value is ${_lpnController.text}");
    if (_formKey.currentState!.validate()) {
        // set ready to confirm to fail so other trigger point
        // won't process the receiving request
        // the issue happens when we have 2 trigger point to process
        // the receiving request
        // 1. LPN blur
        // 2. confirm button click
        // so when we blur the LPN controller by clicking the confirm button, the
        // _onRecevingConfirm function will be fired twice
        _readyToConfirm = false;
        _onWorkOrderProduceConfirm();
    }


    setState(() {
      // enable the confirm button
      _readyToConfirm = true;
    });

  }

  void _onWorkOrderProduceConfirm() async {

    // the user start to confirm receiving from the work order
    // let's calculate the quantity first

    int inventoryQuantity = 0;

    if (_forceLPNReceiving) {

      // if we force the user to receiving by LPN, then default the
      // receiving quantity to one LPN UOM's quantity
      ItemUnitOfMeasure? lpnUOM = _getLPNUOM();
      if (lpnUOM == null) {

        showErrorDialog(context, "LPN UOM is not setup for the item. please specify the quantity");
        // reset ready to confirm flag so the operators can confirm the produce again
        _readyToConfirm = true;
        return;

      }
      inventoryQuantity = lpnUOM.quantity!;
    }
    else {
      inventoryQuantity = int.parse(_quantityController.text) * _selectedItemUnitOfMeasure!.quantity!;
    }

    // if the inventory status requires reason, then make sure the user input one
    if (_selectedInventoryStatus != null && _selectedInventoryStatus?.reasonRequiredWhenProducing == true &&
        _selectedReasonCode == null) {

      showErrorDialog(context, "Reason for the inventory " +
          ( _selectedInventoryStatus?.name ?? "") +
          " is required, please choose the reason!");
      // reset ready to confirm flag so the operators can confirm the produce again
      _readyToConfirm = true;
      return;

    }

    try {

      _confirmWorkOrderProduce(_currentWorkOrder!,
          inventoryQuantity,
          _lpnController.text);
    }
    finally {

      _lpnControllerFocusNode.requestFocus();
      // reset ready to confirm flag so the operators can confirm the produce again
      _readyToConfirm = true;
    }
  }
  void _confirmWorkOrderProduce(WorkOrder workOrder, int inventoryQuantity,
      String lpn ) async {

    if (lpn.isNotEmpty) {
      showLoading(context);
      // first of all, validate the LPN
      try {
        String errorMessage = await InventoryService.validateNewLpn(lpn);
        if (errorMessage.isNotEmpty) {
          Navigator.of(context).pop();
          showErrorDialog(context, errorMessage);

          return;
        }
      }
      on CWMSHttpException catch(ex) {

        Navigator.of(context).pop();
        showErrorDialog(context, "${ex.code} - ${ex.message}");
        return;

      }
      Navigator.of(context).pop();
    }



    int lpnCount = _getRequiredLPNCount(inventoryQuantity);

    // see if we are receiving single lpn or multiple lpn
    if (lpnCount == 1) {
      // if we haven't specify the UOM that we will need to track the LPN
      // or we are receiving at less than LPN uom level,
      // or we are receiving at LPN uom level but we only receive 1 LPN, then proceed with single LPN


      // before we will receive one LPN, we will verify if the quantity exceed
      // the LPN's standard quantity. If so, then we will warn the user to make sure
      // they don't accidentally input a wrong number
      bool validateLPNQuantity = await _validateQuantityForSingleLPN(inventoryQuantity);
      if (validateLPNQuantity) {
        _onWorkOrderProduceSingleLPNConfirm(workOrder, inventoryQuantity, lpn);
      }
      else {
        // quantity is not valid(normally it means we only need one LPN but the total
        // quantity exceed the standard LPN's quantity
        _readyToConfirm = true;
        return;
      }
    }
    else {
      _onWorkOrderProduceMiltipleLPNConfirm(workOrder, inventoryQuantity, lpn);
    }
  }

  Future<bool> _validateQuantityForSingleLPN(int inventoryQuantity) async {

    if (_selectedItemPackageType?.trackingLpnUOM == null) {
      // the tracking LPN UOM is not defined for this item package type
      // so no matter what's the quantity the user input, we will always
      // take it as PASS
      return true;
    }
    // if the quantity is greater than the lpn uom's quantity, warning
    // the user to make sure it is not a typo. Since we already define the LPN
    // uom, normally the quantity of the single LPN won't exceed the standard
    // lpn UOM's quantity
    if (inventoryQuantity > _selectedItemPackageType!.trackingLpnUOM!.quantity!) {
      // bool continueWithExceedQuantity = await showYesNoDialog(context, "lpn validation", "lpn quantity exceed the standard quantity, continue?");
      bool continueWithExceedQuantity = false;
      await showYesNoDialog(context, CWMSLocalizations.of(context)!.lpnQuantityExceedWarningTitle, CWMSLocalizations.of(context)!.lpnQuantityExceedWarningMessage,
            () => continueWithExceedQuantity = true,
            () => continueWithExceedQuantity = false,
      );

      return continueWithExceedQuantity;
    }
    // current quantity doesn't exceed the standard lpn quantity, good to go
    return true;
  }

  void _onWorkOrderProduceSingleLPNConfirm(WorkOrder workOrder, int inventoryQuantity,
      String lpn ) async {

    showLoading(context);

    // make sure the user input a valid LPN
    try {
      String errorMessage = await InventoryService.validateNewLpn(lpn);
      if (errorMessage.isNotEmpty) {
        Navigator.of(context).pop();
        showErrorDialog(context, errorMessage);
        _lpnControllerFocusNode.requestFocus();
        return;
      }

    }
    on CWMSHttpException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, "${ex.code} - ${ex.message}");
      _lpnControllerFocusNode.requestFocus();
      return;

    }

    WorkOrderProduceTransaction workOrderProduceTransaction =
        generateWorkOrderProduceTransaction(
            lpn, _selectedInventoryStatus!,
            _selectedItemPackageType!, inventoryQuantity,
            _getReasonCodeForProducingInventory()
        );


    try {
      await WorkOrderService.saveWorkOrderProduceTransaction(
          workOrderProduceTransaction
      );
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      _lpnControllerFocusNode.requestFocus();
      return;

    }

    if (Global.warehouseConfiguration.newLPNPrintLabelAtProducingFlag == true &&
        Global.warehouseConfiguration.printingStrategy == PrintingStrategy.LOCAL_PRINTER_SERVER_DATA) {
      // we will print the LPN label
      // we will download the LPN label as PDF and then print from the printer that attached to the RF
      _printLPNLabel(lpn);
    }

    Navigator.of(context).pop();
    _refreshScreenAfterProducing();


  }

  void _printLPNLabel(String lpn) {
    // get the default printer that attached to the RF


    if (Global.getLastLoginRF().printerName == "") {
      return ;
    }
    // download the LPN label
    InventoryService.autoPrintLPNLabelByLpn(context, lpn);

  }

  ReasonCode? _getReasonCodeForProducingInventory() {
    if (_selectedInventoryStatus != null && (
        _selectedInventoryStatus?.reasonRequiredWhenProducing == true ||
            _selectedInventoryStatus?.reasonOptionalWhenProducing == true
    )) {
      return _selectedReasonCode;
    }
    else {
      return null;
    }
  }

  _onWorkOrderProduceMiltipleLPNConfirm(WorkOrder workOrder, int inventoryQuantity,
      String lpn ) async {

    // let's see how many LPNs we will need
    int lpnCount = _getRequiredLPNCount(inventoryQuantity);


    if (lpnCount == 1) {


      // before we will receive one LPN, we will verify if the quantity exceed
      // the LPN's standard quantity. If so, then we will warn the user to make sure
      // they don't accidentally input a wrong number
      bool validateLPNQuantity = await _validateQuantityForSingleLPN(inventoryQuantity);
      if (validateLPNQuantity) {
        _onWorkOrderProduceSingleLPNConfirm(workOrder, inventoryQuantity, lpn);
      }
      else {
        // quantity is not valid(normally it means we only need one LPN but the total
        // quantity exceed the standard LPN's quantity
        _readyToConfirm = true;
        return;
      }

    }
    else if (lpnCount > 1) {
      // we will need multiple LPNs, let's prompt a dialog to capture the lpns

      Set<String> capturedLpn = new Set();
      // if the user already scna in a lpn, then add it
      if (lpn.isNotEmpty) {
        capturedLpn.add(lpn);
      }
      LpnCaptureRequest lpnCaptureRequest = new LpnCaptureRequest.withData(
          _currentWorkOrder!.item!,
          _selectedItemPackageType!,
          _selectedItemPackageType!.trackingLpnUOM!,
          lpnCount, capturedLpn,
          true
      );

      final result = await Navigator.of(context)
          .pushNamed("lpn_capture", arguments: lpnCaptureRequest);

      // printLongLogMessage("returned from the capture lpn form. result == null? : ${result == null}");
      if (result == null) {
        // the user press Return, let's do nothing

        return null;
      }

      lpnCaptureRequest = result as LpnCaptureRequest;

      if (lpnCaptureRequest.result == false) {
        // this happens when the user click 'cancel' button
        return null;
      }
      // receive with multiple LPNs
      _produceMultipleLpns(lpnCaptureRequest);
    }

  }


  void _produceMultipleLpns(LpnCaptureRequest lpnCaptureRequest) async {

    showLoading(context);
    // make sure the user input a valid LPN
    try {
      Iterator<String> lpnIterator = lpnCaptureRequest.capturedLpn.iterator;
      while(lpnIterator.moveNext()) {

        String errorMessage = await InventoryService.validateNewLpn(lpnIterator.current);
        if (errorMessage.isNotEmpty) {
          Navigator.of(context).pop();
          showErrorDialog(context, errorMessage);
          return;
        }
      }
    }
    on CWMSHttpException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, "${ex.code} - ${ex.message}");
      return;

    }
    try {
      // start receive LPNs one by one and show the progress bar
      _setupProgressBar();
      Iterator<String> lpnIterator = lpnCaptureRequest.capturedLpn.iterator;
      int totalLPNCount = lpnCaptureRequest.capturedLpn.length;
      int currentLPNIndex = 1;

      while(lpnIterator.moveNext()) {
        String lpn = lpnIterator.current;
        double progress = currentLPNIndex * 100 / totalLPNCount;
        String message = CWMSLocalizations.of(context)!.receivingCurrentLpn + ": " +
            lpn + ", " + currentLPNIndex.toString() + " / " + totalLPNCount.toString();

        _progressDialog!.update(progress: progress, message: message);

        WorkOrderProduceTransaction workOrderProduceTransaction =
            generateWorkOrderProduceTransaction(
                lpn, _selectedInventoryStatus!,
              _selectedItemPackageType!, lpnCaptureRequest!.lpnUnitOfMeasure!.quantity!,
                _getReasonCodeForProducingInventory()
          );

        await WorkOrderService.saveWorkOrderProduceTransaction(
            workOrderProduceTransaction
        );
        currentLPNIndex++;
      }

    }
    on CWMSHttpException catch(ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, "${ex.code} - ${ex.message}");
      return;

    }

    if (_progressDialog!.isShowing()) {
      _progressDialog!.hide();
    }

    Navigator.of(context).pop();

    _refreshScreenAfterProducing();

  }

  _setupProgressBar() {

    _progressDialog = new ProgressDialog(
      context,
      type: ProgressDialogType.normal,
      isDismissible: false,
      showLogs: true,
    );

    _progressDialog!.style(message: CWMSLocalizations.of(context)!.receivingMultipleLpns);
    if (!_progressDialog!.isShowing()) {
      _progressDialog!.show();
    }
  }
  _refreshScreenAfterProducing() {
    // refresh the work order to reflect the produced quantity
    _refreshWorkOrderInformation();
    showToast("inventory produced");
    // we will allow the user to continue receiving with the same
    // receipt and line
    _lpnController.clear();
    // default the quantity to 1
    _quantityController.text = "1";
    _lpnControllerFocusNode.requestFocus();
    // FocusScope.of(context).requestFocus(lpnFocusNode);

    _readyToConfirm = true;


  }


  // check how many LPNs we will need to receive
  // based on the quantity that the user input,
  // the UOM that the user select
  int _getRequiredLPNCount(int totalQuantity) {

    // if the user choose force LPN receiving, then
    // we will default to receive by 1 LPN uom
    if (_forceLPNReceiving) {
      return 1;
    }

    int lpnCount = 0;

    if (_selectedItemPackageType!.trackingLpnUOM == null) {
      // the tracking LPN UOM is not defined for this item package type, so we don't know
      // how to calculate how many LPNs we may need based on the UOM and quantity
      lpnCount = 1;
    }
    else if (_selectedItemUnitOfMeasure!.quantity! >= _selectedItemPackageType!.trackingLpnUOM!.quantity!) {
      // we are receiving at LPN uom level, then see what's the quantity the user specify
      lpnCount = totalQuantity ~/ _selectedItemPackageType!.trackingLpnUOM!.quantity!;
    }
    else {
      // we are receiving at some lower level than the tracking LPN UOM,
      // no matter how many we are receiving, we will only need one lpn, we will rely on
      // the user to input the right quantity that can be done in one single lpn
      lpnCount = 1;
    }
    return lpnCount;

  }

  _refreshWorkOrderInformation() {
    WorkOrderService.getWorkOrderByNumber(_currentWorkOrder!.number!)
        .then((workOrder)  { 

            setState(() {
              _currentWorkOrder!.producedQuantity = workOrder?.producedQuantity;
            });
        });


  }
  WorkOrderProduceTransaction generateWorkOrderProduceTransaction(
      String lpn, InventoryStatus selectedInventoryStatus,
      ItemPackageType selectedItemPackageType, int quantity, ReasonCode? reasonCode)   {
    WorkOrderProduceTransaction workOrderProduceTransaction = new WorkOrderProduceTransaction();
    workOrderProduceTransaction.workOrder = _currentWorkOrder;
    workOrderProduceTransaction.productionLine = _currentProductionLine;

    workOrderProduceTransaction.rfCode = Global.getLastLoginRFCode();

    workOrderProduceTransaction.workOrderKPITransactions = [];

    WorkOrderProducedInventory workOrderProducedInventory = new WorkOrderProducedInventory();
    workOrderProducedInventory.lpn = lpn;
    workOrderProducedInventory.quantity = quantity;
    workOrderProducedInventory.inventoryStatus = selectedInventoryStatus;
    workOrderProducedInventory.inventoryStatusId = selectedInventoryStatus.id;
    workOrderProducedInventory.itemPackageType = selectedItemPackageType;
    workOrderProducedInventory.itemPackageTypeId = selectedItemPackageType.id;
    List<WorkOrderProducedInventory> workOrderProducedInventoryList = [];
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
    workOrderProduceTransaction.workOrderLineConsumeTransactions =
        workOrderLineConsumeTransactions;

    if (reasonCode != null) {
      workOrderProduceTransaction.reasonCodeId = reasonCode.id;
      workOrderProduceTransaction.reasonCode = reasonCode;
    }
    else {
      workOrderProduceTransaction.reasonCodeId = null;
      workOrderProduceTransaction.reasonCode = null;

    }
    

    return workOrderProduceTransaction;
  }



}