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
import 'package:cwms_mobile/inventory/models/item_unit_of_measure.dart';
import 'package:cwms_mobile/inventory/models/lpn_capture_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/models/cwms_http_exception.dart';
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:progress_dialog/progress_dialog.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


class ReceivingPage extends StatefulWidget{

  ReceivingPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _ReceivingPageState();

}

class _ReceivingPageState extends State<ReceivingPage> {

  // input batch id
  TextEditingController _receiptNumberController = new TextEditingController();
  TextEditingController _itemController = new TextEditingController();
  TextEditingController _quantityController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();

  Receipt _currentReceipt;
  ReceiptLine _currentReceiptLine;

  List<InventoryStatus> _validInventoryStatus;
  InventoryStatus _selectedInventoryStatus;
  ItemPackageType _selectedItemPackageType;
  ItemUnitOfMeasure _selectedItemUnitOfMeasure;

  List<Inventory>  inventoryOnRF;
  FocusNode _receiptNumberFocusNode = FocusNode();
  FocusNode _itemFocusNode = FocusNode();
  FocusNode _quantityFocusNode = FocusNode();
  FocusNode _lpnFocusNode = FocusNode();
  bool _readyToConfirm = true; // whether we can confirm the received inventory

  ProgressDialog pr;

  @override
  void initState() {
    super.initState();
    _currentReceipt = new Receipt();
    _currentReceiptLine = new ReceiptLine();
    _selectedInventoryStatus = new InventoryStatus();
    _selectedItemPackageType = new ItemPackageType();



    InventoryStatusService.getAllInventoryStatus()
        .then((value) {
      _validInventoryStatus = value;
      if (_validInventoryStatus.length > 0) {
        _selectedInventoryStatus = _validInventoryStatus[0];
      }
    });
    // setup the default inventory status


    inventoryOnRF = new List<Inventory>();

    _receiptNumberFocusNode.addListener(() {
      print("_receiptFocusNode.hasFocus: ${_receiptNumberFocusNode.hasFocus}");
      if (!_receiptNumberFocusNode.hasFocus && _receiptNumberController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _loadReceipt(_receiptNumberController.text);
        // _itemFocusNode.requestFocus();

      }
    });
    _receiptNumberFocusNode.requestFocus();

    _itemFocusNode.addListener(() {
      print("_itemFocusNode.hasFocus: ${_itemFocusNode.hasFocus}");
      if (!_itemFocusNode.hasFocus && _itemController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _loadReceiptLine(_itemController.text);
        // _quantityFocusNode.requestFocus();

      }
    });

    _lpnFocusNode.addListener(() {
      print("_lpnFocusNode.hasFocus: ${_lpnFocusNode.hasFocus}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _enterOnLPNController();
      }
    });


    _reloadInventoryOnRF();
  }
  final  _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).receiving)),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Form(
          key: _formKey,
          // autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[

              buildTwoSectionInputRow(
                CWMSLocalizations.of(context).receiptNumber,
                TextFormField(

                    controller: _receiptNumberController,
                    autofocus: true,
                    focusNode: _receiptNumberFocusNode,
                    textInputAction: TextInputAction.next,
                    onEditingComplete: () => _itemFocusNode.requestFocus(),
                    decoration: InputDecoration(
                      isDense: true,
                      suffixIcon:
                        IconButton(
                          onPressed: _showChoosingReceiptDialog,
                          icon: Icon(Icons.list),
                        ),

                    ),
                    // 校验ITEM NUMBER（不能为空）
                    validator: (v) {
                      if (v.trim().isEmpty) {
                        return "please scan in receipt";
                      }
                      return null;
                    }),
              ),

              buildTwoSectionInputRow(
                CWMSLocalizations.of(context).item,
                TextFormField(
                    controller: _itemController,
                    textInputAction: TextInputAction.next,
                    focusNode: _itemFocusNode,
                    autofocus: true,
                    onEditingComplete: () => _quantityFocusNode.requestFocus(),
                    decoration: InputDecoration(
                        isDense: true,
                        suffixIcon:
                            IconButton(
                              onPressed: _showChoosingItemsDialog,
                              icon: Icon(Icons.list),
                          ),
                    ),
                    // 校验ITEM NUMBER（不能为空）
                    validator: (v) {

                      if (v.trim().isEmpty) {
                        return "please scan in item";
                      }
                      return null;
                    }),
              ),
              // display the item
              buildTwoSectionInformationRow(
                CWMSLocalizations.of(context).item,
                _currentReceiptLine.item == null ?
                    "" : _currentReceiptLine.item.description,
              ),
              buildFourSectionInformationRow(
                  CWMSLocalizations.of(context).expectedQuantity,
                  _currentReceiptLine.expectedQuantity.toString(),
                  CWMSLocalizations.of(context).receivedQuantity,
                 _currentReceiptLine.receivedQuantity.toString()),

              // Allow the user to choose item package type

              buildTwoSectionInputRow(
                CWMSLocalizations.of(context).itemPackageType,

                  _getItemPackageTypeItems().isEmpty ?
                      Container() :
                      DropdownButton(
                          // hint: Text(CWMSLocalizations.of(context).pleaseSelect),
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
                   //  hint: Text(CWMSLocalizations.of(context).pleaseSelect),
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
              buildThreeSectionInputRow(
                  "RCV Quantity:",
                  TextFormField(
                      keyboardType: TextInputType.number,
                      controller: _quantityController,
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                      focusNode: _quantityFocusNode,
                      onFieldSubmitted: (v){
                        printLongLogMessage("start to focus on lpn node");
                        _lpnFocusNode.requestFocus();

                      },
                      decoration: InputDecoration(
                          isDense: true
                      ),
                      // 校验ITEM NUMBER（不能为空）
                      validator: (v) {
                        if (v.trim().isEmpty) {
                          return "please type in quantity";
                        }
                        if (!_validateOverReceiving(
                            _currentReceiptLine, int.parse(_quantityController.text))) {

                          return "over receive is not allowed";
                        }
                        return null;
                      }),
                  _getItemUnitOfMeasures().isEmpty ?
                      Container() :
                      DropdownButton(
                        hint: Text(CWMSLocalizations.of(context).pleaseSelect),
                        items: _getItemUnitOfMeasures(),
                        value: _selectedItemUnitOfMeasure,
                        elevation: 1,
                        isExpanded: true,
                        icon: Icon(
                          Icons.list,
                          size: 20,
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
                  CWMSLocalizations.of(context).lpn+ ": ",
                  Focus(
                    child:
                        SystemControllerNumberTextBox(
                          type: "lpn",
                          controller: _lpnController,
                          readOnly: false,
                          showKeyboard: false,
                          focusNode: _lpnFocusNode,
                          autofocus: true,
                          validator: (v) {
                            // if we only need one LPN, then make sure the user input the LPN in this form.
                            // otherwise, we will flow to next LPN Capture form to let the user capture
                            // more LPNs
                            if (v.trim().isEmpty && _getRequiredLPNCount(int.parse(_quantityController.text)) == 1) {
                              return CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).lpn);
                            }

                            return null;
                        }),
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
    return buildTwoButtonRow(
      context,
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState.validate()) {

            print("1. _readyToConfirm? $_readyToConfirm");
            if (_readyToConfirm == true) {
              _readyToConfirm = false;
              print("1. form validation passed");
              print("1. set _readyToConfirm to false");
              _onRecevingConfirm(_currentReceiptLine,
                  int.parse(_quantityController.text),
                  _lpnController.text);
            }
          }

        },
        child: Text(CWMSLocalizations
            .of(context)
            .confirm),
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
    );

  }

  // call the deposit form to deposit the inventory on the RF
  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the inventory on the RF
    _reloadInventoryOnRF();
  }

  bool _validateOverReceiving(ReceiptLine receiptLine,
      int receivingQuantity) {
    double openQuantity = (receiptLine.expectedQuantity - receiptLine.receivedQuantity) * 1.0;
    if (receiptLine.overReceivingQuantity > 0) {
      openQuantity += receiptLine.overReceivingQuantity;
    }
    else if (receiptLine.overReceivingPercent > 0) {
      openQuantity = openQuantity +
          receiptLine.expectedQuantity * (100 + receiptLine.overReceivingPercent) / 100;
    }
    return openQuantity >= receivingQuantity;
  }

  List<DropdownMenuItem> _getInventoryStatusItems() {
    List<DropdownMenuItem> items = [];
    if (_validInventoryStatus == null || _validInventoryStatus.length == 0) {
      return items;
    }
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


    if (_currentReceiptLine.item.itemPackageTypes.length > 0) {
      // _selectedItemPackageType = _currentReceiptLine.item.itemPackageTypes[0];

      for (int i = 0; i < _currentReceiptLine.item.itemPackageTypes.length; i++) {

        items.add(DropdownMenuItem(
          value: _currentReceiptLine.item.itemPackageTypes[i],
          child: Text(_currentReceiptLine.item.itemPackageTypes[i].description),
        ));
      }


      if (_currentReceiptLine.item.itemPackageTypes.length == 1 ||
          _selectedItemPackageType == null) {
        // if we only have one item package type for this item, then
        // default the selection to it
        // if the user has not select any item package type yet, then
        // default the value to the first option as well
        setState(() {
          _selectedItemPackageType = _currentReceiptLine.item.itemPackageTypes[0];

        });
      }
    }

    return items;
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

        _selectedItemUnitOfMeasure = _selectedItemPackageType.itemUnitOfMeasures
            .firstWhere((element) => element.id == _selectedItemPackageType.defaultInboundReceivingUOM.id);
    }

    return items;
  }

  void _onRecevingConfirm(ReceiptLine receiptLine, int confirmedQuantity,
                String lpn) async {

    if (_getItemPackageTypeItems().isEmpty) {
      showErrorToast(

        CWMSLocalizations.of(context).itemNotReceivableNoPackageType,
      );
      _readyToConfirm = true;
      return;
    }

    int lpnCount = _getRequiredLPNCount(confirmedQuantity);

    printLongLogMessage("1. lpn count: $lpnCount");

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
        _onRecevingSingleLpnConfirm(receiptLine, confirmedQuantity, lpn);
      }
      else {
        // quantity is not valid(normally it means we only need one LPN but the total
        // quantity exceed the standard LPN's quantity
        _readyToConfirm = true;
        return;
      }
    }
    else {
      printLongLogMessage("start to receive multiple LPNs in one transaction");
      _onRecevingMultiLpnConfirm(receiptLine, confirmedQuantity, lpn);
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

  void _onRecevingSingleLpnConfirm(ReceiptLine receiptLine, int confirmedQuantity,
        String lpn) async {
    // TO-DO:Current we don't support the location code. Will add
    //      it later

    bool qcRequired = false;

    printLongLogMessage("1. _onRecevingSingleLpnConfirm / showLoading");
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
    try {
      Inventory inventory = await ReceiptService.receiveInventory(
          _currentReceipt, _currentReceiptLine,
          _lpnController.text, _selectedInventoryStatus,
          _selectedItemPackageType, int.parse(_quantityController.text) * _selectedItemUnitOfMeasure.quantity
      );
      qcRequired = inventory.inboundQCRequired;
      printLongLogMessage("inventory ${inventory.lpn} received and need QC? ${inventory.inboundQCRequired}");
      if (qcRequired) {
        // for any inventory that needs qc, let's allocate the location automatically
        // for the inventory

        printLongLogMessage("allocate location for the QC needed inventory ${inventory.lpn}");
        InventoryService.allocateLocation(inventory);
      }

    }
    on WebAPICallException catch(ex) {


      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

    _refreshScreenAfterReceive(qcRequired);

  }

  // check how many LPNs we will need to receive
  // based on the quantity that the user input,
  // the UOM that the user select
  int _getRequiredLPNCount(int totalQuantity) {

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
    else{
      // we are receiving at some lower level than the tracking LPN UOM,
      // no matter how many we are receiving, we will only need one lpn, we will rely on
      // the user to input the right quantity that can be done in one single lpn

      // before we will receive one LPN, we will verify if the quantity exceed
      // the LPN's standard quantity. If so, then we will warn the user to make sure
      // they don't accidentally input a wrong number
      lpnCount = 1;
    }
    return lpnCount;

  }

  void _onRecevingMultiLpnConfirm(ReceiptLine receiptLine, int confirmedQuantity,
      String lpn) async {

    // let's see how many LPNs we will need
    int lpnCount = _getRequiredLPNCount(confirmedQuantity);

    printLongLogMessage("we will need to receive $lpnCount LPNs");
    if (lpnCount == 1) {
      // we will only need one LPN, let's just proceed with the current LPN

      // before we will receive one LPN, we will verify if the quantity exceed
      // the LPN's standard quantity. If so, then we will warn the user to make sure
      // they don't accidentally input a wrong number
      bool validateLPNQuantity = await _validateQuantityForSingleLPN(confirmedQuantity);
      if (validateLPNQuantity) {
        _onRecevingSingleLpnConfirm(receiptLine, confirmedQuantity, lpn);
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
          receiptLine.item,
          _selectedItemPackageType,
          _selectedItemPackageType.trackingLpnUOM,
          lpnCount, capturedLpn,
        true
      );

      printLongLogMessage("flow to lpn_capture screen");
      final result = await Navigator.of(context)
          .pushNamed("lpn_capture", arguments: lpnCaptureRequest);

      printLongLogMessage("returned from the capture lpn form");
      if (result == null) {
        // the user press Return, let's do nothing

        return null;
      }

      lpnCaptureRequest = result as LpnCaptureRequest;
      printLongLogMessage("start to receive lpns with request");
      printLongLogMessage(lpnCaptureRequest.toJson().toString());

      // receive with multiple LPNs
      _receiveMultipleLpns(receiptLine, lpnCaptureRequest);
    }

  }

  void _receiveMultipleLpns(ReceiptLine receiptLine, LpnCaptureRequest lpnCaptureRequest) async {

    bool qcRequired = false;

    printLongLogMessage("2. _receiveMultipleLpns / showLoading");
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

        pr.update(progress: progress, message: message);
        Inventory inventory = await ReceiptService.receiveInventory(
            _currentReceipt, _currentReceiptLine,
            lpn, _selectedInventoryStatus,
            _selectedItemPackageType, lpnCaptureRequest.lpnUnitOfMeasure.quantity
        );
        if (inventory.inboundQCRequired == true) {
          // for any inventory that needs qc, let's allocate the location automatically
          // for the inventory

          printLongLogMessage("allocate location for the QC needed inventory ${inventory.lpn}");
          InventoryService.allocateLocation(inventory);
          qcRequired = true;
        }


        currentLPNIndex++;
      }

    }
    on WebAPICallException catch(ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

    if (pr.isShowing()) {
      pr.hide();
    }
    _refreshScreenAfterReceive(qcRequired);

  }

  _setupProgressBar() {

    pr = new ProgressDialog(
      context,
      type: ProgressDialogType.Normal,
      isDismissible: false,
      showLogs: true,
    );

    pr.style(message: CWMSLocalizations.of(context).receivingMultipleLpns);
    if (!pr.isShowing()) {
      pr.show();
    }
  }
  _refreshScreenAfterReceive(bool qcRequired) {
    print("inventory received!");

    Navigator.of(context).pop();

    if (qcRequired == true) {
       showWarningDialog(context, CWMSLocalizations.of(context).inventoryNeedQC);
    }
    showToast("inventory received");
    // we will allow the user to continue receiving with the same
    // receipt and line
    _lpnController.clear();
    _quantityController.clear();
    _quantityFocusNode.requestFocus();


    // refresh the inventory on the RF
    _reloadInventoryOnRF();

    _readyToConfirm = true;

  }


  _startItemBarcodeScanner()  async {
    /*
    *
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print("barcode scanned: $barcodeScanRes");
    _receiptNumberController.text = barcodeScanRes;
    _loadReceipt(_receiptNumberController.text);
    * */

  }
  _loadReceipt(String receiptNumber) {
    if (receiptNumber.isEmpty) {
      return;
    }
    ReceiptService.getReceiptByNumber(receiptNumber)
        .then((receipt) {
           setState(() {
             _currentReceipt = receipt;
          });
    });
  }
  _startReceiptBarcodeScanner() async {
    /*
    *
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print("barcode scanned: $barcodeScanRes");
    _itemController.text = barcodeScanRes;
    _loadReceiptLine(_itemController.text);
    * */
  }

  _loadReceiptLine(String itemNumber) {
    // we can only load the line from current receipt
    // based on the item being scanned
    if (_currentReceipt.receiptLines.isEmpty ||
        itemNumber.isEmpty) {
      return ;
    }

    setState(() {
      _currentReceiptLine =  _currentReceipt.receiptLines.firstWhere(
              (receiptLine) => receiptLine.item.name == itemNumber);
    });


  }

  // show all open receipt that can be received
  _showChoosingReceiptDialog() async {

    showLoading(context);
    List<Receipt> openReceiptForReceiving =
        await ReceiptService.getOpenReceipts();

    // Setup the total quantity for each receipt. We
    // will display the total quantity to assist the user
    // to choose the right receipt to start with
    _setupTotalQuantity(openReceiptForReceiving);

    // 隐藏loading框
    Navigator.of(context).pop();
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        var child = Column(
          children: <Widget>[
            Row(
              children: [
                ElevatedButton(
                  child: Text(CWMSLocalizations
                      .of(context)
                      .cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            ListTile(title: Text(CWMSLocalizations
                .of(context)
                .chooseReceipt)),
            _buildOpenReceiptList(context, openReceiptForReceiving)
          ],
        );
        //使用AlertDialog会报错
        //return AlertDialog(content: child);
        return Dialog(child: child);
      },
    );

  }

  void _setupTotalQuantity(List<Receipt> receipts) {
    receipts.forEach((receipt) {
      _setupTotalQuantityForReceipt(receipt);
    });

  }
  void _setupTotalQuantityForReceipt(Receipt receipt) {
    int totalExpectedQuantity = 0;
    int totalReceivedQuantity = 0;
    receipt.receiptLines.forEach((receiptLine) {
      totalExpectedQuantity += receiptLine.expectedQuantity;
      totalReceivedQuantity += receiptLine.receivedQuantity;
    });
    receipt.totalReceivedQuantity = totalReceivedQuantity;
    receipt.totalExpectedQuantity = totalExpectedQuantity;
    


  }

  Widget _buildOpenReceiptList(BuildContext context,
      List<Receipt> openReceiptForReceiving) {
    return
      Expanded(
        child: ListView.builder(
            itemCount: openReceiptForReceiving.length,
            itemBuilder: (BuildContext context, int index) {

              return ReceiptListItem(
                  index: index,
                  receipt: openReceiptForReceiving[index],
                  onToggleHightlighted:  (selected) {
                    // reset the selected inventory
                    print("$index receipt is selected? $selected");
                    _onSelecteReceipt(selected, openReceiptForReceiving[index]);
                    // hide the dialog
                    Navigator.of(context).pop();
                  }
                  );
            }),
      );
  }

  void _onSelecteReceipt(bool selected, Receipt receipt) {

    if (selected) {
      setState(() {
        print("set current receipt to ${receipt.number}");
        _currentReceipt = receipt;
        _currentReceiptLine = new ReceiptLine();
        _receiptNumberController.text = receipt.number;
      });
    }
    _itemFocusNode.requestFocus();

  }
  // Show all items on this receipt
  _showChoosingItemsDialog() async {
    showLoading(context);
    List<ReceiptLine> receiptLines = _currentReceipt.receiptLines;

    // 隐藏loading框
    Navigator.of(context).pop();
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        var child = Column(
          children: <Widget>[
            Row(
              children: [
                ElevatedButton(
                  child: Text(CWMSLocalizations
                      .of(context)
                      .cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            ListTile(title: Text(CWMSLocalizations
                    .of(context)
                    .chooseItem)),
                _buildReceiptLineList(context, receiptLines)
          ],
        );
        //使用AlertDialog会报错
        //return AlertDialog(content: child);
        return Dialog(child: child);
      },
    );
  }
  Widget _buildReceiptLineList(BuildContext context,
      List<ReceiptLine> receiptLines) {
    return
      Expanded(
        child: ListView.builder(
            itemCount: receiptLines.length,
            itemBuilder: (BuildContext context, int index) {

              return ReceiptLineListItem(
                  index: index,
                  receiptLine: receiptLines[index],
                  onToggleHightlighted:  (selected) {
                    // reset the selected inventory
                    _onSelecteReceiptLine(selected, receiptLines[index]);
                    // hide the dialog
                    Navigator.of(context).pop();
                  }
              );
            }),
      );
  }

  void _onSelecteReceiptLine(bool selected, ReceiptLine receiptLine) {

    if (selected) {
      setState(() {

        _currentReceiptLine = receiptLine;
        _itemController.text = receiptLine.item.name;
      });
    }
    _quantityFocusNode.requestFocus();

  }


  void _reloadInventoryOnRF() {

    try {

      InventoryService.getInventoryOnCurrentRF()
          .then((value) {
        setState(() {
          inventoryOnRF = value;
        });
      });
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

  }

  void _enterOnLPNController({int tryTime = 10}) async {
    if (_getItemPackageTypeItems().isEmpty) {
      showErrorToast(

        CWMSLocalizations.of(context).itemNotReceivableNoPackageType,
      );
      _readyToConfirm = true;
      return;
    }
    // we may come here when the user scan / press
    // enter in the LPN controller. In either case, we will need to make sure
    // the lpn doesn't have focus before we start confirm

    printLongLogMessage("Start to confirm receiving inventory, tryTime = $tryTime}");
    if (tryTime <= 0) {
      // do nothing as we run out of try time

      setState(() {
        // enable the confirm button
        _readyToConfirm = true;
      });
      return;
    }
    if (_lpnFocusNode.hasFocus) {
      printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnLPNController(tryTime: tryTime - 1));

      return;

    }
    // if we are here, then it means we already have the full LPN
    // due to how  flutter handle the input, we will get the enter
    // action listner handler fired before the input characters are
    // full assigned to the lpnController.

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
        _onRecevingConfirm(_currentReceiptLine,
            int.parse(_quantityController.text),
            _lpnController.text);
      }
    }

    setState(() {
      // enable the confirm button
      _readyToConfirm = true;
    });

  }

}