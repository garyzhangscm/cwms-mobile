
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
import 'package:progress_dialog/progress_dialog.dart';


class WorkOrderProduceInventoryPage extends StatefulWidget{

  WorkOrderProduceInventoryPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _WorkOrderProduceInventoryPageState();

}

class _WorkOrderProduceInventoryPageState extends State<WorkOrderProduceInventoryPage> {

  // input batch id

  TextEditingController _quantityController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();

  WorkOrder _currentWorkOrder;
  ProductionLine _currentProductionLine;

  List<InventoryStatus> _validInventoryStatus;
  InventoryStatus _selectedInventoryStatus;
  ItemPackageType _selectedItemPackageType;
  ItemUnitOfMeasure _selectedItemUnitOfMeasure;
  ProgressDialog _progressDialog;

  BillOfMaterial _matchedBillOfMaterial;
  FocusNode lpnFocusNode = FocusNode();
  FocusNode quantityFocusNode = FocusNode();
  bool _readyToConfirm = true; // whether we can confirm the produced inventory



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
            if (_validInventoryStatus.length > 0) {
              _selectedInventoryStatus = _validInventoryStatus[0];
            }
          });
    });

    quantityFocusNode.requestFocus();
    // default quantity to 1
    _quantityController.text = "1";
  }
  final  _formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {

    Map arguments  = ModalRoute.of(context).settings.arguments as Map ;
    _currentWorkOrder = arguments['workOrder'];

    _currentProductionLine = arguments['productionLine'];

    _loadMatchedBillOfMaterial();
  }
  _loadMatchedBillOfMaterial() {
    if (_matchedBillOfMaterial != null) {
      return;
    }
    else if (_currentWorkOrder.consumeByBom != null) {
      _matchedBillOfMaterial = _currentWorkOrder.consumeByBom;
    }
    else {

      BillOfMaterialService.findMatchedBillOfMaterial(_currentWorkOrder).then((value) => _matchedBillOfMaterial = value);

    }

  }

  @override
  Widget build(BuildContext context) {



    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).workOrderProduce)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          //autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[

              buildTwoSectionInformationRowWithWidget(
                  CWMSLocalizations.of(context).workOrderNumber,
                  _getWorkOrderDisplayWidget(context, _currentWorkOrder)),
              buildTwoSectionInformationRowWithWidget(
                  CWMSLocalizations.of(context).item,
                  _getItemDisplayWidget(context, _currentWorkOrder.item)),
/**
              buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context).expectedQuantity,
                _currentWorkOrder.expectedQuantity.toString()),
              buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context).billOfMaterial,
                  _matchedBillOfMaterial == null ? "" : _matchedBillOfMaterial.number),
              // show the matched BOM
              buildTwoSectionInformationRow(
                  CWMSLocalizations.of(context).producedQuantity,
                  _currentWorkOrder.producedQuantity.toString()),
    **/
              // Allow the user to choose item package type
              buildTwoSectionInputRow(
                  CWMSLocalizations.of(context).itemPackageType,

                  DropdownButton(
                    hint: Text(CWMSLocalizations.of(context).pleaseSelect),
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
              ),
              // Allow the user to choose inventory status
              buildTwoSectionInputRow(
                  CWMSLocalizations.of(context).inventoryStatus,
                  DropdownButton(
                    hint: Text(CWMSLocalizations.of(context).pleaseSelect),
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
              ),
              /***
               *
                  buildTwoSectionInputRow(
                  CWMSLocalizations.of(context).producingQuantity,
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
              buildThreeSectionInputRow(
                CWMSLocalizations.of(context).producingQuantity,
                TextFormField(
                      keyboardType: TextInputType.number,
                      controller: _quantityController,
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                      focusNode: quantityFocusNode,
                      onFieldSubmitted: (v){
                        printLongLogMessage("start to focus on lpn node");
                        lpnFocusNode.requestFocus();

                      },
                      decoration: InputDecoration(
                          isDense: true
                      ),
                      // 校验ITEM NUMBER（不能为空）
                      validator: (v) {
                        if (v.trim().isEmpty) {
                          return "please type in quantity";
                        }
                        return null;
                      }),
                _getItemUnitOfMeasures().isEmpty ?
                  Container() :
                  DropdownButton(
                    hint: Text(CWMSLocalizations.of(context).pleaseSelect),
                    items: _getItemUnitOfMeasures(),
                    value: _selectedItemUnitOfMeasure,
                    elevation: 16,
                    icon: const Icon(Icons.arrow_downward),
                    underline: Container(
                      height: 2,
                      color: Colors.deepPurpleAccent,
                    ),
                    onChanged: (T) {
                      //下拉菜单item点击之后的回调
                      setState(() {
                        _selectedItemUnitOfMeasure = T;
                      });
                    },
                  )


              ),
              buildTwoSectionInputRow(
                CWMSLocalizations.of(context).lpn,
                Focus(
                    child:
                    RawKeyboardListener(
                      focusNode: lpnFocusNode,
                      onKey: (event) {

                        // printLongLogMessage("user pressed : ${event.logicalKey}");
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
                            readOnly: false,
                            showKeyboard: false,
                            validator: (v) {
                              if (v.trim().isEmpty && _getRequiredLPNCount(int.parse(_quantityController.text)) == 1) {
                                return CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).lpn);
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
        onPressed: () {
          printLongLogMessage("confirm button click!");
          print("1. _formKey.currentState.validate()? ${_formKey.currentState.validate()}");
          if (_formKey.currentState.validate()) {

            print("1. _readyToConfirm? $_readyToConfirm");
            if (_readyToConfirm == true) {
              _readyToConfirm = false;
              print("1. form validation passed");
              print("1. set _readyToConfirm to false");
              _onWorkOrderProduceConfirm(_currentWorkOrder,
                  int.parse(_quantityController.text),
                  _lpnController.text);
            }
          }

        },
        child: Text(CWMSLocalizations
            .of(context)
            .confirm),
      )
    );

  }

  List<DropdownMenuItem> _getItemUnitOfMeasures() {
    List<DropdownMenuItem> items = [];

    if ( _selectedItemPackageType == null || _selectedItemPackageType.itemUnitOfMeasures == null ||
        _selectedItemPackageType.itemUnitOfMeasures.length == 0) {
      // if the user has not selected any item package type yet
      // return nothing
      return items;
    }

    for (int i = 0; i < _selectedItemPackageType.itemUnitOfMeasures.length; i++) {

      items.add(DropdownMenuItem(
        value:  _selectedItemPackageType.itemUnitOfMeasures[i],
        child: Text( _selectedItemPackageType.itemUnitOfMeasures[i].unitOfMeasure.name),
      ));
    }

    // we may have _selectedItemUnitOfMeasure setup by previous item package type.
    // or manually by user. If it is setup by the user, then we won't refresh it
    // otherwise, we will reload the default receiving uom
    // if _selectedItemPackageType.itemUnitOfMeasures doesn't containers the _selectedItemUnitOfMeasure
    // then we know that we just changed the item package type or item, so we will need
    // to refresh the _selectedItemUnitOfMeasure to the default inbound receiving uom as well
    if (_selectedItemUnitOfMeasure == null ||
        !_selectedItemPackageType.itemUnitOfMeasures.any((element) => element.hashCode == _selectedItemUnitOfMeasure.hashCode)) {
      // if the user has not select any item unit of measure yet, then
      // default the value to the one marked as 'default for inbound receiving'

      // printLongLogMessage("_currentWorkOrder.item: ${_currentWorkOrder.item.toJson()}");
      // printLongLogMessage("_selectedItemPackageType: ${_selectedItemPackageType.toJson()}");
      _selectedItemUnitOfMeasure = _selectedItemPackageType.itemUnitOfMeasures
          .firstWhere((element) => element.id == _selectedItemPackageType.defaultWorkOrderReceivingUOM.id);
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
                        context, item.name, Column(
                          children: <Widget>[
                            buildTwoSectionInformationRow(
                                CWMSLocalizations.of(context).item,
                                _currentWorkOrder.item.name),
                            buildTwoSectionInformationRow(
                                CWMSLocalizations.of(context).item,
                                _currentWorkOrder.item.description),

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
                  context, workOrder.number, Column(
                  children: <Widget>[

                    buildTwoSectionInformationRow(
                        CWMSLocalizations.of(context).expectedQuantity,
                        workOrder.expectedQuantity.toString()),
                    buildTwoSectionInformationRow(
                        CWMSLocalizations.of(context).billOfMaterial,
                        _matchedBillOfMaterial == null ? "" : _matchedBillOfMaterial.number),
                    // show the matched BOM
                    buildTwoSectionInformationRow(
                        CWMSLocalizations.of(context).producedQuantity,
                        workOrder.producedQuantity.toString()),

                  ]),

                  verticalPadding: 175.0,
                  horizontalPadding: 50.0
              );
            },
        ));

  }




  List<DropdownMenuItem> _getInventoryStatusItems() {
    List<DropdownMenuItem> items = [];
    if (_validInventoryStatus == null || _validInventoryStatus.length == 0) {
      return items;
    }

    // _selectedInventoryStatus = _validInventoryStatus[0];
    for (int i = 0; i < _validInventoryStatus.length; i++) {
      items.add(DropdownMenuItem(
        value: _validInventoryStatus[i],
        child: Text(_validInventoryStatus[i].description),
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

  List<DropdownMenuItem> _getItemPackageTypeItems() {
    List<DropdownMenuItem> items = [];


    if (_currentWorkOrder.item.itemPackageTypes.length > 0) {
      // _selectedItemPackageType = _currentWorkOrder.item.itemPackageTypes[0];

      for (int i = 0; i < _currentWorkOrder.item.itemPackageTypes.length; i++) {

        // printLongLogMessage("_currentWorkOrder.item.itemPackageTypes[i]: ${_currentWorkOrder.item.itemPackageTypes[i].toJson()}");
        items.add(DropdownMenuItem(
          value: _currentWorkOrder.item.itemPackageTypes[i],
          child: Text(_currentWorkOrder.item.itemPackageTypes[i].description),
        ));
      }
      if (_currentWorkOrder.item.itemPackageTypes.length == 1 ||
          _selectedItemPackageType == null) {
        // if we only have one item package type for this item, then
        // default the selection to it
        // if the user has not select any item package type yet, then
        // default the value to the first option as well
        _selectedItemPackageType = _currentWorkOrder.item.itemPackageTypes[0];
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
      // default the quantity to 1
      _quantityController.text = "1";
    }
  }



  void _enterOnLPNController(int tryTime) async {
    // we may come here when the user scan / press
    // enter in the LPN controller. In either case, we will need to make sure
    // the lpn doesn't have focus before we start confirm

    // printLongLogMessage("Start to confirm work order produced inventory, tryTime = $tryTime}");
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
    if (_formKey.currentState.validate()) {
      printLongLogMessage("2. form passed validation");
      printLongLogMessage("2. _readyToConfirm? $_readyToConfirm");
      if (_readyToConfirm == true) {
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
        _onWorkOrderProduceConfirm(_currentWorkOrder,
            int.parse(_quantityController.text),
            _lpnController.text);
      }
    }


    setState(() {
      // enable the confirm button
      _readyToConfirm = true;
    });

  }

  void _onWorkOrderProduceConfirm(WorkOrder workOrder, int confirmedQuantity,
      String lpn ) async {

    if (lpn.isNotEmpty) {
      showLoading(context);
      // first of all, validate the LPN
      try {
        bool validLpn = await InventoryService.validateNewLpn(lpn);
        if (!validLpn) {
          Navigator.of(context).pop();
          showErrorDialog(context, "LPN is not valid, please make sure it follow the right format");
          return;
        }
        printLongLogMessage("LPN ${lpn} passed the validation");
      }
      on CWMSHttpException catch(ex) {

        Navigator.of(context).pop();
        showErrorDialog(context, "${ex.code} - ${ex.message}");
        return;

      }
      Navigator.of(context).pop();
    }

    int lpnCount = _getRequiredLPNCount(confirmedQuantity);

    // see if we are receiving single lpn or multiple lpn
    if (lpnCount == 1) {
      // if we haven't specify the UOM that we will need to track the LPN
      // or we are receiving at less than LPN uom level,
      // or we are receiving at LPN uom level but we only receive 1 LPN, then proceed with single LPN


      // before we will receive one LPN, we will verify if the quantity exceed
      // the LPN's standard quantity. If so, then we will warn the user to make sure
      // they don't accidentally input a wrong number
      bool validateLPNQuantity = await _validateQuantityForSingleLPN(confirmedQuantity);
      if (validateLPNQuantity) {
        _onWorkOrderProduceSingleLPNConfirm(workOrder, confirmedQuantity, lpn);
      }
      else {
        // quantity is not valid(normally it means we only need one LPN but the total
        // quantity exceed the standard LPN's quantity
        _readyToConfirm = true;
        return;
      }
    }
    else {
      _onWorkOrderProduceMiltipleLPNConfirm(workOrder, confirmedQuantity, lpn);
    }
  }

  Future<bool> _validateQuantityForSingleLPN(int confirmedQuantity) async {

    if (_selectedItemPackageType.trackingLpnUOM == null) {
      // the tracking LPN UOM is not defined for this item package type
      // so no matter what's the quantity the user input, we will always
      // take it as PASS
      return true;
    }
    // if the quantity is greater than the lpn uom's quantity, warning
    // the user to make sure it is not a typo. Since we already define the LPN
    // uom, normally the quantity of the single LPN won't exceed the standard
    // lpn UOM's quantity
    if (confirmedQuantity > _selectedItemPackageType.trackingLpnUOM.quantity) {
      // bool continueWithExceedQuantity = await showYesNoDialog(context, "lpn validation", "lpn quantity exceed the standard quantity, continue?");
      bool continueWithExceedQuantity = false;
      await showYesNoDialog(context, CWMSLocalizations.of(context).lpnQuantityExceedWarningTitle, CWMSLocalizations.of(context).lpnQuantityExceedWarningMessage,
            () => continueWithExceedQuantity = true,
            () => continueWithExceedQuantity = false,
      );
      printLongLogMessage("continueWithExceedQuantity: $continueWithExceedQuantity");

      return continueWithExceedQuantity;
    }
    // current quantity doesn't exceed the standard lpn quantity, good to go
    return true;
  }

  void _onWorkOrderProduceSingleLPNConfirm(WorkOrder workOrder, int confirmedQuantity,
      String lpn ) async {

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
    on CWMSHttpException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, "${ex.code} - ${ex.message}");
      return;

    }

    printLongLogMessage("Start to prepare the work order produce transaction");

    WorkOrderProduceTransaction workOrderProduceTransaction =
        generateWorkOrderProduceTransaction(
            _lpnController.text, _selectedInventoryStatus,
            _selectedItemPackageType, confirmedQuantity * _selectedItemUnitOfMeasure.quantity
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
   //  printLongLogMessage("start to print lpn label: $lpn, findPrinterBy: ${workOrderProduceTransaction.productionLine.name}");
    // InventoryService.printLPNLabel(lpn, workOrderProduceTransaction.productionLine.name);

    Navigator.of(context).pop();
    _refreshScreenAfterProducing();


  }

  _onWorkOrderProduceMiltipleLPNConfirm(WorkOrder workOrder, int confirmedQuantity,
      String lpn ) async {

    // let's see how many LPNs we will need
    int lpnCount = _getRequiredLPNCount(confirmedQuantity);

    printLongLogMessage("we will need to produce $lpnCount LPNs");
    if (lpnCount == 1) {


      // before we will receive one LPN, we will verify if the quantity exceed
      // the LPN's standard quantity. If so, then we will warn the user to make sure
      // they don't accidentally input a wrong number
      bool validateLPNQuantity = await _validateQuantityForSingleLPN(confirmedQuantity);
      if (validateLPNQuantity) {
        _onWorkOrderProduceSingleLPNConfirm(workOrder, confirmedQuantity, lpn);
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
        printLongLogMessage("add current LPN $lpn first so that the user don't have to scan in again");
      }
      LpnCaptureRequest lpnCaptureRequest = new LpnCaptureRequest.withData(
          _currentWorkOrder.item,
          _selectedItemPackageType,
          _selectedItemPackageType.trackingLpnUOM,
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

        bool validLpn = await InventoryService.validateNewLpn(lpnIterator.current);
        if (!validLpn) {
          Navigator.of(context).pop();
          showErrorDialog(context, "LPN is not valid, please make sure it follow the right format");
          return;
        }
        printLongLogMessage("LPN ${lpnIterator.current} passed the validation");
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
        String message = CWMSLocalizations.of(context).receivingCurrentLpn + ": " +
            lpn + ", " + currentLPNIndex.toString() + " / " + totalLPNCount.toString();

        _progressDialog.update(progress: progress, message: message);

        WorkOrderProduceTransaction workOrderProduceTransaction =
            generateWorkOrderProduceTransaction(
                lpn, _selectedInventoryStatus,
              _selectedItemPackageType, lpnCaptureRequest.lpnUnitOfMeasure.quantity
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

    if (_progressDialog.isShowing()) {
      _progressDialog.hide();
    }

    Navigator.of(context).pop();

    _refreshScreenAfterProducing();

  }

  _setupProgressBar() {

    _progressDialog = new ProgressDialog(
      context,
      type: ProgressDialogType.Normal,
      isDismissible: false,
      showLogs: true,
    );

    _progressDialog.style(message: CWMSLocalizations.of(context).receivingMultipleLpns);
    if (!_progressDialog.isShowing()) {
      _progressDialog.show();
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
    lpnFocusNode.requestFocus();

    _readyToConfirm = true;

  }


  // check how many LPNs we will need to receive
  // based on the quantity that the user input,
  // the UOM that the user select
  int _getRequiredLPNCount(int totalQuantity) {

    printLongLogMessage("start to get required lpn quantity with total quantity $totalQuantity");
    int lpnCount = 0;

    if (_selectedItemPackageType.trackingLpnUOM == null) {
      // the tracking LPN UOM is not defined for this item package type, so we don't know
      // how to calculate how many LPNs we may need based on the UOM and quantity
      lpnCount = 1;
    }
    else if (_selectedItemUnitOfMeasure.quantity == _selectedItemPackageType.trackingLpnUOM.quantity) {
      // we are receiving at LPN uom level, then see what's the quantity the user specify
      lpnCount = totalQuantity;
    }
    else if (_selectedItemUnitOfMeasure.quantity > _selectedItemPackageType.trackingLpnUOM.quantity) {
      // we are receiving at some higher level, see how many LPN uom we will need
      lpnCount = (totalQuantity * _selectedItemUnitOfMeasure.quantity / _selectedItemPackageType.trackingLpnUOM.quantity) as int;
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
    WorkOrderService.getWorkOrderByNumber(_currentWorkOrder.number)
        .then((workOrder)  { 

            setState(() {
              _currentWorkOrder.producedQuantity = workOrder.producedQuantity;
            });
        });


  }
  WorkOrderProduceTransaction generateWorkOrderProduceTransaction(
      String lpn, InventoryStatus selectedInventoryStatus,
      ItemPackageType selectedItemPackageType, int quantity)   {
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