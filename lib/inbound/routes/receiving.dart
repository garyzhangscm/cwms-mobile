import 'package:badges/badges.dart';
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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


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
          autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[

              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
                  Row(
                      children: <Widget>[
                        Text(CWMSLocalizations.of(context).receiptNumber,
                          textAlign: TextAlign.left,
                        ),
                        Expanded(
                          child:
                          Focus(
                            child: TextFormField(

                                controller: _receiptNumberController,

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
                        )
                      ]
                  ),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child:
                    // confirm the location
                    Row(
                        children: <Widget>[
                          Text(CWMSLocalizations.of(context).item,
                            textAlign: TextAlign.left,
                          ),
                          Expanded(
                            child:
                            Focus(
                              child: TextFormField(

                                  controller: _itemController,
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
                          )
                        ]
                    ),
              ),
              // display the item
              Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child:
                    Row(
                        children: <Widget>[
                          Text(CWMSLocalizations.of(context).item,
                            textAlign: TextAlign.left,
                          ),
                          Text(_currentReceiptLine.item == null ?
                              "" : _currentReceiptLine.item.description,
                            textAlign: TextAlign.left,
                          ),
                        ]
                    ),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child:
                    Row(
                        children: <Widget>[
                          Text(CWMSLocalizations.of(context).expectedQuantity,
                            textAlign: TextAlign.left,
                          ),
                          Text(_currentReceiptLine.expectedQuantity.toString(),
                            textAlign: TextAlign.left,
                          ),
                        ]
                    ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
                  Row(
                      children: <Widget>[
                        Text(CWMSLocalizations.of(context).receivedQuantity,
                          textAlign: TextAlign.left,
                        ),
                        Text(_currentReceiptLine.receivedQuantity.toString(),
                          textAlign: TextAlign.left,
                        ),
                      ]
                  ),
              ),
              // Allow the user to choose item package type
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
                  Row(
                      children: <Widget>[
                        Text(CWMSLocalizations.of(context).itemPackageType,
                          textAlign: TextAlign.left,
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
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
                Row(
                    children: <Widget>[
                      Text(CWMSLocalizations.of(context).inventoryStatus,
                        textAlign: TextAlign.left,
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
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child:
                    // always force the user to input / confirm the quantity
                    // picked this time
                    Row(
                        children: <Widget>[
                          Text("Receiving Quantity:",
                            textAlign: TextAlign.left,
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
                                    if (!_validateOverReceiving(
                                        _currentReceiptLine, int.parse(_quantityController.text))) {

                                      return "over pick is not allowed";
                                    }
                                    return null;
                                  }),
                            ),
                          )
                        ]
                    ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
                // always force the user to input / confirm the quantity
                // picked this time
                Row(
                    children: <Widget>[
                      Text(CWMSLocalizations
                          .of(context)
                          .lpn+ ": ",
                        textAlign: TextAlign.left,
                      ),
                      Expanded(
                        child:
                          Focus(
                            child: TextFormField(
                                controller: _lpnController,
                                validator: (v) {
                                  return null;
                                }),
                          ),
                      )
                    ]
                ),
              ),
              _buildButtons(context)
              /***
              Padding(
                padding: const EdgeInsets.only(top: 25),
                child: ConstrainedBox(
                  constraints: BoxConstraints.expand(height: 55.0),
                  child: RaisedButton(
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                       if (_formKey.currentState.validate()) {
                         print("form validation passed");
                         _onRecevingConfirm(_currentReceiptLine,
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
               */
            ],
          ),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }
  Widget _buildButtons(BuildContext context) {
    return
      Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        //交叉轴的布局方式，对于column来说就是水平方向的布局方式
        crossAxisAlignment: CrossAxisAlignment.center,
        //就是字child的垂直布局方向，向上还是向下
        verticalDirection: VerticalDirection.down,
        children: [
          // button to confirm receiving
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child:
            RaisedButton(
              color: Theme.of(context).primaryColor,
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  print("form validation passed");
                  _onRecevingConfirm(_currentReceiptLine,
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
          // button to deposit inventory
          Padding(
              padding: const EdgeInsets.only(left: 10),
              child:
                Badge(
                  showBadge: true,
                  padding: EdgeInsets.all(8),
                  badgeColor: Colors.deepPurple,
                  badgeContent: Text(
                    inventoryOnRF.length.toString(),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  child: RaisedButton(
                    onPressed: inventoryOnRF.length == 0 ? null : _startDeposit,
                    child: Text(CWMSLocalizations.of(context).depositInventory),
                  ),
                )
          ),
        ],
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
    List<DropdownMenuItem> items = new List();

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


    showLoading(context);
    await ReceiptService.receiveInventory(
      _currentReceipt, _currentReceiptLine,
        _lpnController.text, _selectedInventoryStatus,
        _selectedItemPackageType, int.parse(_quantityController.text)
    );
    print("inventory received!");

    Navigator.of(context).pop();
    showToast("inventory received");
    // we will allow the user to continue receiving with the same
    // receipt and line
    _lpnController.clear();
    _quantityController.clear();


    // refresh the inventory on the RF
    _reloadInventoryOnRF();

  }



  _startItemBarcodeScanner()  async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print("barcode scanned: $barcodeScanRes");
    _receiptNumberController.text = barcodeScanRes;
    _loadReceipt(_receiptNumberController.text);

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
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print("barcode scanned: $barcodeScanRes");
    _itemController.text = barcodeScanRes;
    _loadReceiptLine(_itemController.text);
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

}