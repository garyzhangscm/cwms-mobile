import 'reserve_wave_pick.dart';
import '../../shared/scanning/scan_app_bar.dart';

import 'dart:collection';
import 'dart:core';

import 'package:cwms_mobile/i18n/spanish_ui.dart';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/models/pick_result.dart';
import 'package:cwms_mobile/outbound/routes/pick.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/material.dart';
import 'package:cwms_mobile/shared/workspace_ui.dart';
import 'package:collection/collection.dart';

import '../../shared/global.dart';
import '../models/wave.dart';
import '../services/wave.dart';
import '../widgets/wave_list_item.dart';


class PickByWavePage extends StatefulWidget{

  PickByWavePage({Key? key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _PickByWavePageState();

}

class _PickByWavePageState extends State<PickByWavePage> {

  final _waveNumberController = TextEditingController();
  // all picks that assigned to current user
  List<Pick> assignedPicks = [];

  // a map of relationship between wave and pick id
  HashMap<String, Set<int>> wavePicks = new HashMap();
  final _waveNumberFocusNode = FocusNode();


  List<Wave> assignedWaves = [];


  bool _loadingWave = false;
  String? _waveLookupError;
  Pick? currentPick;

  List<Inventory>  inventoryOnRF = [];

  @override
  void initState() {
    super.initState();
    print("Start to initial picks to empty list");
    assignedPicks = [];
    currentPick = null;
    assignedWaves = [];

    inventoryOnRF = [];

    _reloadInventoryOnRF();

  }

  @override
  void dispose() {
    _waveNumberFocusNode.dispose();
    _waveNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = CWMSLocalizations.of(context);
    final heading = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: workspaceNavy,
          fontWeight: FontWeight.w700,
        );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD8E0ED)),
    );

    return Scaffold(
      backgroundColor: workspaceBackground,
      appBar: ScanAppBar(
        title: Text(labels.pickByWave),
        backgroundColor: workspaceBackground,
        foregroundColor: workspaceNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      endDrawer: MyDrawer(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: border.borderSide,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.qr_code_scanner, color: workspaceBlue),
                            const SizedBox(width: 10),
                            Expanded(child: Text(uiText(context, 'Scan a wave'), style: heading)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(uiText(context, 'Scan the Pick List barcode or enter the wave number.')),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _waveNumberController,
                          autofocus: true,
                          focusNode: _waveNumberFocusNode,
                          textInputAction: TextInputAction.search,
                          onChanged: (_) => _clearWaveLookupError(),
                          onFieldSubmitted: (_) => _onAddingWave(),
                          decoration: InputDecoration(
                            labelText: labels.waveNumber,
                            errorText: _waveLookupError,
                            errorMaxLines: 4,
                            border: border,
                            enabledBorder: border,
                            suffixIcon: IconButton(
                              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                              onPressed: () {
                                _waveNumberController.clear();
                                _clearWaveLookupError();
                                _waveNumberFocusNode.requestFocus();
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: workspaceBlue,
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: _loadingWave ? null : _onAddingWave,
                          child: _loadingWave
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(labels.addWave),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(uiText(context, 'Wave queue'), style: heading),
                const SizedBox(height: 8),
                if (assignedWaves.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(uiText(context, 'No waves in the queue.')),
                  ),
                for (var index = 0; index < assignedWaves.length; index++)
                  WaveListItem(
                    index: index,
                    wave: assignedWaves[index],
                    onRemove: _removeWave,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loadingWave || assignedWaves.isEmpty
                            ? null
                            : _onStartingPicking,
                        child: Text(labels.start, textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: inventoryOnRF.isEmpty ? null : _startDeposit,
                        child: Text(
                          '${labels.depositInventory} (${inventoryOnRF.length})',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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

  void _clearWaveLookupError() {
    if (_waveLookupError != null) {
      setState(() => _waveLookupError = null);
    }
  }

  Future<void> _onAddingWave() async {
    if (_loadingWave) return;
    final number = _waveNumberController.text.trim();
    if (number.isEmpty || _waveAlreadyInList(number)) return;

    setState(() {
      _loadingWave = true;
      _waveLookupError = null;
    });
    try {
      final wave = await WaveService.getWaveByNumber(number);
      if (ReserveWaveApi.available) {
        final state = await ReserveWaveApi(wave.id!).lookup();
        if (!mounted) return;
        if (state != null && state['managed'] == true) {
          _waveNumberController.clear();
          await Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => ReserveWavePickPage(wave: wave, data: state),
          ));
          return;
        }
      }
      final picks = await PickService.getPicksByWave(wave.id!);
      if (!mounted) return;
      setState(() {
        assignedWaves.add(wave);
        assignedPicks.addAll(picks);
        wavePicks[wave.number!] = picks.map((pick) => pick.id!).toSet();
      });
      _waveNumberController.clear();
    } catch (error) {
      if (mounted) {
        setState(() {
          _waveLookupError = uiErrorText(
            context,
            error is WebAPICallException
                ? error.errMsg()
                : ReserveWaveApi.error(error),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingWave = false);
        _waveNumberFocusNode.requestFocus();
      }
    }
  }

  void _deassignPickFromUser(Wave wave) {
    // find the pick ids and remove them from the pick list

    Set<int> existingPicks = wavePicks[wave.number]!;
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
        await PickService.acknowledgePick(currentPick!.id!);
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
    currentPick!.batchPickQuantity = 0;
    currentPick!.batchedPicks = [];
    for(var pick in  assignedPicks) {

      try {
        // if we have error assign one valid pick, let's just ignore the pick
        // and continue with others
          if (pick.quantity! > pick.pickedQuantity! && pick.id != currentPick!.id! &&
              PickService.pickInventoryWithSameAttribute(pick, currentPick!)) {
              bool acknowledgeable = await PickService.isPickAcknowledgable(pick.id!);
              printLongLogMessage("pick ${pick.number} is acknowledgeable? ${acknowledgeable}");

              if (acknowledgeable) {
                await PickService.acknowledgePick(pick.id!);
                currentPick!.batchedPicks.add(pick);
                currentPick!.batchPickQuantity = currentPick!.batchPickQuantity! + (pick.quantity! - pick.pickedQuantity!);
              }
          }
      }
      on WebAPICallException {

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
    if (currentPick!.batchPickQuantity! > 0) {
      currentPick!.batchPickQuantity = currentPick!.batchPickQuantity! + (currentPick!.quantity! - currentPick!.pickedQuantity!);
      currentPick!.batchedPicks.add(currentPick!);
    }

    // setup the batch picked quantity to be the same as pick quantity
    // since we are working on a single pick. In the next pick page,
    // we will use the same logic to handle the batch picking and single pick
    // Map argumentMap = new HashMap();
    // argumentMap['pick'] = currentPick;
    // argumentMap['pickMode'] = PickMode.BY_WAVE;

    // final result = await Navigator.of(context).pushNamed("pick", arguments: argumentMap);

    final result = await Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) =>
                PickPage(
                    currentPick: currentPick!,
                    workNumber: currentPick!.number,
                    assignedPicks: assignedPicks)));

    showLoading(context);

    try {
        await PickService.unacknowledgePick(currentPick!.id!);
        if (currentPick!.batchedPicks.length > 0) {
          // assigned the batch picks as well
          currentPick!.batchedPicks.forEach((pick) async {
            await PickService.unacknowledgePick(pick.id!);
          });
        }
    }
    on WebAPICallException {
      // ignore the error when unackonwledge the orig picks
      // Navigator.of(context).pop();
      // showErrorDialog(context, ex.errMsg());
      //_orderNumberFocusNode.requestFocus();
      // return;

    }

    Navigator.of(context).pop();

    if (result == null) {
      // if the user click the return button instead of confirming
      // let's do nothing
      return;
    }
    var pickResult = result as PickResult;
    print("pick result: ${pickResult.toJson()} for pick: ${currentPick?.number}");

    // refresh the wave
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
    if (pickResult.confirmedPickResult.length > 0) {
      printLongLogMessage("We got ${pickResult.confirmedPickResult.length} pick confirm result. let's start to change the local cached pick's quantity");
      for(var pickId in pickResult.confirmedPickResult.keys) {
            var confirmedQuantity = pickResult.confirmedPickResult[pickId];
            for (Pick pick in assignedPicks) {
              if (pick.id == pickId) {
                printLongLogMessage("found pick ${pick.number}, will add ${confirmedQuantity} to its current picked quantity ${pick.pickedQuantity}");
                pick.pickedQuantity = pick.pickedQuantity! + confirmedQuantity!;
              }
            }
      }
    }
    if (pickResult.cancelledPicks.length > 0) {
      printLongLogMessage("We got ${pickResult.cancelledPicks.length} pick cancelled, let's remove from the available list");
      assignedPicks.removeWhere((pick) => pickResult.cancelledPicks.contains(pick.id));

    }
    if (pickResult.reallocatedPicks.length > 0) {
      printLongLogMessage("We got ${pickResult.reallocatedPicks.length} new picks generated after reallocate, let's added to the list");
      assignedPicks.addAll(pickResult.reallocatedPicks);
    }


  }


  void _reloadInventoryOnRF() {

    InventoryService.getInventoryOnCurrentRF()
        .then((value) {
      if (!mounted) return;
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

    Wave? wave;
    Iterator<MapEntry<String, Set<int>>> wavePickIterator = wavePicks.entries.iterator;
    while(wavePickIterator.moveNext()) {
      MapEntry<String, Set<int>> wavePick = wavePickIterator.current;
      String waveNumber = wavePick.key;
      Set<int> pickIdSet =  wavePick.value;
      // check if the pick belongs to the current wave
      if (pickIdSet.contains(pick.id)) {
        wave = assignedWaves.firstWhereOrNull((assignedWave) => assignedWave.number == waveNumber);
        if (wave != null) {
          // we found such order, let's return
          break;
        }
      }

    }

    return wave!;
  }


  Future<Pick?> _getNextValidPick() async {
    print(" =====   _getNextValidPick      =====");
    assignedPicks.forEach((pick) {
      printLongLogMessage(">> number: ${pick.number} / quantity: ${pick.quantity} / picked quantity: ${pick.pickedQuantity} / skip count: ${pick.skipCount} " +
          "/ source location: ${pick.sourceLocation?.name} / pick sequence: ${pick.sourceLocation?.pickSequence}");
    });
    if (assignedPicks.isEmpty) {
       return null;
    }
    else {
      // sort the pick first so skipped pick will come last
      printLongLogMessage("start to sort the picks based on rf's current location ${Global.getLastLoginRF().currentLocation?.name} with pick sequence ${Global.getLastLoginRF().currentLocation?.pickSequence}");
      PickService.sortPicks(assignedPicks, Global.getLastLoginRF().currentLocation!, true);

      print(" =====   after sort, we have picks      =====");
      assignedPicks.forEach((pick) {
        printLongLogMessage(">> number: ${pick.number} / quantity: ${pick.quantity} / picked quantity: ${pick.pickedQuantity} / skip count: ${pick.skipCount} " +
            "/ source location: ${pick.sourceLocation?.name} / pick sequence: ${pick.sourceLocation?.pickSequence}");
      });
      // return the first unacknowleged pick
      for (var pick in assignedPicks.where((pick) => pick.quantity! > pick.pickedQuantity!)) {
        bool acknowledgeable = await PickService.isPickAcknowledgable(pick.id!);
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