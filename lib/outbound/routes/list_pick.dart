import 'dart:math';

import 'package:badges/badges.dart' as badge;
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/models/pick_result.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/outbound/services/pick_list.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/material.dart';

import '../../shared/global.dart';
import '../models/pick_list.dart';

import '../../shared/services/barcode_service.dart';
import '../../shared/models/barcode.dart';

/**
 * Obsoleted! please use PickByListPage for list pick
 */
class ListPickPage extends StatefulWidget{

  ListPickPage({Key? key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _ListPickPageState();

}

class _ListPickPageState extends State<ListPickPage> {

  // input batch id
  TextEditingController _itemController = new TextEditingController();
  TextEditingController _sourceLocationController = new TextEditingController();
  TextEditingController _quantityController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();

  int _totalConfirmedQuantity = 0;

  PickList? _currentPickList;
  Pick? _currentPick;

  FocusNode _lpnFocusNode = FocusNode();
  FocusNode _lpnControllerFocusNode = FocusNode();
  FocusNode _sourceLocationFocusNode = FocusNode();
  FocusNode _sourceLocationControllerFocusNode = FocusNode();
  FocusNode _quantityFocusNode = FocusNode();
  FocusNode _quantityControllerFocusNode = FocusNode();


  List<Inventory>  inventoryOnRF = [];

  @override
  void initState() {
    super.initState();

    _itemController.clear();
    _sourceLocationController.clear();
    _quantityController.clear();
    _lpnController.clear();
    _totalConfirmedQuantity = 0;

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
        // allow the user to input barcode

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


    Future.delayed(Duration.zero, () {
      // extract the argument
      printLongLogMessage("=========== initState ==========");
      Map arguments  = ModalRoute.of(context)?.settings.arguments as Map ;


      _currentPickList = arguments['pickList'];
      _totalConfirmedQuantity = 0;
      // get the next pick from the list
      getNextPick();
    });
  }
/**
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // extract the argument
    printLongLogMessage("=========== didChangeDependencies ==========");
    Map arguments  = ModalRoute.of(context).settings.arguments as Map ;
    _pickMode = arguments['pickMode'];

    _currentPickList = arguments['pickList'];
    _totalConfirmedQuantity = 0;
    // get the next pick from the list
    getNextPick();

  }
**/
  void returnToPreviewPage() {

    var pickResult = PickResult.fromJson(
        {'result': true, 'confirmedQuantity': _totalConfirmedQuantity});

    // refresh the pick on the RF
    // _reloadInventoryOnRF();


    Navigator.pop(context, pickResult);
  }

  /// Get the next pick from the list
  Future<Pick?> getNextPick() async {
    if (_currentPickList == null) {
      return null;
    }
    if (_currentPickList?.picks.isEmpty == true) {
      return null;
    }
    /**
    printLongLogMessage("_currentPickList.picks.length? : ${_currentPickList.picks.length}");
    _currentPickList.picks.forEach((pick) {

      printLongLogMessage(">> pick ${pick.number}, pick quantity： ${pick.quantity}, picked quantity: ${pick.pickedQuantity}");
    });
        **/

    // sort the picks
    PickService.sortPicks(_currentPickList!.picks, Global.getLastActivityLocation(), Global.isMovingForward());


    setState(() {

      // return the first pick that has open quantity
      _currentPick = _currentPickList?.picks.firstWhere((pick) => pick.quantity! > pick.pickedQuantity!);
    });
    if (_currentPick == null) {
      // there's no available pick in the list, show message and return
      await showDialog(
            context: context,
            builder: (context) {
          return
            AlertDialog(
              title: Text(""),
              content: Text("current list ${_currentPickList?.number} is done"),
              actions: <Widget>[

                ElevatedButton(
                  child: Text("Confirm"),
                  onPressed: () {
                    Navigator.of(context).pop(true); //关闭对话框
                    returnToPreviewPage();
                  },
                ),
              ],
            );
        }
      );
    }
    else if (Global.getRFConfiguration.listPickBatchPicking) {
      // if we will need to batch picking, then combine the picks with
      // same attribute into one and allow the user to batch picking
      setState(() {

        _currentPick = getPickBatch(_currentPick!, _currentPickList!);
      });
    }
    
    // printLongLogMessage("_currentPick: ${_currentPick.toJson()}");
    // _lpnControllerFocusNode.requestFocus();
    return _currentPick;
  }

  // get picking batch from the list, with picks that
  // similar to the current pick
  Pick getPickBatch(Pick pick, PickList pickList) {
    // get all the pick that has same inventory attribute as the
    // current pick
    List<Pick> similarPicks = pickList.picks.where((anotherPick) {
        // skip the current pick
        if (anotherPick.id == pick.id) {
          return false;
        }
        // skip the fully picked pick
        if (anotherPick.pickedQuantity! >= anotherPick.quantity!) {
          return false;
        }
        if (PickService.pickInventoryWithSameAttribute(pick, anotherPick)) {
          return true;
        }
        return false;
    }).toList();
    if (similarPicks.isEmpty) {
      // ok, we didn't find any pick that can be combined , let's return the
      // original pick
      return pick;
    }
    // ok, we find some picks that we can combine into the original pick
    // let's create a new pick structure
    Pick combinedPick = Pick.clone(pick);
    // set the pick's number to empty
    combinedPick.number = "**MIX**";
    combinedPick.destinationLocationId = null;
    combinedPick.destinationLocation = null;
    similarPicks.forEach((similarPick) {
      combinedPick.pickedQuantity = combinedPick.pickedQuantity! + similarPick.pickedQuantity!;
      combinedPick.quantity = combinedPick.quantity! + similarPick.quantity!;
      // set the inventory attribute to be the most specific one
      if (combinedPick.color == null || combinedPick.color?.isNotEmpty == true) {
        combinedPick.color = similarPick.color;
      }
      if (combinedPick.productSize == null || combinedPick.productSize?.isNotEmpty == true) {
        combinedPick.productSize = similarPick.productSize;
      }
      if (combinedPick.style == null || combinedPick.style?.isNotEmpty == true) {
        combinedPick.style = similarPick.style;
      }
      if (combinedPick.allocateByReceiptNumber == null || combinedPick.allocateByReceiptNumber?.isNotEmpty == true) {
        combinedPick.allocateByReceiptNumber = similarPick.allocateByReceiptNumber;
      }
    });
    return combinedPick;

  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: Text(CWMSLocalizations.of(context)!.listPick)),
      resizeToAvoidBottomInset: true,
      body:
          Column(
            children: <Widget>[
              buildTwoSectionInformationRow("List Number:", _currentPickList?.number ?? ""),
              buildTwoSectionInformationRow("Pick Number:", _currentPick?.number ?? ""),
              buildTwoSectionInformationRow("Location:", _currentPick?.sourceLocation?.name ?? ""),
              _currentPick == null ? Container() : _buildLocationInput(context),
              _currentPick == null ? Container() : _buildLPNInput(context),
              buildTwoSectionInformationRow("Item Number:",  _currentPick?.item?.name ?? ""),
              buildTwoSectionInformationRow("Pick Quantity:", _currentPick?.quantity.toString() ?? ""),
              _currentPick == null ? Container() : _buildQuantityInput(context),
              _buildButtons(context),
            ],
          ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildLocationInput(BuildContext context) {
    return buildTwoSectionInputRow(
        CWMSLocalizations.of(context)!.location,
      _currentPick?.confirmLocationFlag == true || _currentPick?.confirmLocationCodeFlag == true ?
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
            child: Text(_currentPick?.item?.name ?? "", textAlign: TextAlign.left ),
          ),
    );
  }


  Widget _buildLPNInput(BuildContext context) {
    return buildTwoSectionInputRow(
      CWMSLocalizations.of(context)!.lpn,
        _currentPick?.confirmLpnFlag == true ?
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
                        _itemController.clear();
                        _sourceLocationController.clear();
                        _quantityController.clear();
                        _lpnController.clear();
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
        CWMSLocalizations.of(context)!.quantity,
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

              _onPickConfirm(_currentPickList!, int.parse(_quantityController.text));
            },
            child: Text(CWMSLocalizations.of(context)!.confirm)
        ),
        ElevatedButton(
            onPressed: _skipCurrentPick,
            child: Text(CWMSLocalizations.of(context)!.skip)
        ),
        badge.Badge(
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
                  child: Text(CWMSLocalizations.of(context)!.depositInventory),
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
          CWMSLocalizations.of(context)!.missingField(CWMSLocalizations.of(context)!.location));
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
          CWMSLocalizations.of(context)!.missingField(CWMSLocalizations.of(context)!.lpn));
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
    pickableQuantity = min(pickableQuantity, _currentPick!.quantity! - _currentPick!.pickedQuantity!);

    Navigator.of(context).pop();
    if (pickableQuantity > 0) {
      // lpn is valid, go to next control
      _quantityController.text = pickableQuantity.toString();
      _quantityFocusNode.requestFocus();

    }
    else {
      await showBlockedErrorDialog(context, "lpn " + _lpnController.text + " is not pickable, "
          "please make sure the LPN is in the right place");
      _lpnControllerFocusNode.requestFocus();
      return;
    }

  }


  Future<int> validateLPNByQuantity(String lpn) async{
    List<Inventory> inventories = [];
    try {
      inventories = await InventoryService.findPickableInventory(
        _currentPick!.itemId!, _currentPick!.inventoryStatusId!,
          lpn: lpn,
          color: _currentPick?.color ?? "",
        productSize: _currentPick?.productSize  ?? "",
        style: _currentPick?.style  ?? "",
        receiptNumber: _currentPick?.allocateByReceiptNumber  ?? "",
          locationId: _currentPick?.sourceLocationId
      );
    }
    on WebAPICallException catch(ex) {
      return 0;

    }

    printLongLogMessage("validateLPNByQuantity, lpn: ${lpn}\n found ${inventories.length} inventory record");
    return inventories.map((inventory) => inventory.quantity).reduce((a, b) => a! + b!) ?? 0;
  }

  void _onPickConfirm(PickList pickList, int confirmedQuantity) async {

    int totalPickableQuantity = 0 ;
    pickList.picks.forEach((pick) {
      totalPickableQuantity += (pick.quantity! - pick!.pickedQuantity!);
    });

    // over pick for bulk pick is not allowed
    if (confirmedQuantity > totalPickableQuantity) {
      showErrorDialog(context,
        CWMSLocalizations.of(context)!.overPickNotAllowed);
      return;
    }

    showLoading(context);

    try {
      if (_lpnController.text.isNotEmpty) {
        _currentPickList = await PickListService.confirmPickList(
            pickList, confirmedQuantity, _currentPick!.sourceLocationId!,  _lpnController.text);
      }
      else {
        printLongLogMessage("We will confirm the pick with specify the LPN");
        _currentPickList = await PickListService.confirmPickList(
            pickList, confirmedQuantity, _currentPick!.sourceLocationId!);
      }
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());

      return;

    }
    _totalConfirmedQuantity += confirmedQuantity;

    print("pick confirmed");
    /**
    _currentPickList.picks.forEach((pick) {

      printLongLogMessage(">> 2. pick ${pick.number}, pick quantity： ${pick.quantity}, picked quantity: ${pick.pickedQuantity}");
    });
        **/

    Navigator.of(context).pop();
    showToast("pick confirmed");

    // clear the input
    _lpnController.clear();
    _quantityController.clear();


    // refresh the display after we complete one location / LPN
    // their may be more locations / LPN to pick from
    getNextPick();

    _lpnControllerFocusNode.requestFocus();

    /**
    var pickResult = PickResult.fromJson(
        {'result': true, 'confirmedQuantity': confirmedQuantity});

    // refresh the pick on the RF
    // _reloadInventoryOnRF();


    Navigator.pop(context, pickResult);
        **/
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
    _currentPick!.skipCount = _currentPick!.skipCount! + 1;

    getNextPick();

  }

  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the pick on the RF
    _reloadInventoryOnRF();
  }

  setupControllers(Pick pick) {

    if(pick.confirmItemFlag == false) {
      _itemController.text = pick.item?.name ?? "";
    }
    // printLongLogMessage("pick.confirmLocationFlag: ${pick.confirmLocationFlag}");
    // printLongLogMessage("pick.confirmLocationCodeFlag: ${pick.confirmLocationCodeFlag}");
    if (pick.confirmLocationFlag == false &&
        pick.confirmLocationCodeFlag == false) {
      _sourceLocationController.text = pick.sourceLocation?.name ?? "";
    }
    if (pick!.quantity! > pick!.pickedQuantity!) {

      _quantityController.text = (pick.quantity! - pick!.pickedQuantity!).toString();
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
      if (_currentPick?.confirmLocationCodeFlag == true) {
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
    else if (warehouseLocation.id != _currentPick?.sourceLocationId) {
      showErrorDialog(context, "Location ${_sourceLocationController.text} is not the right location for pick");
      return false;

    }
    return true;
  }


}