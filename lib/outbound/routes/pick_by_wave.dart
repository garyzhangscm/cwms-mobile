
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
import 'package:badges/badges.dart';

import '../../shared/global.dart';
import '../models/pick_mode.dart';
import '../models/wave.dart';
import '../services/wave.dart';
import '../widgets/wave_list_item.dart';


class PickByWavePage extends StatefulWidget{

  PickByWavePage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _PickByWavePageState();

}

class _PickByWavePageState extends State<PickByWavePage> {

  // input batch id
  TextEditingController _waveNumberController = new TextEditingController();
  GlobalKey _formKey = new GlobalKey<FormState>();
  // all picks that assigned to current user
  List<Pick> assignedPicks = [];

  // a map of relationship between wave and pick id
  HashMap wavePicks = new HashMap<String, Set<int>>();
  FocusNode _waveNumberFocusNode = FocusNode();


  List<Wave> assignedWaves = [];


  Pick currentPick;

  List<Inventory>  inventoryOnRF;

  @override
  void initState() {
    super.initState();
    print("Start to initial picks to empty list");
    assignedPicks = [];
    currentPick = null;
    assignedWaves = [];

    inventoryOnRF = [];

    _waveNumberFocusNode.addListener(() {
      print("_waveNumberFocusNode.hasFocus: ${_waveNumberFocusNode.hasFocus}");
      if (!_waveNumberFocusNode.hasFocus && _waveNumberController.text.isNotEmpty) {
        // if we tab out, then add the wave to the list
        _onAddingWave(10);

      }
    });

    _reloadInventoryOnRF();

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).pickByOrder)),
      resizeToAvoidBottomInset: true,
      body:
          Column(
            children: [
              _buildWaveNumberScanner(context),
              _buildButtons(context),
              _buildWaveList(context)
            ],
          ),
      // bottomNavigationBar: buildBottomNavigationBar(context)
      endDrawer: MyDrawer(),
    );
  }

  // scan in barcode to add a order into current batch
  Widget _buildWaveNumberScanner(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(
                  children: <Widget>[
                        TextFormField(
                        controller: _waveNumberController,
                        showCursor: true,
                        autofocus: true,
                        focusNode: _waveNumberFocusNode,
                        decoration: InputDecoration(
                          labelText: CWMSLocalizations.of(context).waveNumber,
                          hintText: "please input wave number",
                          suffixIcon:
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                            mainAxisSize: MainAxisSize.min, // added line
                            children: <Widget>[
                              IconButton(
                                onPressed: () => _waveNumberController.text = "",
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
        buildThreeButtonRow(context,
          ElevatedButton(
              onPressed: () => _onAddingWave(10),
              child: Text(CWMSLocalizations.of(context).addWave)
          ),
          ElevatedButton(
              onPressed: _onStartingPicking,
              child: Text(CWMSLocalizations.of(context).start)
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
        )
      ]
    );


  }


  Widget _buildWaveList(BuildContext context) {

    return
      Expanded(
        child: ListView.separated(
            separatorBuilder: (context, index) => Divider(
              color: Colors.black,
            ),
            itemCount: assignedWaves.length,
            itemBuilder: (BuildContext context, int index) {

              return WaveListItem(
                index: index,
                wave: assignedWaves[index],
                onRemove:  (index) =>  _removeWave(index)
              );
            }),
      );
  }
  void _removeWave(int index) {
    print("will remove for wave: ${assignedWaves[index].number}");
    setState(() {
      // remove the picks first
      _deassignPickFromUser(assignedWaves[index]);
      // remove the order from the user
      assignedWaves.removeAt(index);
    });
  }

  void _onAddingWave(int tryTime) async {

    printLongLogMessage("_onAddingWave: Start to adding wave , tryTime = $tryTime");
    if (tryTime <= 0) {
      // do nothing as we run out of try time
      return;
    }
    printLongLogMessage("_onAddingWave / _waveNumberControllerFocusNode.hasFocus:   ${_waveNumberFocusNode.hasFocus}");
    if (_waveNumberFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _onAddingWave(tryTime - 1));

      return;

    }
    print("Will get information for ${_waveNumberController.text} ");

    // check if hte order is already in the list
    // if so, we won't bother refresh the list
    if (_waveNumberController.text.isNotEmpty &&
        !_waveAlreadyInList(_waveNumberController.text)) {

      showLoading(context);
      try {

        Wave wave =
            await WaveService.getWaveByNumber(_waveNumberController.text);

        if (wave != null) {
          _assignWaveToUser(wave);
          print("Will add wave ${wave.number} to the list");
          _waveNumberController.clear();
          _waveNumberFocusNode.requestFocus();
        }

        Navigator.of(context).pop();
      }
      on WebAPICallException catch(ex) {


        Navigator.of(context).pop();
        showErrorDialog(context, ex.errMsg());
        //_orderNumberFocusNode.requestFocus();
        return;

      }
    }
    else {

      _waveNumberController.clear();
      _waveNumberFocusNode.requestFocus();
    }

  }
  void _assignWaveToUser(Wave wave) {
    // only continue if the order is not in the list yet

    int index = assignedWaves.indexWhere(
            (element) => element.number == wave.number);
    if (index < 0) {

      setState(() {
        assignedWaves.add(wave);
        _assignPickToUser(wave);


      });
    }

  }


  void _assignPickToUser(Wave wave) async {
    print("start to get the picks from wave ${wave.number}");
    List<Pick> picksByWave =  await PickService.getPicksByWave(wave.id);

    printLongLogMessage("get ${picksByWave.length} picks from the wave ${wave.number}");
    assignedPicks.addAll(picksByWave);

    // save the relationship between the wave and the picks so that
    // when we remove the wave from current assignment, we can
    // remove the picks as well
    Set<int> existingPicks = wavePicks[wave.number];
    if (existingPicks == null) {
      existingPicks = new Set<int>();
    }

    picksByWave.forEach((pick) => existingPicks.add(pick.id));
    wavePicks[wave.number] = existingPicks;

    print("_assignPickToUser: Now we have ${assignedPicks.length} picks from ${wavePicks.length} waves assigned");


  }

  void _deassignPickFromUser(Wave wave) {
    // find the pick ids and remove them from the pick list

    Set<int> existingPicks = wavePicks[wave.number];
    existingPicks.forEach((pickId) =>
        assignedPicks.removeWhere((assignedPick) => assignedPick.id == pickId));

    // remove order from the relationship map
    wavePicks.remove(wave.number);
    print("_deassignPickFromUser: Now we have ${assignedPicks.length} picks from ${wavePicks.length} orders deassigned");

  }

  bool _waveAlreadyInList(String waveNumber) {
    return
      assignedWaves.indexWhere((element) => element.number == waveNumber) >= 0;
  }


  void _onStartingPicking() async {


    await this._startPickingForWave();

  }

  _startPickingForWave() async {

    showLoading(context);

    // flow to pick page with the first pick
    currentPick = await _getNextValidPick();
    if (currentPick == null) {

      Navigator.of(context).pop();
      await showBlockedErrorDialog(context, "all picks are done!");
      return;
    }

    // acknowledge the pick so no one else can take it
    try {
        await PickService.acknowledgePick(currentPick.id);
    }
    on WebAPICallException catch(ex) {
        Navigator.of(context).pop();
        showErrorDialog(context, ex.errMsg());
        //_orderNumberFocusNode.requestFocus();
        return;

    }

    // let's find picks from the same wave from same location with same attribute
    // and not assigned or aknowledged yet so that we can assign to the same user
    // for batch pick
    currentPick.batchPickQuantity = 0;
    currentPick.batchedPicks = [];
    for(var pick in  assignedPicks) {

      try {
        // if we have error assign one valid pick, let's just ignore the pick
        // and continue with others
          if (pick.quantity > pick.pickedQuantity && pick.id != currentPick.id &&
              PickService.pickInventoryWithSameAttribute(pick, currentPick)) {
              bool acknowledgeable = await PickService.isPickAcknowledgable(pick.id);
              printLongLogMessage("pick ${pick.number} is acknowledgeable? ${acknowledgeable}");

              if (acknowledgeable) {
                await PickService.acknowledgePick(pick.id);
                currentPick.batchedPicks.add(pick);
                currentPick.batchPickQuantity += (pick.quantity - pick.pickedQuantity);
              }
          }
      }
      on WebAPICallException catch(ex) {

      }
    }

    Navigator.of(context).pop();
    /**
    assignedPicks.forEach((pick) async {
      if (pick.quantity > pick.pickedQuantity &&
          PickService.pickInventoryWithSameAttribute(pick, currentPick)) {
        if (pick.id != currentPick.id) {
          bool acknowledgeable = await PickService.isPickAcknowledgable(pick.id);
          printLongLogMessage("pick ${pick.number} is acknowledgeable? ${acknowledgeable}");

          if (acknowledgeable) {
            currentPick.batchedPicks.add(pick);
            await PickService.acknowledgePick(pick.id);
            currentPick.batchPickQuantity += (pick.quantity - pick.pickedQuantity);
          }
        }
      }

    });
        **/

    // add the main pick if there're other picks can be batched together
    if (currentPick.batchPickQuantity > 0) {
      currentPick.batchPickQuantity += (currentPick.quantity - currentPick.pickedQuantity);
      currentPick.batchedPicks.add(currentPick);
    }

    // setup the batch picked quantity to be the same as pick quantity
    // since we are working on a single pick. In the next pick page,
    // we will use the same logic to handle the batch picking and single pick
    Map argumentMap = new HashMap();
    argumentMap['pick'] = currentPick;
    argumentMap['pickMode'] = PickMode.BY_WAVE;

    final result = await Navigator.of(context).pushNamed("pick", arguments: argumentMap);

    showLoading(context);

    try {
        await PickService.unacknowledgePick(currentPick.id);
        if (currentPick.batchedPicks.length > 0) {
          // assigned the batch picks as well
          currentPick.batchedPicks.forEach((pick) async {
            await PickService.unacknowledgePick(pick.id);
          });
        }
    }
    on WebAPICallException catch(ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      //_orderNumberFocusNode.requestFocus();
      return;

    }

    Navigator.of(context).pop();

    if (result == null) {
      // if the user click the return button instead of confirming
      // let's do nothing
      return;
    }
    var pickResult = result as PickResult;
    print("pick result: ${pickResult.toJson()} for pick: ${currentPick.number}");

    // refresh the orders
    if (pickResult.result == true) {
      /**
      // update the current pick
      currentPick.pickedQuantity
        = currentPick.pickedQuantity + pickResult.confirmedQuantity;
      // update the order's open pick quantity to reflect the
      // pick status
      Wave wave = _getWaveByPick(currentPick);
      if (wave != null) {
        setState(() {

          wave.totalOpenPickQuantity -= pickResult.confirmedQuantity;
          wave.totalPickedQuantity +=  pickResult.confirmedQuantity;
        });
      }
          **/

      // refresh the pick on the RF
      _reloadInventoryOnRF();
      printLongLogMessage(">> pick confirmed successfully, let's start refresh the local pick cache and get the next pick to continue");


      // refresh the pick information locally based on the pick result
      showLoading(context);
      _refreshPickInformation(pickResult);
      Navigator.of(context).pop();
      printLongLogMessage("we successfully loaded all the wave, let's continue picking");
      _startPickingForWave();
    }
    else {

      _reloadInventoryOnRF();
    }

  }

  void  _refreshPickInformation(PickResult pickResult) {

    // refresh the assignedPicks list based on the pick result
    // so that the next valid pick will be based off the latest result
    if (pickResult.confirmedPickResult != null && pickResult.confirmedPickResult.length > 0) {
      printLongLogMessage("We got ${pickResult.confirmedPickResult.length} pick confirm result. let's start to change the local cached pick's quantity");
      for(var pickId in pickResult.confirmedPickResult.keys) {
            var confirmedQuantity = pickResult.confirmedPickResult[pickId];
            for (Pick pick in assignedPicks) {
              if (pick.id == pickId) {
                printLongLogMessage("found pick ${pick.number}, will add ${confirmedQuantity} to its current picked quantity ${pick.pickedQuantity}");
                pick.pickedQuantity += confirmedQuantity;
              }
            }
      }
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

  Wave _getWaveByPick(Pick pick) {
    // Since the pick doesn't have the information of the wave, we will
    // need to get the wave number from the map orderWaves, which
    // is the only place we store the relationship between
    // wave number and pick id

    Wave wave;
    Iterator<MapEntry<String, Set<int>>> wavePickIterator = wavePicks.entries.iterator;
    while(wavePickIterator.moveNext()) {
      MapEntry<String, Set<int>> wavePick = wavePickIterator.current;
      String waveNumber = wavePick.key;
      Set<int> pickIdSet =  wavePick.value;
      // check if the pick belongs to the current wave
      if (pickIdSet.contains(pick.id)) {
        wave = assignedWaves.firstWhere((assignedWave) => assignedWave.number == waveNumber);
        if (wave != null) {
          // we found such order, let's return
          break;
        }
      }

    }

    return wave;
  }


  Future<Pick> _getNextValidPick() async {
    print(" =====   _getNextValidPick      =====");
    assignedPicks.forEach((pick) {
      printLongLogMessage(">> number: ${pick.number} / quantity: ${pick.quantity} / picked quantity: ${pick.pickedQuantity} / skip count: ${pick.skipCount} " +
          "/ source location: ${pick.sourceLocation.name} / pick sequence: ${pick.sourceLocation.pickSequence}");
    });
    if (assignedPicks.isEmpty) {
       return null;
    }
    else {
      // sort the pick first so skipped pick will come last
      printLongLogMessage("start to sort the picks based on rf's current location ${Global.getLastLoginRF().currentLocation.name} with pick sequence ${Global.getLastLoginRF().currentLocation.pickSequence}");
      PickService.sortPicks(assignedPicks, Global.getLastLoginRF().currentLocation, true);

      print(" =====   after sort, we have picks      =====");
      assignedPicks.forEach((pick) {
        printLongLogMessage(">> number: ${pick.number} / quantity: ${pick.quantity} / picked quantity: ${pick.pickedQuantity} / skip count: ${pick.skipCount} " +
            "/ source location: ${pick.sourceLocation.name} / pick sequence: ${pick.sourceLocation.pickSequence}");
      });
      // return the first unacknowleged pick
      for (var pick in assignedPicks.where((pick) => pick.quantity > pick.pickedQuantity)) {
        bool acknowledgeable = await PickService.isPickAcknowledgable(pick.id);
        if (acknowledgeable) {
          return pick;
        }
      }
      // we have a list picks but none of them are available for pick
      return null;

    }
  }

  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the pick on the RF
    _reloadInventoryOnRF();
  }



}