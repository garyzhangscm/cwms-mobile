import 'package:badges/badges.dart' as badge;
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inbound/models/receipt.dart';
import 'package:cwms_mobile/inbound/models/receipt_line.dart';
import 'package:cwms_mobile/inbound/services/receipt.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/models/item_unit_of_measure.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
import 'package:cwms_mobile/inventory/services/item_package_type.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/models/cwms_http_exception.dart';
import 'package:cwms_mobile/shared/services/barcode_service.dart';
import 'package:flutter/material.dart';
import 'package:progress_dialog_null_safe/progress_dialog_null_safe.dart';

import '../../shared/models/barcode.dart';


class BarcodeReceivingPage extends StatefulWidget{

  BarcodeReceivingPage({Key? key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _BarcodeReceivingPageState();

}

class _BarcodeReceivingPageState extends State<BarcodeReceivingPage> {

  // input batch id

  List<Inventory>  _inventoryOnRF = [];
  Inventory? _lastReceivedInventory;
  Receipt? _lastReceivedReceipt;

  TextEditingController _barcodeController = new TextEditingController();
  FocusNode _barcodeFocusNode = FocusNode();

  ProgressDialog? pr;

  @override
  void initState() {
    super.initState();


    _inventoryOnRF = [];

    _lastReceivedInventory = null;
    _lastReceivedReceipt = null;

    _barcodeFocusNode.addListener(() {
      printLongLogMessage("_barcodeFocusNode.hasFocus: ${_barcodeFocusNode.hasFocus}");
      if (!_barcodeFocusNode.hasFocus && _barcodeController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _enterOnBarcodeController();
      }
    });

    _reloadInventoryOnRF();
  }
  final  _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).barcodeReceiving)),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Form(
          key: _formKey,
          // autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[

              Row(
                children: [
                  Text(CWMSLocalizations.of(context).barcodeLastReceivingVerbiage,
                      style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 0.5))
                ],
              ),
              _lastReceivedInventory == null ?
                  _buildEmptyReceivingInformationDisplay(context) :
                  _buildPreviousReceivingInformationDisplay(context),
              Row(
                children: [
                  Text(CWMSLocalizations.of(context).barcodeReceivingVerbiage,
                      style: TextStyle(fontWeight: FontWeight.bold))
                ],
              ),
              _buildBarcodeTextInput(context),
              _buildButtons(context)
            ],
          ),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildEmptyReceivingInformationDisplay(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10),
      child: IntrinsicHeight(
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(children: [
                  Container(height: 240.0),
                ]),
              ),
              // Expanded(child: Container(color: Colors.amber)),
            ]),
      ),
    );

  }
  Widget _buildPreviousReceivingInformationDisplay(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10),
      child: IntrinsicHeight(
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(children: [
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context).receiptNumber,
                      _lastReceivedReceipt?.number ?? ""),
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context).lpn,
                      _lastReceivedInventory?.lpn ?? ""),
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context).item,
                      _lastReceivedInventory?.item?.name ?? ""),
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context).item,
                      _lastReceivedInventory?.item?.description ?? ""),
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context).quantity,
                      (_lastReceivedInventory?.quantity.toString()  ?? "") + " " +
                          (_lastReceivedInventory?.itemPackageType?.stockItemUnitOfMeasure?.unitOfMeasure?.description ?? "")),
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context).quantity,
                      _lastReceivedInventory == null ? "" :
                          (_getDisplayQuantity(_lastReceivedInventory!).toString()
                              + " " + _getDisplayUOM(_lastReceivedInventory!))),
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context).inventoryStatus,
                      _lastReceivedInventory?.inventoryStatus?.description ?? ""),
                ]),
              ),
              // Expanded(child: Container(color: Colors.amber)),
          ]),
      ),
    );

  }
  Widget _buildBarcodeTextInput(BuildContext context) {
    return TextFormField(
        controller: _barcodeController,
        showCursor: true,
        // showKeyboard: widget.showKeyboard,
        autofocus: true,
        focusNode: _barcodeFocusNode,


    );
  }
  Widget _buildButtons(BuildContext context) {
    return buildTwoButtonRow(
      context,
      ElevatedButton(
        onPressed: _showQRCodeView,
        child: Text(CWMSLocalizations
            .of(context)
            .startCamera),
      ),
      badge.Badge(
        showBadge: true,
        badgeStyle: badge.BadgeStyle(
          padding: EdgeInsets.all(8),
          badgeColor: Colors.deepPurple,
        ),
        badgeContent: Text(
          _inventoryOnRF == null || _inventoryOnRF.length == 0 ? "0" : _inventoryOnRF.length.toString(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        child:
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              onPressed: _inventoryOnRF.length == 0 ? null : _startDeposit,
              child: Text(CWMSLocalizations.of(context).depositInventory),
            ),
          ),
      )
    );

  }



  void _enterOnBarcodeController({int tryTime = 10}) async {


    if (_barcodeFocusNode.hasFocus) {
      printLongLogMessage("barcode controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnBarcodeController(tryTime: tryTime - 1));

      return;

    }

    String barcode = _barcodeController.text.trim();

    bool result = await _processBarcode(barcode);

    if (result == true) {
      _barcodeController.clear();
    }

    _barcodeFocusNode.requestFocus();

  }

  // call the deposit form to deposit the inventory on the RF
  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the inventory on the RF
    _reloadInventoryOnRF();
  }
  _showQRCodeView() async {
    final barcode = await Navigator.of(context)
        .pushNamed("qr_code_view");

    bool result = await _processBarcode(barcode.toString());

    if (result == true) {
      _barcodeController.clear();
      _barcodeFocusNode.requestFocus();
    }
  }

  Future<bool> _processBarcode(String barcode) async {

    var parameters =  new Map();

    try {

      Barcode barcodeResult = BarcodeService.parseBarcode(barcode);
      if (barcodeResult.is_2d == false || barcodeResult.result?.isEmpty == true) {
        Navigator.of(context).pop();
        await showBlockedErrorDialog(context, "Can't parse the barcode " + barcode);
        return false;
      }
      parameters = barcodeResult.result!;
    }
    on Exception catch(ex) {

      Navigator.of(context).pop();
      await showBlockedErrorDialog(context, "Can't parse the barcode " + barcode);
      return false;

    }


    String receiptIdString = parameters["receiptId"];
    String receiptLineIdString = parameters["receiptLineId"];
    // String itemName = parameters["itemName"];
    String quantityString = parameters["quantity"];
    String inventoryStatusString = parameters["inventoryStatus"];
    String itemPackageTypeString = parameters["itemPackageType"];
    String lpn = parameters["lpn"];
    //inventory attribute

    String color = parameters.containsKey("color") ? parameters["color"]:"";
    String productSize = parameters.containsKey("productSize") ? parameters["productSize"]:"";
    String style = parameters.containsKey("style") ? parameters["style"]:"";

    String inventoryAttribute1 = parameters.containsKey("inventoryAttribute1") ? parameters["inventoryAttribute1"]:"";
    String inventoryAttribute2 = parameters.containsKey("inventoryAttribute2") ? parameters["inventoryAttribute2"]:"";
    String inventoryAttribute3 = parameters.containsKey("inventoryAttribute3") ? parameters["inventoryAttribute3"]:"";
    String inventoryAttribute4 = parameters.containsKey("inventoryAttribute4") ? parameters["inventoryAttribute4"]:"";
    String inventoryAttribute5 = parameters.containsKey("inventoryAttribute5") ? parameters["inventoryAttribute5"]:"";

    // validate the barcode
    // we will need to pass in either
    // 1. receiptId and receiptLineId and Item
    if (receiptIdString == null || receiptIdString.isEmpty ||
        receiptLineIdString == null || receiptLineIdString.isEmpty ||
        quantityString == null || quantityString.isEmpty ||
        lpn == null || lpn.isEmpty) {

      await showBlockedErrorDialog(context, CWMSLocalizations.of(context).incorrectBarcodeFormat);
      return false;
    }
    showLoading(context);

    InventoryStatus? inventoryStatus;
    if (inventoryStatusString == null || inventoryStatusString.isEmpty) {
      // if inventory status is not passed in, receive by default available inventory status
      inventoryStatus = await InventoryStatusService.getAvaiableInventoryStatus();
    }
    else {
      inventoryStatus = await InventoryStatusService.getInventoryStatusByName(inventoryStatusString);
    }
    if (inventoryStatus == null) {

      Navigator.of(context).pop();
      await showBlockedErrorDialog(context, CWMSLocalizations.of(context).incorrectBarcodeFormat);
      return false;
    }

    Receipt receipt = await ReceiptService.getReceiptById(int.parse(receiptIdString));
    ReceiptLine receiptLine = await ReceiptService.getReceiptLineById(int.parse(receiptLineIdString));

    ItemPackageType? itemPackageType;
    if (itemPackageTypeString == null || itemPackageTypeString.isEmpty) {
      // if item package type is not passed, get the default item package type from the item

      itemPackageType = receiptLine.item?.defaultItemPackageType != null ?
          receiptLine.item?.defaultItemPackageType :
          receiptLine.item?.itemPackageTypes.length == 1 ?
              receiptLine.item?.itemPackageTypes[0] : null;
    }
    else {
      itemPackageType = await ItemPackageTypeService.getItemPackageTypeByName(
          receiptLine.item!.id!, itemPackageTypeString
      );
    }
    if (itemPackageType == null) {

      Navigator.of(context).pop();
      await showBlockedErrorDialog(context, CWMSLocalizations.of(context).incorrectBarcodeFormat);
      return false;
    }

    printLongLogMessage("start to receive inventory with attribute:");
    printLongLogMessage("color: $color" );
    printLongLogMessage("productSize: $productSize" );
    printLongLogMessage("style: $style" );
    printLongLogMessage("inventoryAttribute1: $inventoryAttribute1" );
    printLongLogMessage("inventoryAttribute2: $inventoryAttribute2" );
    printLongLogMessage("inventoryAttribute3: $inventoryAttribute3" );
    printLongLogMessage("inventoryAttribute4: $inventoryAttribute4" );
    printLongLogMessage("inventoryAttribute5: $inventoryAttribute5" );
    return _onReceivingSingleLpnConfirm(receipt, receiptLine, int.parse(quantityString),
        inventoryStatus, itemPackageType, lpn,
    color, productSize, style,
    inventoryAttribute1,
      inventoryAttribute2,
      inventoryAttribute3,
      inventoryAttribute4,
      inventoryAttribute5);

  }

  Future<bool> _onReceivingSingleLpnConfirm(Receipt receipt,
      ReceiptLine receiptLine, int quantity,
      InventoryStatus inventoryStatus,
      ItemPackageType itemPackageType,
      String lpn,
      String color, String productSize, String style,
      String inventoryAttribute1,
      String inventoryAttribute2,
      String inventoryAttribute3,
      String inventoryAttribute4,
      String inventoryAttribute5) async {
    // TO-DO:Current we don't support the location code. Will add
    //      it later

    bool qcRequired = false;

    // make sure the user input a valid LPN
    try {
      String errorMessage = await InventoryService.validateNewLpn(lpn);
      if (errorMessage.isNotEmpty) {
        Navigator.of(context).pop();
        await showBlockedErrorDialog(context, errorMessage);
        return false;
      }
    }
    on CWMSHttpException catch(ex) {

      Navigator.of(context).pop();
      await showBlockedErrorDialog(context, "${ex.code} - ${ex.message}");
      return false;

    }
    try {
      Inventory inventory = await ReceiptService.receiveInventory(
          receipt, receiptLine,
          lpn, inventoryStatus,
          itemPackageType, quantity,
          color, productSize, style,
          inventoryAttribute1,
          inventoryAttribute2,
          inventoryAttribute3,
          inventoryAttribute4,
          inventoryAttribute5,
        false, false
      );
      qcRequired = inventory.inboundQCRequired!;
      printLongLogMessage("inventory ${inventory.lpn} received and need QC? ${inventory.inboundQCRequired}");
      if (qcRequired) {
        // for any inventory that needs qc, let's allocate the location automatically
        // for the inventory

        printLongLogMessage("allocate location for the QC needed inventory ${inventory.lpn}");
        InventoryService.allocateLocation(inventory);
      }

      // refresh the inventory to get latest information
      inventory = await InventoryService.getInventoryById(inventory.id!);

      setState(() {
        _lastReceivedReceipt = receipt;
        _lastReceivedInventory = inventory;
      });
      // get the inventory with latest information
    }
    on WebAPICallException catch(ex) {


      Navigator.of(context).pop();
      await showBlockedErrorDialog(context, ex.errMsg());
      return false;

    }

    _refreshScreenAfterReceive(qcRequired);

    return true;

  }

  _refreshScreenAfterReceive(bool qcRequired) {
    print("inventory received!");

    Navigator.of(context).pop();

    if (qcRequired == true) {
      showWarningDialog(context, CWMSLocalizations.of(context).inventoryNeedQC);
    }
    showToast("inventory received");

    // refresh the inventory on the RF
    _reloadInventoryOnRF();

  }
  num _getDisplayQuantity(Inventory inventory) {
    // get the display UOM
    // display by the display UOM only if the display UOM is defined and the quantity
    // of the inventory can be divided by the display UOM
    ItemUnitOfMeasure displayItemUnitOfMeasure = _getDisplayItemUnitOfMeasure(inventory);

    if (displayItemUnitOfMeasure == null) {
      printLongLogMessage("display item unit of measure is not defined");
      return inventory.quantity!;
    }
    else if (inventory.quantity! % displayItemUnitOfMeasure.quantity! == 0) {
      printLongLogMessage("displayItemUnitOfMeasure: ${displayItemUnitOfMeasure.toJson()}");
      printLongLogMessage("inventory.quantity: ${inventory.quantity}, displayItemUnitOfMeasure.quantity: ${displayItemUnitOfMeasure.quantity}");
      printLongLogMessage("inventory.quantity % displayItemUnitOfMeasure.quantity:${inventory.quantity! % displayItemUnitOfMeasure.quantity!}");

      return inventory.quantity! / displayItemUnitOfMeasure.quantity!;
    }
    else {

      printLongLogMessage("displayItemUnitOfMeasure: ${displayItemUnitOfMeasure.toJson()}");
      printLongLogMessage("inventory.quantity: ${inventory.quantity}, displayItemUnitOfMeasure.quantity: ${displayItemUnitOfMeasure.quantity}");
      printLongLogMessage("inventory.quantity % displayItemUnitOfMeasure.quantity:${inventory.quantity! % displayItemUnitOfMeasure.quantity!}");
      return inventory.quantity!;
    }

  }
  String _getDisplayUOM(Inventory inventory) {
    // get the display UOM
    // display by the display UOM only if the display UOM is defined and the quantity
    // of the inventory can be divided by the display UOM
    ItemUnitOfMeasure displayItemUnitOfMeasure = _getDisplayItemUnitOfMeasure(inventory);
    if (displayItemUnitOfMeasure == null) {
      return "";
    }
    else if (inventory.quantity! % displayItemUnitOfMeasure!.quantity! == 0) {
      return displayItemUnitOfMeasure.unitOfMeasure?.description ?? "";
    }
    else {

      return "";
    }

  }
  ItemUnitOfMeasure _getDisplayItemUnitOfMeasure(Inventory inventory) {
    printLongLogMessage("start to get display item unit of measure from inventory:\n ${inventory.toJson()}");
    printLongLogMessage("inventory.itemPackageType: \n ${inventory.itemPackageType?.toJson()}");

    if (inventory.itemPackageType?.displayItemUnitOfMeasure != null) {
       printLongLogMessage("inventory.itemPackageType.displayItemUnitOfMeasure: \n ${inventory.itemPackageType!.displayItemUnitOfMeasure?.toJson()}");
    }

    return inventory.itemPackageType!.displayItemUnitOfMeasure != null ?
          inventory.itemPackageType!.displayItemUnitOfMeasure! :
          inventory.itemPackageType!.stockItemUnitOfMeasure!;
  }

  void _reloadInventoryOnRF() {

    try {

      InventoryService.getInventoryOnCurrentRF()
          .then((value) {
        setState(() {
          _inventoryOnRF = value;
        });
      });
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showBlockedErrorDialog(context, ex.errMsg());
      return;

    }

  }
}