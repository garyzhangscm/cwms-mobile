import 'package:badges/badges.dart';
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
import 'package:cwms_mobile/shared/services/qr_code_service.dart';
import 'package:flutter/material.dart';
import 'package:progress_dialog/progress_dialog.dart';


class BarcodeReceivingPage extends StatefulWidget{

  BarcodeReceivingPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _BarcodeReceivingPageState();

}

class _BarcodeReceivingPageState extends State<BarcodeReceivingPage> {

  // input batch id

  List<Inventory>  _inventoryOnRF = [];
  Inventory _lastReceivedInventory;
  Receipt _lastReceivedReceipt;


  ProgressDialog pr;

  @override
  void initState() {
    super.initState();


    _inventoryOnRF = [];

    _lastReceivedInventory = null;
    _lastReceivedReceipt = null;


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
                      _lastReceivedReceipt.number),
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context).lpn,
                      _lastReceivedInventory.lpn),
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context).item,
                      _lastReceivedInventory.item.name),
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context).item,
                      _lastReceivedInventory.item.description),
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context).quantity,
                      _lastReceivedInventory.quantity.toString() + " " +
                          ( _lastReceivedInventory.itemPackageType.stockItemUnitOfMeasure == null ?
                         "" : _lastReceivedInventory.itemPackageType.stockItemUnitOfMeasure.unitOfMeasure.description)),
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context).quantity,
                      _getDisplayQuantity(_lastReceivedInventory).toString() + " " + _getDisplayUOM(_lastReceivedInventory)),
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context).inventoryStatus,
                      _lastReceivedInventory.inventoryStatus.description),
                ]),
              ),
              // Expanded(child: Container(color: Colors.amber)),
          ]),
      ),
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
      Badge(
        showBadge: true,
        padding: EdgeInsets.all(8),
        badgeColor: Colors.deepPurple,
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

  // call the deposit form to deposit the inventory on the RF
  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the inventory on the RF
    _reloadInventoryOnRF();
  }
  _showQRCodeView() async {

    final result = await Navigator.of(context)
        .pushNamed("qr_code_view");

    printLongLogMessage("capture the QR CODE: " + result);

    var parameters = QRCodeService.parseQRCode(result);

    printLongLogMessage("resutl after parse the code code: \n ${parameters}");

    String receiptIdString = parameters["receiptId"];
    String receiptLineIdString = parameters["receiptLineId"];
    // String itemName = parameters["itemName"];
    String quantityString = parameters["quantity"];
    String inventoryStatusString = parameters["inventoryStatus"];
    String itemPackageTypeString = parameters["itemPackageType"];
    String lpn = parameters["lpn"];

    // validate the barcode
    // we will need to pass in either
    // 1. receiptId and receiptLineId and Item
    if (receiptIdString == null || receiptIdString.isEmpty ||
        receiptLineIdString == null || receiptLineIdString.isEmpty ||
        quantityString == null || quantityString.isEmpty ||
        lpn == null || lpn.isEmpty) {

      showErrorDialog(context, CWMSLocalizations.of(context).incorrectBarcodeFormat);
      return;
    }
    showLoading(context);

    InventoryStatus inventoryStatus;
    if (inventoryStatusString == null || inventoryStatusString.isEmpty) {
      // if inventory status is not passed in, receive by default available inventory status
      inventoryStatus = await InventoryStatusService.getAvaiableInventoryStatus();
    }
    else {
      inventoryStatus = await InventoryStatusService.getInventoryStatusByName(inventoryStatusString);
    }
    if (inventoryStatus == null) {

      Navigator.of(context).pop();
      showErrorDialog(context, CWMSLocalizations.of(context).incorrectBarcodeFormat);
      return;
    }

    Receipt receipt = await ReceiptService.getReceiptById(int.parse(receiptIdString));
    ReceiptLine receiptLine = await ReceiptService.getReceiptLineById(int.parse(receiptLineIdString));

    ItemPackageType itemPackageType;
    if (itemPackageTypeString == null || itemPackageTypeString.isEmpty) {
      // if item package type is not passed, get the default item package type from the item

      itemPackageType = receiptLine.item.defaultItemPackageType != null ?
          receiptLine.item.defaultItemPackageType :
          receiptLine.item.itemPackageTypes.length == 1 ?
              receiptLine.item.itemPackageTypes[0] : null;
    }
    else {
      itemPackageType = await ItemPackageTypeService.getItemPackageTypeByName(
          receiptLine.item.id, itemPackageTypeString
      );
    }
    if (itemPackageType == null) {

      Navigator.of(context).pop();
      showErrorDialog(context, CWMSLocalizations.of(context).incorrectBarcodeFormat);
      return;
    }

    _onRecevingSingleLpnConfirm(receipt, receiptLine, int.parse(quantityString),
        inventoryStatus, itemPackageType, lpn);

  }

  void _onRecevingSingleLpnConfirm(Receipt receipt,
      ReceiptLine receiptLine, int quantity,
      InventoryStatus inventoryStatus,
      ItemPackageType itemPackageType,
      String lpn) async {
    // TO-DO:Current we don't support the location code. Will add
    //      it later

    bool qcRequired = false;

    printLongLogMessage("1. _onRecevingSingleLpnConfirm / showLoading");
    // make sure the user input a valid LPN
    try {
      String errorMessage = await InventoryService.validateNewLpn(lpn);
      if (errorMessage.isNotEmpty) {
        Navigator.of(context).pop();
        showErrorDialog(context, errorMessage);
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
          receipt, receiptLine,
          lpn, inventoryStatus,
          itemPackageType, quantity
      );
      qcRequired = inventory.inboundQCRequired;
      printLongLogMessage("inventory ${inventory.lpn} received and need QC? ${inventory.inboundQCRequired}");
      if (qcRequired) {
        // for any inventory that needs qc, let's allocate the location automatically
        // for the inventory

        printLongLogMessage("allocate location for the QC needed inventory ${inventory.lpn}");
        InventoryService.allocateLocation(inventory);
      }

      // refresh the inventory to get latest information
      inventory = await InventoryService.getInventoryById(inventory.id);

      setState(() {
        _lastReceivedReceipt = receipt;
        _lastReceivedInventory = inventory;
      });
      // get the inventory with latest information
    }
    on WebAPICallException catch(ex) {


      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

    _refreshScreenAfterReceive(qcRequired);


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
      return inventory.quantity;
    }
    else if (inventory.quantity % displayItemUnitOfMeasure.quantity == 0) {
      printLongLogMessage("displayItemUnitOfMeasure: ${displayItemUnitOfMeasure.toJson()}");
      printLongLogMessage("inventory.quantity: ${inventory.quantity}, displayItemUnitOfMeasure.quantity: ${displayItemUnitOfMeasure.quantity}");
      printLongLogMessage("inventory.quantity % displayItemUnitOfMeasure.quantity:${inventory.quantity % displayItemUnitOfMeasure.quantity}");

      return inventory.quantity / displayItemUnitOfMeasure.quantity;
    }
    else {

      printLongLogMessage("displayItemUnitOfMeasure: ${displayItemUnitOfMeasure.toJson()}");
      printLongLogMessage("inventory.quantity: ${inventory.quantity}, displayItemUnitOfMeasure.quantity: ${displayItemUnitOfMeasure.quantity}");
      printLongLogMessage("inventory.quantity % displayItemUnitOfMeasure.quantity:${inventory.quantity % displayItemUnitOfMeasure.quantity}");
      return inventory.quantity;
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
    else if (inventory.quantity % displayItemUnitOfMeasure.quantity == 0) {
      return displayItemUnitOfMeasure.unitOfMeasure.description;
    }
    else {

      return "";
    }

  }
  ItemUnitOfMeasure _getDisplayItemUnitOfMeasure(Inventory inventory) {
    printLongLogMessage("start to get display item unit of measure from inventory:\n ${inventory.toJson()}");
    printLongLogMessage("inventory.itemPackageType: \n ${inventory.itemPackageType.toJson()}");

    if (inventory.itemPackageType.displayItemUnitOfMeasure != null) {
       printLongLogMessage("inventory.itemPackageType.displayItemUnitOfMeasure: \n ${inventory.itemPackageType.displayItemUnitOfMeasure.toJson()}");
    }

    return inventory.itemPackageType.displayItemUnitOfMeasure != null ?
          inventory.itemPackageType.displayItemUnitOfMeasure :
          inventory.itemPackageType.stockItemUnitOfMeasure;
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
      showErrorDialog(context, ex.errMsg());
      return;

    }

  }
}