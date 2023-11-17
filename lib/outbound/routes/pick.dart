import 'package:badges/badges.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/models/pick_result.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/pick_mode.dart';


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
  FocusNode _lpnFocusNode = FocusNode();
  FocusNode _lpnControllerFocusNode = FocusNode();
  FocusNode _sourceLocationFocusNode = FocusNode();
  FocusNode _sourceLocationControllerFocusNode = FocusNode();
  FocusNode _quantityFocusNode = FocusNode();
  FocusNode _quantityControllerFocusNode = FocusNode();


  PickMode _pickMode;
  String _workNumber;
  int _lpnQuantity = 0;


  final  _formKey = GlobalKey<FormState>();

  List<Inventory>  inventoryOnRF;

  // if pick to a specific destination LPN
  String _destinationLPN;

  @override
  void initState() {
    super.initState();

    _itemController.clear();
    _sourceLocationController.clear();
    _quantityController.clear();
    _lpnController.clear();
    _destinationLPN = "";
    _workNumber = "";
    _lpnQuantity = 0;


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
        _enterOnLPNController(10);

      }});

    /**
    _quantityFocusNode.addListener(() async {
      printLongLogMessage("_quantityFocusNode hasFocus?: ${_quantityFocusNode.hasFocus}");
      printLongLogMessage("_quantityController text?: ${_quantityController.text}");
      if (!_quantityFocusNode.hasFocus && _quantityController.text.isNotEmpty) {
        _enterOnQuantityController(10);

      }});
**/

  }

  @override
  void didChangeDependencies() {

    // extract the argument
    printLongLogMessage("start to get picks and related mode");
    Map arguments  = ModalRoute.of(context).settings.arguments as Map ;
    _pickMode = arguments['pickMode'];
    printLongLogMessage("_pickMode: $_pickMode");


    _currentPick = arguments['pick'];
    printLongLogMessage("_currentPick: ${_currentPick.toJson()}");
    _destinationLPN  = arguments['destinationLPN'] == null ? "" : arguments['destinationLPN'];
    printLongLogMessage("_destinationLPN: $_destinationLPN");
    _workNumber = arguments['workNumber'] == null || arguments['workNumber'].toString().isEmpty ? _currentPick.number : arguments['workNumber'];
    printLongLogMessage("_workNumber: $_workNumber");

  }

  @override
  Widget build(BuildContext context) {
    // _currentPick  = ModalRoute.of(context).settings.arguments;

    return Scaffold(

      appBar: AppBar(title: Text("CWMS - Pick")),
      resizeToAvoidBottomInset: true,
      body:
          Column(
            children: <Widget>[
              buildTwoSectionInformationRow("Work Number:", _workNumber),
              buildTwoSectionInformationRow("Location:", _currentPick.sourceLocation.name),
              _buildLocationInput(context),
              _buildLPNInput(context),
              buildTwoSectionInformationRow("Item Number:", _currentPick.item.name),
              // add the batch pick quantity only if the quantity to be picked is more than the single pick
              _currentPick.batchPickQuantity > _currentPick.quantity - _currentPick.pickedQuantity ?
                  buildTwoSectionInformationRow("Batch Pick Quantity:", _currentPick.batchPickQuantity.toString()) :
                  buildTwoSectionInformationRow("Pick Quantity:", _currentPick.quantity.toString()),
              buildTwoSectionInformationRow("Picked Quantity:", _currentPick.pickedQuantity.toString()),
              buildTwoSectionInformationRow("Inventory Quantity:", _lpnQuantity.toString()),
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
        _currentPick.confirmLocationFlag == true || _currentPick.confirmLocationCodeFlag == true ?
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
            child: Text(_currentPick.sourceLocation.name, textAlign: TextAlign.left ),
          ),
    );
  }


  Widget _buildLPNInput(BuildContext context) {
    return buildTwoSectionInputRow(
      CWMSLocalizations.of(context).lpn,
      _currentPick.confirmLpnFlag == true ?
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
                      onPressed: () {
                        _lpnController.clear();
                        setState(() {

                          _lpnQuantity = 0;
                        });
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

              _onPickConfirm(_currentPick, int.parse(_quantityController.text));
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
    if (pickableQuantity > 0) {
      // lpn is valid, go to next control
      _quantityController.text = pickableQuantity.toString();
      _quantityFocusNode.requestFocus();

    }
    else {
      await showBlockedErrorDialog(context, "lpn " + _lpnController.text + " is not pickable");
      _lpnControllerFocusNode.requestFocus();
      return;
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


    _onPickConfirm(_currentPick, int.parse(_quantityController.text));

  }

  Future<int> validateLPNByQuantity(String lpn) async{
    List<Inventory> inventories = [];
    try {
      inventories = await InventoryService.findInventory(
          lpn: lpn,
          locationName: _currentPick.sourceLocation.name
      );
    }
    on WebAPICallException catch(ex) {
      return 0;

    }

    printLongLogMessage("validateLPNByQuantity, lpn: ${lpn}\n found ${inventories.length} inventory record");
    if (inventories.isEmpty) {
      return 0;
    }
    // over pick is not allowed so only return the pickable quantity
    setState(() {
      _lpnQuantity = inventories.map((inventory) => inventory.quantity).reduce((a, b) => a + b);
    });
    int openPickQuanity = _currentPick.batchPickQuantity > _currentPick.quantity - _currentPick.pickedQuantity ?
        _currentPick.batchPickQuantity : _currentPick.quantity - _currentPick.pickedQuantity;

    printLongLogMessage("validateLPNByQuantity: _currentPick.batchPickQuantity = ${_currentPick.batchPickQuantity}");
    printLongLogMessage("validateLPNByQuantity: _currentPick.quantity = ${_currentPick.quantity}");
    printLongLogMessage("validateLPNByQuantity: _currentPick.pickedQuantity = ${_currentPick.pickedQuantity}");
    printLongLogMessage("validateLPNByQuantity: openPickQuanity = ${openPickQuanity}");
    printLongLogMessage("validateLPNByQuantity: _lpnQuantity = ${_lpnQuantity}");

    return _lpnQuantity > openPickQuanity ? openPickQuanity : _lpnQuantity;
  }

  void _onPickConfirm(Pick pick, int confirmedQuantity) async {

    // save the result into a local variable as the confirmed quantity
    // will need to be returned.
    // the confirmedQuantity will be split into multiple picks in case of
    // batch pick
    int totalConfirmedQuantity = confirmedQuantity;
    // add the current pick to the top of the batched pick and
    // then loop through each batched pick and process accordingly
    if (pick.batchedPicks == null) {
      pick.batchedPicks = [pick];
    }
    else {
      pick.batchedPicks.insert(0, pick);
    }


    int totalOpenQuantity =
        pick.batchedPicks.map((e) => (e.quantity - e.pickedQuantity) > 0 ? e.quantity - e.pickedQuantity : 0)
            .reduce((a, b) => a + b);

    if (confirmedQuantity > totalOpenQuantity) {
      showErrorDialog(context,
        CWMSLocalizations.of(context).overPickNotAllowed);
      return;
    }

    showLoading(context);
    Iterator<Pick> pickIterator = pick.batchedPicks.iterator;
    Pick currentConfirmedPick;
    int currentConfirmedPickConfirmedQuantity;
    while (confirmedQuantity > 0 && pickIterator.moveNext()) {
      currentConfirmedPick = pickIterator.current;
      currentConfirmedPickConfirmedQuantity = confirmedQuantity > (currentConfirmedPick.quantity - currentConfirmedPick.pickedQuantity) ?
          currentConfirmedPick.quantity - currentConfirmedPick.pickedQuantity : confirmedQuantity;
      printLongLogMessage("start to confirm pick ${currentConfirmedPick.number} with quantity ${currentConfirmedPickConfirmedQuantity}");

      try {
        if (currentConfirmedPick.confirmLpnFlag && _lpnController.text.isNotEmpty) {
          printLongLogMessage(
              "We will confirm the pick with LPN ${_lpnController.text}");
          await PickService.confirmPick(
              currentConfirmedPick, currentConfirmedPickConfirmedQuantity, lpn: _lpnController.text,
              destinationLpn: _destinationLPN);
        }
        else {
          printLongLogMessage("We will NOT confirm the pick with specify the LPN");
          await PickService.confirmPick(
              currentConfirmedPick, currentConfirmedPickConfirmedQuantity,
              destinationLpn: _destinationLPN);
        }
        confirmedQuantity = confirmedQuantity - currentConfirmedPickConfirmedQuantity;
      }
      on WebAPICallException catch(ex) {
        Navigator.of(context).pop();
        showErrorDialog(context, ex.errMsg());
        return;
      }

    }

    print("pick confirmed with total quantity $totalConfirmedQuantity");

    Navigator.of(context).pop();
    showToast("pick confirmed");

    var pickResult = PickResult.fromJson(
        {'result': true, 'confirmedQuantity': totalConfirmedQuantity});

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
    _currentPick.skipCount++;
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

  Future<bool> _validateSourceLocation() async {
    // validate the source location
    if (_sourceLocationController.text.isEmpty) {
      return true;
    }
    showLoading(context);
    WarehouseLocation warehouseLocation;
    try {
      if (_currentPick.confirmLocationCodeFlag) {
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
    else if (warehouseLocation.id != _currentPick.sourceLocationId) {
      showErrorDialog(context, "Location ${_sourceLocationController.text} is not the right location for pick");
      return false;

    }
    return true;
  }


}