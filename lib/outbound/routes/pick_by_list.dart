
import 'dart:collection';
import 'dart:core';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/models/pick_list.dart';
import 'package:cwms_mobile/outbound/models/pick_result.dart';
import 'package:cwms_mobile/outbound/services/order.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/outbound/services/pick_list.dart';
import 'package:cwms_mobile/outbound/widgets/order_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/bottom_navigation_bar.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:badges/badges.dart' as badge;

import '../../shared/global.dart';
import '../models/pick_mode.dart';


class PickByListPage extends StatefulWidget{

  PickByListPage({Key? key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _PickByListPageState();

}

class _PickByListPageState extends State<PickByListPage> {

  // input batch id
  TextEditingController _pickListNumberController = new TextEditingController();
  FocusNode _pickListNumberFocusNode = FocusNode();

  TextEditingController _newLPNNumberController = new TextEditingController();
  FocusNode _newLPNNumberFocusNode = FocusNode();

  PickList? _currentPickList;
  String? _currentDestinationLPN;
  // if the list contains partial LPN pick, then we will require the
  // user to input a new LPN so that the partial LPN picks can pick into
  // this new LPN
  bool? _requireNewLPN;

  // whether we retain the LPN for a whole LPN pick
  bool? _retainLPNForLPNPick;

  Pick? _currentPick;

  List<Inventory>  inventoryOnRF = [];

  @override
  void initState() {
    super.initState();
    inventoryOnRF = [];

    _currentPickList = null;
    _currentPick = null;
    _currentDestinationLPN = "";
    _requireNewLPN = true;
    _retainLPNForLPNPick = true;

    _pickListNumberFocusNode.addListener(() {
      print("_pickListNumberFocusNode.hasFocus: ${_pickListNumberFocusNode.hasFocus}");
      if (!_pickListNumberFocusNode.hasFocus && _pickListNumberController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _onAddingPickList();

      }
    });
    _newLPNNumberFocusNode.addListener(() {
      print("_newLPNNumberFocusNode.hasFocus: ${_newLPNNumberFocusNode.hasFocus}");
      if (!_newLPNNumberFocusNode.hasFocus && _newLPNNumberController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _onAddingNewLPN();

      }
    });

    _reloadInventoryOnRF();

  }

  @override
  void dispose() {
    super.dispose();
    // for any reason the user return, let's try to unacknowledge the _currentPickList
    if (_currentPickList != null) {
      PickListService.unacknowledgePickList(_currentPickList!.id!).then(
          (pickList) {
              // _currentPickList= null;
      }).catchError((err) {
        // ignore any error
        printLongLogMessage("error while unacknowledge the pick list ${_currentPickList?.number}");
      });
    }

  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context)!.listPick)),
      resizeToAvoidBottomInset: true,
      body:
          Column(
            children: [
              _buildPickListNumberScanner(context),
              _buildLPNNumberScanner(context),
              _buildRetainLPNCheckBox(context),
              _buildButtons(context),
            ],
          ),
      // bottomNavigationBar: buildBottomNavigationBar(context)
      endDrawer: MyDrawer(),
    );
  }



  Widget _buildPickListNumberScanner(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(
                  children: <Widget>[
                        TextFormField(
                        controller: _pickListNumberController,
                        showCursor: true,
                        autofocus: true,
                        focusNode: _pickListNumberFocusNode,
                        decoration: InputDecoration(
                          labelText: CWMSLocalizations.of(context)!.pickList,
                          hintText: "please input pick list",
                          suffixIcon:
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                            mainAxisSize: MainAxisSize.min, // added line
                            children: <Widget>[
                              IconButton(
                                onPressed: () => _clear(),
                                icon: Icon(Icons.close),
                              ),
                            ],
                          ),
                        )

                    )
                  ]
              )
          );

  }
  Widget _buildLPNNumberScanner(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.all(16.0),
          child:
          Column(
              children: <Widget>[
                TextFormField(
                    controller: _newLPNNumberController,
                    showCursor: true,
                    autofocus: true,
                    focusNode: _newLPNNumberFocusNode,
                    decoration: InputDecoration(
                      labelText: CWMSLocalizations.of(context)!.lpn,
                      hintText: "please input a new lpn",
                      suffixIcon:
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                        mainAxisSize: MainAxisSize.min, // added line
                        children: <Widget>[
                          IconButton(
                            onPressed: () => _clear(),
                            icon: Icon(Icons.close),
                          ),
                        ],
                      ),
                    )

                )
              ]
          )
      );

  }

  Widget _buildRetainLPNCheckBox(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.all(16.0),
          child:
          Column(
              children: <Widget>[Row(
                  children: <Widget>[

                    Checkbox(
                      value: _retainLPNForLPNPick,
                      activeColor: Colors.blue, //选中时的颜色
                      onChanged:(value){
                        //重新构建页面
                        setState(() {
                          _retainLPNForLPNPick=value;
                        });
                      },

                    ),
                    Text("Retain LPN for LPN Pick"),

                  ]
              ),
              ]
          )
      );

  }

  Widget _buildButtons(BuildContext context) {

    return Column(
      children: [
        buildTwoButtonRow(context,
            ElevatedButton(
                onPressed: _currentPickList != null && (_requireNewLPN == false || _currentDestinationLPN?.isNotEmpty == true)
                    ? _startPickingForPick : null,
                child: Text(CWMSLocalizations.of(context)!.start)
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
                ),
              ),
            )
        )
      ],
    );


  }
  void _clear() {

    if (_currentPickList != null) {

      PickListService.unacknowledgePickList(_currentPickList!.id!);
      _currentPickList = null;
    }

    _newLPNNumberController.clear();
    _pickListNumberController.clear();
    _pickListNumberFocusNode.requestFocus();
  }

  void _onAddingPickList() async {

    _currentPickList = null;
    if (_pickListNumberController.text.isNotEmpty ) {

      showLoading(context);
      try {

        _currentPickList = await PickListService.getPickListByNumber(_pickListNumberController.text);

        if (_currentPickList != null) {
          // acknowledge the pick list so that no one else can work on the same list
          await PickListService.acknowledgePickList(_currentPickList!.id!);
        }
        _requireNewLPN = _checkNewLPNRequirement(_currentPickList!);

        setState(() {
        });
        Navigator.of(context).pop();
        _newLPNNumberFocusNode.requestFocus();
      }
      on WebAPICallException catch(ex) {


        Navigator.of(context).pop();
        showErrorDialog(context, ex.errMsg());
        //_orderNumberFocusNode.requestFocus();
        return;

      }
    }
  }

  // check if the pick list requires a new LPN
  // if the pick list contains any non whole LPN pick,
  // then we will requires a new LPN so that the partail LPN
  // pick can pick into this new LPN
  bool _checkNewLPNRequirement(PickList pickList) {
    return pickList.picks.any((pick) => pick.wholeLPNPick == false);
  }

  void _onAddingNewLPN() async {


    _currentDestinationLPN = "";
    // make sure the LPN is a new LPN or an LPN that in the current RF
    if (_newLPNNumberController.text.isNotEmpty ) {

      showLoading(context);
      try {

        List<Inventory> inventoryList = await InventoryService.findInventory(lpn: _newLPNNumberController.text, includeDetails: false);

        if (inventoryList == null || inventoryList.isEmpty) {
          // OK, this LPN is a new LPN, we will still need to make sure the new LPN has the right format
          String errorMessage = await InventoryService.validateNewLpn(_newLPNNumberController.text);
          if (errorMessage.isNotEmpty) {
            Navigator.of(context).pop();
            showErrorDialog(context, errorMessage);
            return;
          }
          _currentDestinationLPN = _newLPNNumberController.text;

        }
        else {

          _currentDestinationLPN = _newLPNNumberController.text;
        }

        setState(() {
        });
        Navigator.of(context).pop();
      }
      on WebAPICallException catch(ex) {

        Navigator.of(context).pop();
        showErrorDialog(context, ex.errMsg());
        //_orderNumberFocusNode.requestFocus();
        return;

      }
    }
  }


  _startPickingForPick() async {


    _currentPick = _getNextValidPick();

    if (_currentPick != null) {

      printLongLogMessage("start to pick for ${_currentPick?.number} with batch quantity ${_currentPick?.batchPickQuantity}");
      Map argumentMap = new HashMap();
      argumentMap['pick'] = _currentPick;
      argumentMap['workNumber'] = _currentPickList!.number;
      argumentMap['pickMode'] = PickMode.BY_LIST;
      argumentMap['destinationLPN'] = _currentDestinationLPN;

      final result = await Navigator.of(context).pushNamed("pick", arguments: argumentMap);
      if (result == null) {
        // if the user click the return button instead of confirming
        // let's do nothing
        return;
      }
      var pickResult = result as PickResult;
      print("pick result: $pickResult for pick: ${_currentPick?.number}");

      // refresh the orders
      if (pickResult.result == true) {
        // refresh the list and get the next pick
        showLoading(context);
        try {
          _currentPickList = await PickListService.getPickListByNumber(_pickListNumberController.text);
          Navigator.of(context).pop();
          _startPickingForPick();
        }
        on WebAPICallException catch(ex) {

          Navigator.of(context).pop();
          showErrorDialog(context, ex.errMsg());
          //_orderNumberFocusNode.requestFocus();
          return;

        }
        // refresh the pick on the RF
        _reloadInventoryOnRF();

      }

    }
    else {
      showErrorDialog(context, "No more picks left in the list");
      _clear();
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


  Pick? _getNextValidPick() {
    print(" =====   _getNextValidPick      =====");
    _currentPickList!.picks.forEach((pick) {
      print(">> ${pick.number} / ${pick.quantity} / ${pick.pickedQuantity} / ${pick.skipCount}");
    });
    if (_currentPickList!.picks.isEmpty) {
       return null;
    }
    else {
      // sort the pick first so skipped pick will come last

      PickService.sortPicks(_currentPickList!.picks, Global.getLastActivityLocation(), Global.isMovingForward());
      // get the first available pick and then group the quantity all together from the same location, for the same
      // inventory
      _currentPick = _currentPickList!.picks.firstWhere((pick) => pick.quantity! > pick!.pickedQuantity!);
      if (_currentPick != null) {
        _currentPick!.batchPickQuantity = 0;
        _currentPick!.batchedPicks = [];
        _currentPickList!.picks.forEach((pick) {
          if (pick.quantity! > pick!.pickedQuantity! && PickService.pickInventoryWithSameAttribute(pick, _currentPick!)) {
            _currentPick?.batchPickQuantity = _currentPick!.batchPickQuantity! + (pick.quantity! - pick.pickedQuantity!);
            if (pick.id != _currentPick!.id!) {
              _currentPick!.batchedPicks.add(pick);
            }
          }
        });
      }
      return _currentPick;
    }
  }


  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the pick on the RF
    _reloadInventoryOnRF();
  }



}