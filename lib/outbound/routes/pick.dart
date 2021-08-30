import 'package:badges/badges.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/models/pick_result.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


class PickPage extends StatefulWidget{

  PickPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _PickPageState();

}

class _PickPageState extends State<PickPage> {

  // input batch id
  TextEditingController _itemController = new TextEditingController();
  TextEditingController _sourceLocationController = new TextEditingController();
  TextEditingController _quantityController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();
  Pick _currentPick;
  bool _lpnValidateResult = true;
  FocusNode _lpnFocusNode = FocusNode();

  final  _formKey = GlobalKey<FormState>();

  List<Inventory>  inventoryOnRF;

  @override
  void initState() {
    super.initState();

    _itemController.clear();
    _sourceLocationController.clear();
    _quantityController.clear();
    _lpnController.clear();


    inventoryOnRF = new List<Inventory>();

    _reloadInventoryOnRF();

    _lpnFocusNode.addListener(() { 
      printLongLogMessage("_lpnFocusNode hasFocus?: ${_lpnFocusNode.hasFocus}");
    });

  }
  @override
  Widget build(BuildContext context) {
    _currentPick  = ModalRoute.of(context).settings.arguments;
    // if we want the user to confirm LPN, then default the LPN Validator Result
    // to false and force the user to input one valid LPN
    _lpnValidateResult = _currentPick.confirmLpnFlag ? false : true;

    setupControllers(_currentPick);

    return Scaffold(
      appBar: AppBar(title: Text("CWMS - Pick")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          //autovalidateMode: AutovalidateMode.always, //开启自动校验
          child: Column(
            children: <Widget>[

              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
                  Row(
                      children: <Widget>[
                        Padding(padding: EdgeInsets.only(right: 10), child:
                          Text("Work Number:",
                            textAlign: TextAlign.left,
                          ),
                        ),

                        Text(_currentPick.number,
                          textAlign: TextAlign.left,
                        ),
                      ]
                  ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
                  // display the location
                  Row(
                      children: <Widget>[
                        Padding(padding: EdgeInsets.only(right: 10), child:
                          Text("Location:",
                            textAlign: TextAlign.left,
                          ),
                        ),

                        Text(_currentPick.sourceLocation.name,
                          textAlign: TextAlign.left,
                        ),
                      ]
                  ),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child:
                    // confirm the location
                    Row(
                        children: <Widget>[
                          Padding(padding: EdgeInsets.only(right: 10), child:
                            Text("Location:",
                              textAlign: TextAlign.left,
                            ),
                          ),

                          Expanded(
                            child:
                              Focus(
                                child: TextFormField(
                                    textInputAction: TextInputAction.next,
                                    controller: _sourceLocationController,
                                    decoration: InputDecoration(
                                      suffixIcon: IconButton(
                                        onPressed: () => _startLocationBarcodeScanner(),
                                        icon: Icon(Icons.scanner),
                                      ),
                                    ),
                                    // 校验company code（不能为空）
                                    validator: (v) {
                                      if (v.trim().isEmpty) {
                                        return "please scan in location";
                                      }
                                      if (v.trim() != _currentPick.sourceLocation.name) {

                                        return "wrong location";
                                      }
                                      return null;

                                    }),
                              ),
                          )
                        ]
                    ),
              ),

              // LPN number
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
                // confirm the lpn
                Row(
                    children: <Widget>[

                      Padding(padding: EdgeInsets.only(right: 10), child:
                        Text(CWMSLocalizations.of(context).lpn,
                          textAlign: TextAlign.left,
                        ),
                      ),

                      _currentPick.confirmLpnFlag ?
                        Expanded(
                          child: TextFormField(
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () async {
                                int pickableQuantity = await validateLPNByQuantity(_lpnController.text);

                                if (pickableQuantity > 0) {

                                  // lpn is valid, go to next control
                                  _quantityController.text = pickableQuantity.toString();
                                  FocusScope.of(context).nextFocus();
                                }
                                else {

                                  if (_currentPick.quantity > _currentPick.pickedQuantity) {

                                    _quantityController.text = (_currentPick.quantity - _currentPick.pickedQuantity).toString();
                                  }
                                  else {
                                    _quantityController.text = "0";
                                  }
                                  showToast(CWMSLocalizations.of(context).pickWrongLPN);
                                }
                              },
                              controller: _lpnController,
                              focusNode: _lpnFocusNode,
                              validator: (v) {
                                if (v.trim().isEmpty) {
                                  return CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).lpn);
                                }
                                if (!_lpnValidateResult) {
                                  return CWMSLocalizations.of(context).pickWrongLPN;
                                }
                                return null;
                              }),
                        )

                            :
                        Container()
                    ]
                ),
              ),

              Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child:
                    // display the item
                    Row(
                        children: <Widget>[
                          Padding(padding: EdgeInsets.only(right: 10), child:
                            Text("Item Number:",
                              textAlign: TextAlign.left,
                            ),
                          ),

                          Text(_currentPick.item.name,
                            textAlign: TextAlign.left,
                          ),
                        ]
                    ),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child:
                    // confirm the item
                    Row(
                        children: <Widget>[
                          Padding(padding: EdgeInsets.only(right: 10), child:
                            Text("Item Number:",
                              textAlign: TextAlign.left,
                            ),
                          ),


                          _currentPick.confirmItemFlag ?
                            Expanded(
                              child:
                              Focus(
                                child: TextFormField(
                                    textInputAction: TextInputAction.next,
                                    controller: _itemController,
                                    decoration: InputDecoration(
                                      suffixIcon: IconButton(
                                        onPressed: () => _startItemBarcodeScanner(),
                                        icon: Icon(Icons.scanner),
                                      ),
                                    ),
                                    // 校验ITEM NUMBER（不能为空）
                                    validator: (v) {

                                      if (v.trim().isEmpty) {
                                        return "please scan in item";
                                      }
                                      if (v.trim() != _currentPick.item.name) {

                                        return "wrong item";
                                      }
                                      return null;
                                    }),
                              ),
                            )
                                :
                            Container()
                        ]
                    ),
              ),
              Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child:
                    Row(
                        children: <Widget>[
                          Padding(padding: EdgeInsets.only(right: 10), child:
                            Text("Pick Quantity:",
                              textAlign: TextAlign.left,
                            ),
                          ),

                          Text(_currentPick.quantity.toString(),
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
                          Padding(padding: EdgeInsets.only(right: 10), child:
                            Text("Picked Quantity:",
                              textAlign: TextAlign.left,
                            ),
                          ),

                          Text(_currentPick.pickedQuantity.toString(),
                            textAlign: TextAlign.left,
                          ),
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
                          Padding(padding: EdgeInsets.only(right: 10), child:
                            Text("Picking Quantity:",
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Expanded(
                            child:
                            Focus(
                              child: TextFormField(
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.number,
                                  controller: _quantityController,
                                  // 校验ITEM NUMBER（不能为空）
                                  validator: (v) {

                                    if (v.trim().isEmpty) {
                                      return "please type in quantity";
                                    }
                                    if (int.parse(v.trim()) >
                                          (_currentPick.quantity - _currentPick.pickedQuantity)) {

                                      return "over pick is not allowed";
                                    }
                                    return null;
                                  }),
                            ),
                          )
                        ]
                    ),
              ),
              _buildButtons(context),
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

               ElevatedButton(
                 onPressed: () async {
                  //  Let's make sure the user input the right LPN
                  if(_currentPick.confirmLpnFlag) {
                    _lpnValidateResult = await validateLPN(_lpnController.text);
                  }
                  if (_formKey.currentState.validate()) {
                    _onPickConfirm(_currentPick, int.parse(_quantityController.text));
                  }
                 },
                 child: SizedBox(
                   width: MediaQuery.of(context).size.width * 0.4,
                   child: Text(CWMSLocalizations.of(context).confirm),
                 ),
              ),
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.4,
              child:
              Badge(
                showBadge: true,
                padding: EdgeInsets.all(8),
                badgeColor: Colors.deepPurple,
                badgeContent: Text(
                  inventoryOnRF.length.toString(),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                child:
                    ElevatedButton(
                      onPressed: inventoryOnRF.length == 0 ? null : _startDeposit,

                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: Text(CWMSLocalizations.of(context).depositInventory),
                      ),
                    ),
                )
          ),
        ],
      );
  }

  Future<bool> validateLPN(String lpn) async{
    List<Inventory> inventories = await InventoryService.findInventory(
      lpn: lpn,
      locationName: _currentPick.sourceLocation.name
    );
    return inventories.isNotEmpty;
  }

  // validate lPN for picking. If this LPN is not valid for the pick
  // return 0, otherwise, return the pickable quantity
  Future<int> validateLPNByQuantity(String lpn) async{
    List<Inventory> inventories = await InventoryService.findInventory(
        lpn: lpn,
        locationName: _currentPick.sourceLocation.name
    );
    if (inventories.isEmpty) {
      return 0;
    }
    return inventories.map((inventory) => inventory.quantity).reduce((a, b) => a + b);
  }

  void _onPickConfirm(Pick pick, int confirmedQuantity) async {


    // TO-DO:Current we don't support the location code. Will add
    //      it later


    showLoading(context);
    if (pick.confirmLpnFlag && _lpnController.text.isNotEmpty) {
      printLongLogMessage("We will confirm the pick with LPN ${_lpnController.text}");
      await PickService.confirmPick(
          pick, confirmedQuantity, _lpnController.text);
    }
    else {

      printLongLogMessage("We will confirm the pick with specify the LPN");
      await PickService.confirmPick(
          pick, confirmedQuantity);
    }
    print("pick confirmed");

    Navigator.of(context).pop();
    showToast("pick confirmed");

    var pickResult = PickResult.fromJson(
        {'result': true, 'confirmedQuantity': confirmedQuantity});

    // refresh the pick on the RF
    // _reloadInventoryOnRF();


    Navigator.pop(context, pickResult);
  }

  void _reloadInventoryOnRF() {

    InventoryService.getInventoryOnCurrentRF()
        .then((value) {
      setState(() {
        inventoryOnRF = value;
      });
    });

  }

  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the pick on the RF
    _reloadInventoryOnRF();
  }

  setupControllers(Pick pick) {

    if(pick.confirmItemFlag == false) {
      _itemController.text = pick.item.name;
    }
    if (pick.confirmLocationFlag == false &&
        pick.confirmLocationCodeFlag == false) {
      _sourceLocationController.text = pick.sourceLocation.name;
    }
    if (pick.quantity > pick.pickedQuantity) {

      _quantityController.text = (pick.quantity - pick.pickedQuantity).toString();
    }
    else {
      _quantityController.text = "0";
    }
  }

  _startItemBarcodeScanner()  async {
    /**
     *
        String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
        print("barcode scanned: $barcodeScanRes");
        _sourceLocationController.text = barcodeScanRes;
     * */

  }
  _startLocationBarcodeScanner() async {
    /**
     *
        String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
        print("barcode scanned: $barcodeScanRes");
        _itemController.text = barcodeScanRes;
     * */

  }


}