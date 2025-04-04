
import 'dart:collection';
import 'dart:core';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/models/pick_result.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badge;

import '../../shared/global.dart';
import '../models/pick_mode.dart';


class PickByBatchPage extends StatefulWidget{

  PickByBatchPage({Key? key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _PickByBatchPageState();

}

class _PickByBatchPageState extends State<PickByBatchPage> {

  // input batch id
  TextEditingController _pickNumberController = new TextEditingController();
  FocusNode _pickNumberFocusNode = FocusNode();

  List<Pick> _currentPickBatch = [];

  Pick? _currentPick;

  List<Inventory>  inventoryOnRF = [];

  @override
  void initState() {
    super.initState();
    inventoryOnRF = [];

    _currentPickBatch = [];
    _currentPick = null;

    _pickNumberFocusNode.addListener(() {
      print("_pickListNumberFocusNode.hasFocus: ${_pickNumberFocusNode.hasFocus}");
      if (!_pickNumberFocusNode.hasFocus && _pickNumberController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _onAddingPicks();

      }
    });

    _reloadInventoryOnRF();

  }

  @override
  void dispose() {
    super.dispose();
    // for any reason the user return, let's try to unacknowledge the _currentPickList
    if (_currentPickBatch != null && _currentPickBatch.isNotEmpty) {
      _currentPickBatch.forEach((pick) {

        PickService.unacknowledgePick(pick!.id!).then(
                (pick) {
              // _currentPickList= null;
            }).catchError((err) {
          // ignore any error
          printLongLogMessage("error while unacknowledge the pick  ${pick.number}");
        });
      });
    }

  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context)!.pick)),
      resizeToAvoidBottomInset: true,
      body:
          Column(
            children: [
              _buildPickNumberScanner(context),
              _buildButtons(context),
              _buildPickBatchDisplay(context)
            ],
          ),
      // bottomNavigationBar: buildBottomNavigationBar(context)
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildPickNumberScanner(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(
                  children: <Widget>[
                        TextFormField(
                        controller: _pickNumberController,
                        showCursor: true,
                        autofocus: true,
                        focusNode: _pickNumberFocusNode,
                        decoration: InputDecoration(
                          labelText: CWMSLocalizations.of(context)!.pick,
                          hintText: "please input pick number",
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
  Widget _buildButtons(BuildContext context) {

    return Column(
      children: [
        buildTwoButtonRow(context,
            ElevatedButton(
                onPressed: _currentPickBatch != null && _currentPickBatch.isNotEmpty ? _startBatchPicking : null,
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

    if (_currentPickBatch != null && _currentPickBatch.isNotEmpty) {

      _currentPickBatch.forEach((pick) {

        PickService.unacknowledgePick(pick.id!);
      });

      setState(() {

        _currentPickBatch.clear();
      });
    }

    _pickNumberController.clear();
    _pickNumberFocusNode.requestFocus();
  }

  void _onAddingPicks() async {
    if (_pickNumberController.text.isNotEmpty) {
      List<String> pickNumbers = _pickNumberController.text.split(",");
      // printLongLogMessage("start to add picks ${pickNumbers} to the list");

      showLoading(context);
      try {


        for (var pickNumber in pickNumbers) {

          _onAddingPick(pickNumber);
          // printLongLogMessage(" $pickNumber Added!");
        }
        _pickNumberController.clear();
        _pickNumberFocusNode.requestFocus();
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

  void _onAddingPick(String pickNumber) async {

      // if the pick is already added, then do nothing
      if (_currentPickBatch != null && _currentPickBatch.isNotEmpty &&
          _currentPickBatch.any((pick) => pick.number!.trim() == pickNumber.trim())) {
        // ok, the pick is already added in the current batch. then do nothing
        return;
      }

      // printLongLogMessage("start to get pick by number $pickNumber");
        Pick? pick = await PickService.getPicksByNumber(pickNumber);

      // printLongLogMessage("got pick by number ${pick.number}");

        if (pick != null) {
          // acknowledge the pick list so that no one else can work on the same list
          await PickService.acknowledgePick(pick.id!);
          printLongLogMessage("will add ${pick.number} to current batch");
          setState(() {
            _currentPickBatch.add(pick);
          });
        }


  }



  _startBatchPicking() async {


    _currentPick = _getNextValidPick();

    if (_currentPick != null) {

      // printLongLogMessage("start to pick for ${_currentPick.number} with batch quantity ${_currentPick.batchPickQuantity}");
      Map argumentMap = new HashMap();
      argumentMap['pick'] = _currentPick;
      argumentMap['workNumber'] = _currentPick!.number!;
      argumentMap['pickMode'] = PickMode.BY_BATCH;

      final result = await Navigator.of(context).pushNamed("pick", arguments: argumentMap);
      if (result == null) {
        // if the user click the return button instead of confirming
        // let's do nothing
        return;
      }
      var pickResult = result as PickResult;
      print("pick result: ${pickResult.toJson()} for pick: ${_currentPick!.number}");

      // refresh the orders
      if (pickResult.result == true) {
        if (pickResult.confirmedQuantity! > 0) {
          // we will have to update the local instance of pick with the
          // confirmed quantity
          setState(() {

            _currentPick!.pickedQuantity = (_currentPick!.pickedQuantity!  + pickResult.confirmedQuantity!);
          });
          printLongLogMessage("after pick confirm, the picks in the list are ==>");
          _currentPickBatch.forEach((element) {
            printLongLogMessage(">>> number ${element.number}, picked quantity: ${element.pickedQuantity}");
          });
        }
        // continue with next pick in the batch
        _startBatchPicking();
        // refresh the pick on the RF
        _reloadInventoryOnRF();

      }

    }
    else {
      showErrorDialog(context, "No more picks left in the batch");
      // _clear();
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
    _currentPickBatch.forEach((pick) {
      print(">> ${pick.number} / ${pick.quantity} / ${pick.pickedQuantity} / ${pick.skipCount}");
    });
    if (_currentPickBatch.isEmpty) {
       return null;
    }
    else {
      // sort the pick first so skipped pick will come last

      PickService.sortPicks(_currentPickBatch, Global.getLastActivityLocation(), Global.isMovingForward());
      // get the first available pick and then group the quantity all together from the same location, for the same
      // inventory
      _currentPick = _currentPickBatch.firstWhere((pick) => pick.quantity! > pick!.pickedQuantity!);
      if (_currentPick != null) {
        // Batch picking means we will group all picks but we won't do
        // the actual batch picking in the location. Instead, if the user would like to do a batch picking
        // we suggest to use list pick instead of just group picks into the list
        _currentPick!.batchPickQuantity = _currentPick!.quantity! - _currentPick!.pickedQuantity!;
        _currentPick!.batchedPicks = [];
        /**
        _currentPickBatch.forEach((pick) {
          if (pick.quantity > pick.pickedQuantity && PickService.pickInventoryWithSameAttribute(pick, _currentPick)) {
            _currentPick.batchPickQuantity += (pick.quantity - pick.pickedQuantity);
            if (pick.id != _currentPick.id) {
              _currentPick.batchedPicks.add(pick);
            }
          }
        });
            **/
      }
      return _currentPick;
    }
  }


  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the pick on the RF
    _reloadInventoryOnRF();
  }

  Widget _buildPickBatchDisplay(BuildContext context) {
    return
      Expanded(
          child: ListView.separated(
            itemCount: _currentPickBatch.length,
            itemBuilder: (BuildContext context, int index) {

              return _buildPickBatchListTile(context, index);
            },
            separatorBuilder: (context, index) => Divider(
              color: Colors.black,
            ),
          )
      );
  }

  Widget _buildPickBatchListTile(BuildContext context, int index) {

    printLongLogMessage("start to show list with index $index");
    printLongLogMessage("_currentPickBatch's size is ${_currentPickBatch.length}");
    printLongLogMessage("_currentPickBatch[index].quantity? ${_currentPickBatch[index].quantity}");
    printLongLogMessage("_currentPickBatch[index].pickedQuantity? ${_currentPickBatch[index].pickedQuantity}");
    return
        SizedBox(
            height: 75,
            child:
            ListTile(
              title: Text(CWMSLocalizations.of(context)!.pick + ": " + _currentPickBatch[index]!.number!),
              subtitle:
                Column(
                  children: <Widget>[
                    Row(
                        children: <Widget>[
                          Text(
                              CWMSLocalizations.of(context)!.item + ": ",
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                          Text(
                              _currentPickBatch[index].item?.name ?? "",
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                        ]
                    ),
                    Row(
                        children: <Widget>[
                          Text(
                              CWMSLocalizations.of(context)!.quantity + ": ",
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                          Text(
                              (_currentPickBatch[index].quantity! - _currentPickBatch[index]!.pickedQuantity!).toString(),
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                        ]
                    ),
                    Row(
                        children: <Widget>[
                          Text(
                              CWMSLocalizations.of(context)!.location + ": ",
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                          Text(
                              _currentPickBatch[index].sourceLocation?.name ?? "",
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                        ]
                    ),

                  ]
              ),
              trailing:
                IconButton(
                  onPressed: () => _removePickFromBatch(index),
                  icon: Icon(Icons.close),
                ),
              tileColor: _currentPickBatch[index].quantity! > _currentPickBatch[index]!.pickedQuantity! ?
                  Colors.lightGreen : Colors.white38,
            )
        );
  }

  Future<void> _removePickFromBatch(int index) async {
    Pick pick = _currentPickBatch[index];
    setState(() {

      _currentPickBatch.removeAt(index);
    });
    showLoading(context);
    try {

      await PickService.unacknowledgePick(pick.id!);
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      // ignore the error
      return;

    }

    Navigator.of(context).pop();
  }

}