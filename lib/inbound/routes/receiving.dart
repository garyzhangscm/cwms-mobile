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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  List<Inventory>  inventoryOnRF;
  FocusNode _receiptNumberFocusNode = FocusNode();
  FocusNode _itemFocusNode = FocusNode();
  FocusNode _quantityFocusNode = FocusNode();
  FocusNode _lpnFocusNode = FocusNode();
  bool _readyToConfirm = true; // whether we can confirm the received inventory


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
        _itemFocusNode.requestFocus();

      }
    });
    _receiptNumberFocusNode.requestFocus();

    _itemFocusNode.addListener(() {
      print("_itemFocusNode.hasFocus: ${_itemFocusNode.hasFocus}");
      if (!_itemFocusNode.hasFocus && _itemController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _loadReceiptLine(_itemController.text);
        _quantityFocusNode.requestFocus();

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          // autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[

              buildTowSectionInputRow(
                CWMSLocalizations.of(context).receiptNumber,
                TextFormField(
                    controller: _receiptNumberController,
                    autofocus: true,
                    focusNode: _receiptNumberFocusNode,
                    decoration: InputDecoration(
                      suffixIcon:
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                        mainAxisSize: MainAxisSize.min, // added line
                        children: <Widget>[
                          IconButton(
                            onPressed: _startReceiptBarcodeScanner,
                            icon: Icon(Icons.scanner),
                          ),
                          IconButton(
                            onPressed: _showChoosingReceiptDialog,
                            icon: Icon(Icons.list),
                          ),
                        ],
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

              buildTowSectionInputRow(
                CWMSLocalizations.of(context).item,
                TextFormField(
                    controller: _itemController,
                    autofocus: true,
                    focusNode: _itemFocusNode,
                    decoration: InputDecoration(
                      suffixIcon:
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                        mainAxisSize: MainAxisSize.min, // added line
                        children: <Widget>[
                          IconButton(
                            onPressed: _startItemBarcodeScanner,
                            icon: Icon(Icons.scanner),
                          ),
                          IconButton(
                            onPressed: _showChoosingItemsDialog,
                            icon: Icon(Icons.list),
                          ),
                        ],
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
              buildTwoSectionInformationRow(
                CWMSLocalizations.of(context).expectedQuantity,
                _currentReceiptLine.expectedQuantity.toString(),
              ),
              buildTwoSectionInformationRow(
                CWMSLocalizations.of(context).receivedQuantity,
                _currentReceiptLine.receivedQuantity.toString(),
              ),
              // Allow the user to choose item package type

              buildTowSectionInputRow(
                CWMSLocalizations.of(context).itemPackageType,
                DropdownButton(
                    hint: Text(""),
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

              buildTowSectionInputRow(
                  CWMSLocalizations.of(context).inventoryStatus,
                  DropdownButton(
                    hint: Text(""),
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

              buildTowSectionInputRow(
                  "Receiving Quantity:",
                  TextFormField(
                      keyboardType: TextInputType.number,
                      controller: _quantityController,
                      autofocus: true,
                      focusNode: _quantityFocusNode,
                      onFieldSubmitted: (v){
                        printLongLogMessage("start to focus on lpn node");
                        _lpnFocusNode.requestFocus();

                      },
                      // 校验ITEM NUMBER（不能为空）
                      validator: (v) {
                        if (v.trim().isEmpty) {
                          return "please type in quantity";
                        }
                        if (!_validateOverReceiving(
                            _currentReceiptLine, int.parse(_quantityController.text))) {

                          return "over pick is not allowed";
                        }
                        return null;
                      })
              ),

              buildTowSectionInputRow(
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
                          if (v.trim().isEmpty) {
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
    return buildTowButtonRow(
      context,
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState.validate()) {
            print("form validation passed");
            _onRecevingConfirm(_currentReceiptLine,
                int.parse(_quantityController.text),
                _lpnController.text);
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
    List<DropdownMenuItem> items = new List();
    if (_validInventoryStatus == null) {
      return items;
    }
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
    List<DropdownMenuItem> items = [];

    print("_currentReceiptLine.item.itemPackageTypes.length: ${_currentReceiptLine.item.itemPackageTypes.length}");
    if (_currentReceiptLine.item.itemPackageTypes.length > 0) {
      _selectedItemPackageType = _currentReceiptLine.item.itemPackageTypes[0];

      for (int i = 0; i < _currentReceiptLine.item.itemPackageTypes.length; i++) {

        items.add(DropdownMenuItem(
          value: _currentReceiptLine.item.itemPackageTypes[i],
          child: Text(_currentReceiptLine.item.itemPackageTypes[i].description),
        ));
      }
    }
    return items;
  }

  void _onRecevingConfirm(ReceiptLine receiptLine, int confirmedQuantity,
                String lpn) async {


    // TO-DO:Current we don't support the location code. Will add
    //      it later

    bool qcRequired = false;

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
    try {
      Inventory inventory = await ReceiptService.receiveInventory(
          _currentReceipt, _currentReceiptLine,
          _lpnController.text, _selectedInventoryStatus,
          _selectedItemPackageType, int.parse(_quantityController.text)
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
                FlatButton(
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
                FlatButton(
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

  }


  void _reloadInventoryOnRF() {

    InventoryService.getInventoryOnCurrentRF()
        .then((value) {
      setState(() {
        inventoryOnRF = value;
      });
    });

  }

  void _enterOnLPNController({int tryTime = 10}) async {
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

    printLongLogMessage("lpn controller lost focus, its value is ${_lpnController.text}");
    if (_formKey.currentState.validate()) {
      print("form validation passed");
      _onRecevingConfirm(_currentReceiptLine,
          int.parse(_quantityController.text),
          _lpnController.text);
    }

    setState(() {
      // enable the confirm button
      _readyToConfirm = true;
    });

  }

}