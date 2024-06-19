import 'package:badges/badges.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/models/pick_result.dart';
import 'package:cwms_mobile/outbound/services/bulk_pick.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/material.dart';

import '../models/bulk_pick.dart';

import '../../shared/services/barcode_service.dart';
import '../../shared/models/barcode.dart';





class BulkPickPage extends StatefulWidget{

  BulkPickPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _BulkPickPageState();

}

class _BulkPickPageState extends State<BulkPickPage> {

  // input batch id
  TextEditingController _itemController = new TextEditingController();
  TextEditingController _sourceLocationController = new TextEditingController();
  TextEditingController _quantityController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();
  BulkPick _currentBulkPick;
  FocusNode _lpnFocusNode = FocusNode();
  FocusNode _lpnControllerFocusNode = FocusNode();
  FocusNode _sourceLocationFocusNode = FocusNode();
  FocusNode _sourceLocationControllerFocusNode = FocusNode();
  FocusNode _quantityFocusNode = FocusNode();
  FocusNode _quantityControllerFocusNode = FocusNode();


  List<Inventory>  inventoryOnRF;

  @override
  void initState() {
    super.initState();

    _itemController.clear();
    _sourceLocationController.clear();
    _quantityController.clear();
    _lpnController.clear();


    inventoryOnRF = [];

    _reloadInventoryOnRF();

    _sourceLocationFocusNode.addListener(() async {
      printLongLogMessage("_sourceLocationFocusNode hasFocus?: ${_sourceLocationFocusNode.hasFocus}");
      printLongLogMessage("_sourceLocationController text?: ${_sourceLocationController.text}");
      if (!_sourceLocationFocusNode.hasFocus && _sourceLocationController.text.isNotEmpty) {
        _enterOnLocationController(10);

      }});

    _lpnFocusNode.addListener(() async {
      printLongLogMessage("_lpnFocusNode hasFocus?: ${_lpnFocusNode.hasFocus}");
      printLongLogMessage("_sourceLocationController text?: ${_lpnController.text}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {


        Barcode barcode = BarcodeService.parseBarcode(_lpnController.text);
        if (barcode.is_2d) {
          // for 2d barcode, let's get the result and set the LPN back to the text
          String lpn = BarcodeService.getLPN(barcode);
          printLongLogMessage("get lpn from lpn?: ${lpn}");
          if (lpn == "") {

            showErrorDialog(context, "can't get LPN from the barcode");
            return;
          }
          else {
            _lpnController.text = lpn;
          }
        }

        _enterOnLPNController(10);

      }});

  }

  @override
  void didChangeDependencies() {

    // extract the argument
    Map arguments  = ModalRoute.of(context).settings.arguments as Map ;
    _currentBulkPick = arguments['bulkPick'];

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: Text(CWMSLocalizations.of(context).bulkPick)),
      resizeToAvoidBottomInset: true,
      body:
          Column(
            children: <Widget>[
              buildTwoSectionInformationRow("Work Number:", _currentBulkPick.number),
              buildTwoSectionInformationRow("Location:", _currentBulkPick.sourceLocation.name),
              _buildLocationInput(context),
              _buildLPNInput(context),
              buildTwoSectionInformationRow("Item Number:", _currentBulkPick.item.name),
              buildTwoSectionInformationRow("Pick Quantity:", _currentBulkPick.quantity.toString()),
              _buildQuantityInput(context),
              _buildButtons(context),
            ],
          ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildLocationInput(BuildContext context) {
    return buildTwoSectionInputRow(
        CWMSLocalizations.of(context).location,
      _currentBulkPick.confirmLocationFlag == true || _currentBulkPick.confirmLocationCodeFlag == true ?
          Focus(
              focusNode: _sourceLocationFocusNode,
              child:
              TextFormField(
                  controller: _sourceLocationController,
                  showCursor: true,
                  autofocus: true,
                  focusNode: _sourceLocationControllerFocusNode,
                  decoration: InputDecoration(
                    suffixIcon:
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                      mainAxisSize: MainAxisSize.min, // added line
                      children: <Widget>[
                        IconButton(
                          onPressed: () => _sourceLocationController.text = "",
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                  )

              )
          )
          :
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: Text(_currentBulkPick.item.name, textAlign: TextAlign.left ),
          ),
    );
  }


  Widget _buildLPNInput(BuildContext context) {
    return buildTwoSectionInputRow(
      CWMSLocalizations.of(context).lpn,
        _currentBulkPick.confirmLpnFlag == true ?
      Focus(
          focusNode: _lpnFocusNode,
          child:
          TextFormField(
              controller: _lpnController,
              showCursor: true,
              autofocus: true,
              focusNode: _lpnControllerFocusNode,
              decoration: InputDecoration(
                suffixIcon:
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                  mainAxisSize: MainAxisSize.min, // added line
                  children: <Widget>[
                    IconButton(
                      onPressed: ()  {
                        _lpnController.clear();
                        _quantityController.clear();
                        _lpnControllerFocusNode.requestFocus();
                      },
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
              )

          )
      )
          :
      Container()
    );
  }

  Widget _buildQuantityInput(BuildContext context) {
    return buildTwoSectionInputRow(
        CWMSLocalizations.of(context).quantity,
        Focus(
            focusNode: _quantityFocusNode,
            child:
            TextFormField(
                controller: _quantityController,
                showCursor: true,
                autofocus: true,
                focusNode: _quantityControllerFocusNode,
                decoration: InputDecoration(
                  suffixIcon:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                    mainAxisSize: MainAxisSize.min, // added line
                    children: <Widget>[
                      IconButton(
                        onPressed: () => _quantityController.text = "",
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                )

            )
        )
    );
  }

  Widget _buildButtons(BuildContext context) {

    return buildThreeButtonRow(context,
        ElevatedButton(
            onPressed: () async {

              _onPickConfirm(_currentBulkPick, int.parse(_quantityController.text));
            },
            child: Text(CWMSLocalizations.of(context).confirm)
        ),
        ElevatedButton(
            onPressed: _skipCurrentPick,
            child: Text(CWMSLocalizations.of(context).skip)
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
                )
            ),

        )
      );


  }


  void _enterOnLocationController(int tryTime) async {

    // if the location is empty, then ask the user to input the
    // right location
    if (_sourceLocationController.text.isEmpty) {
      showErrorDialog(context,
          CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).location));
      _sourceLocationControllerFocusNode.requestFocus();
      return;
    }
    printLongLogMessage("_enterOnLocationController: Start to validate source location, tryTime = $tryTime");
    if (tryTime <= 0) {
      // do nothing as we run out of try time
      return;
    }
    printLongLogMessage("_enterOnLocationController / _sourceLocationControllerFocusNode.hasFocus:   ${_sourceLocationControllerFocusNode.hasFocus}");
    if (_sourceLocationControllerFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnLocationController(tryTime - 1));

      return;

    }

    bool locationValid = await _validateSourceLocation();
    if (!locationValid) {
      // validation fail, leave the user in the location control

      showErrorDialog(context, "location " + _sourceLocationController.text + " is invalid");
      _sourceLocationFocusNode.requestFocus();
      return;
    }

  }

  void _enterOnLPNController(int tryTime) async {

    // if the location is empty, then ask the user to input the
    // right location
    if (_lpnController.text.isEmpty) {
      showErrorDialog(context,
          CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).lpn));
      _lpnControllerFocusNode.requestFocus();
      return;
    }
    printLongLogMessage("_enterOnLPNController: Start to validate source location, tryTime = $tryTime");
    if (tryTime <= 0) {
      // do nothing as we run out of try time
      return;
    }
    printLongLogMessage("_enterOnLPNController / _lpnControllerFocusNode.hasFocus:   ${_lpnControllerFocusNode.hasFocus}");
    if (_lpnControllerFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnLPNController(tryTime - 1));

      return;

    }

    showLoading(context);
    int pickableQuantity = await validateLPNByQuantity(_lpnController.text);

    Navigator.of(context).pop();
    if (pickableQuantity == 0) {
      await showBlockedErrorDialog(context, "lpn " + _lpnController.text + " is not pickable");
      _lpnControllerFocusNode.requestFocus();
      return;

    }
    else if (pickableQuantity != _currentBulkPick.quantity - _currentBulkPick.pickedQuantity){

      await showBlockedErrorDialog(context, "lpn " + _lpnController.text + "'s quantity is ${pickableQuantity}," +
          " doesn't match with the picks quantity ${_currentBulkPick.quantity - _currentBulkPick.pickedQuantity}");
      _lpnControllerFocusNode.requestFocus();
      return;
    }
    else {
      // lpn is valid, go to next control
      _quantityController.text = pickableQuantity.toString();
      _quantityFocusNode.requestFocus();
    }

  }

  void _enterOnQuantityController(int tryTime) async {

    // if the location is empty, then ask the user to input the
    // right location
    if (_quantityController.text.isEmpty) {
      showErrorDialog(context,
          CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).quantity));
      _quantityControllerFocusNode.requestFocus();
      return;
    }
    printLongLogMessage("_enterOnQuantityController: Start to validate quantity, tryTime = $tryTime");
    if (tryTime <= 0) {
      // do nothing as we run out of try time
      return;
    }
    printLongLogMessage("_enterOnQuantityController / _quantityControllerFocusNode.hasFocus:   ${_quantityControllerFocusNode.hasFocus}");
    if (_quantityControllerFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnQuantityController(tryTime - 1));

      return;

    }


    _onPickConfirm(_currentBulkPick, int.parse(_quantityController.text));

  }

  Future<int> validateLPNByQuantity(String lpn) async{
    List<Inventory> inventories = [];
    try {
      inventories = await InventoryService.findInventory(
          lpn: lpn,
          locationName: _currentBulkPick.sourceLocation.name
      );
    }
    on WebAPICallException catch(ex) {
      return 0;

    }

    printLongLogMessage("validateLPNByQuantity, lpn: ${lpn}\n found ${inventories.length} inventory record");
    if (inventories.isEmpty) {
      return 0;
    }
    return inventories.map((inventory) => inventory.quantity).reduce((a, b) => a + b);
  }

  void _onPickConfirm(BulkPick bulkPick, int confirmedQuantity) async {

    // over pick for bulk pick is not allowed
    if (confirmedQuantity > _currentBulkPick.quantity - _currentBulkPick.pickedQuantity) {
      showErrorDialog(context,
        CWMSLocalizations.of(context).overPickNotAllowed);
      return;
    }
    // partial pick for bulk pick is not allowed
    if (confirmedQuantity < _currentBulkPick.quantity) {
      showErrorDialog(context,
          CWMSLocalizations.of(context).partailBulkPickNotAllowed);
      return;
    }

    showLoading(context);
    List<Inventory> pickableInventory = [];
    try {
      pickableInventory = await InventoryService.findPickableInventory(
        _currentBulkPick.item.id,
          _currentBulkPick.inventoryStatus.id,
          lpn: _lpnController.text.isNotEmpty ? _lpnController.text : "",
          color: _currentBulkPick.color != null &&  _currentBulkPick.color.isNotEmpty ? _currentBulkPick.color : "",
          productSize: _currentBulkPick.productSize != null && _currentBulkPick.productSize.isNotEmpty ? _currentBulkPick.productSize : "",
          style: _currentBulkPick.style != null && _currentBulkPick.style.isNotEmpty ? _currentBulkPick.style : "",
          locationId: _currentBulkPick.sourceLocationId
      );
      printLongLogMessage("get ${pickableInventory.length} pickable inventory from lpn ${_lpnController.text.isNotEmpty ? _lpnController.text : ""}");
    }
    on WebAPICallException catch(ex) {
      pickableInventory = [];
    }
    if (pickableInventory.isEmpty) {

      Navigator.of(context).pop();
      if (_lpnController.text.isNotEmpty) {

        showErrorDialog(context, "Can't pick from lpn ${_lpnController.text} ");
      }
      else {
        showErrorDialog(context, "fail to pick. please verify the input");
      }
      return;
    }


    try {
      if (bulkPick.confirmLpnFlag && _lpnController.text.isNotEmpty) {
        printLongLogMessage(
            "We will confirm the pick with LPN ${_lpnController.text}");
        await BulkPickService.confirmBulkPick(
            bulkPick, confirmedQuantity, _lpnController.text);
      }
      else {
        printLongLogMessage("We will confirm the pick with specify the LPN");
        await BulkPickService.confirmBulkPick(
            bulkPick, confirmedQuantity);
      }
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

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

  void _skipCurrentPick() {
    _currentBulkPick.skipCount++;
    var pickResult = PickResult.fromJson(
        {'result': true, 'confirmedQuantity': 0});

    Navigator.pop(context, pickResult);

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
    printLongLogMessage("pick.confirmLocationFlag: ${pick.confirmLocationFlag}");
    printLongLogMessage("pick.confirmLocationCodeFlag: ${pick.confirmLocationCodeFlag}");
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

  Future<bool> _validateSourceLocation() async {
    // validate the source location
    if (_sourceLocationController.text.isEmpty) {
      return true;
    }
    showLoading(context);
    WarehouseLocation warehouseLocation;
    try {
      if (_currentBulkPick.confirmLocationCodeFlag) {
        // ok, the pick is required to verify by location code, make sure
        // the user in put a location code
        warehouseLocation =
        await WarehouseLocationService.getWarehouseLocationByCode(
            _sourceLocationController.text
        );
      }
      else {
        warehouseLocation =
        await WarehouseLocationService.getWarehouseLocationByName(
            _sourceLocationController.text
        );
      }
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return false;

    }

    Navigator.of(context).pop();
    if (warehouseLocation == null) {
      showErrorDialog(context, "can't find location by input value ${_sourceLocationController.text}");
      return false;
    }
    else if (warehouseLocation.id != _currentBulkPick.sourceLocationId) {
      showErrorDialog(context, "Location ${_sourceLocationController.text} is not the right location for pick");
      return false;

    }
    return true;
  }


}