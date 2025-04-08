import 'dart:async';
import 'dart:collection';
import 'package:collection/collection.dart';

import 'package:badges/badges.dart' as badge;
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/outbound/models/bulk_pick.dart';
import 'package:cwms_mobile/outbound/models/pick_mode.dart';
import 'package:cwms_mobile/outbound/services/bulk_pick.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/work/models/work-task-type.dart';
import 'package:cwms_mobile/work/models/work_task.dart';
import 'package:cwms_mobile/work/services/work_task_service.dart';
import 'package:flutter/material.dart';

import '../../outbound/models/pick.dart';
import '../../outbound/models/pick_list.dart';
import '../../outbound/services/pick_list.dart';
import '../../shared/global.dart';


class SystemDrivenWork extends StatefulWidget{

  SystemDrivenWork({Key? key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _SystemDrivenWorkState();

}

class _SystemDrivenWorkState extends State<SystemDrivenWork> {

  WorkTask? _currentWorkTask;
  List<Inventory>  _inventoryOnRF = [];

  Timer? _timer;  // timer to load the next work every 10 second

  String _currentWorkTaskSourceLocationName = "";

  @override
  void dispose() {
    super.dispose();
    // remove any timer so we won't need to load the next work again after
    // the user return from this page
    _timer?.cancel();

    if (_currentWorkTask != null) {
      printLongLogMessage("we will need to unaknowledge the current work task ${_currentWorkTask!.number}");
      WorkTaskService.unacknowledgeWorkTask(_currentWorkTask!, false).then((value) =>
          printLongLogMessage("Current work task ${_currentWorkTask!.number} is unaknowledged")
      );
    }

  }

  @override
  void initState() {
    super.initState();

    _inventoryOnRF = [];

    _reloadInventoryOnRF();

    _currentWorkTask = null;
    _currentWorkTaskSourceLocationName = "";
    _timer = Timer(Duration.zero, () {
      this._getNextWorkTask();
    });
    /**
    Future.delayed(Duration.zero, () {
      this._getNextWorkTask();
    });
**/

  }

  _getNextWorkTask() {
    printLongLogMessage("Start to get the next work");
    // showLoading(context);
    printLongLogMessage("SHOWN loading");

    try {

      WorkTaskService.getNextWorkTask().then((nextWorkTask) {

        if (nextWorkTask == null) {
          printLongLogMessage("there's no available work task, let's try again every 10 second");
          _timer = Timer(new Duration(seconds: 10), () {
            // Navigator.of(context).pop();
            this._getNextWorkTask();
          });
          /**
          Future.delayed(new Duration(seconds: 10), () {
            Navigator.of(context).pop();
            this._getNextWorkTask();
          });
              **/
        }
        else {
          printLongLogMessage("start to work on the task ${nextWorkTask.number}");
          // Navigator.of(context).pop();
          setState(() {

            _currentWorkTask = nextWorkTask;
          });
          _setupWorkTaskSourceLocationName();
        }
      });
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(title: Text("CWMS - System Driven Work")),
      resizeToAvoidBottomInset: true,
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          // autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[
              _buildDisplay(context),
              _buildButtons(context)
            ],
          ),
      ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildDisplay(BuildContext context) {

    return SizedBox(
        height: 105,
        child:  Stack(
          alignment:Alignment.center ,
          fit: StackFit.expand, //未定位widget占满Stack整个空间
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 10),
                child: IntrinsicHeight(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(children: [
                            buildTwoSectionInformationRow(CWMSLocalizations.of(context)!.number,
                                 _currentWorkTask?.number ?? ""),
                            buildTwoSectionInformationRow(CWMSLocalizations.of(context)!.type,
                                _currentWorkTask?.type?.name ?? ""),
                            buildTwoSectionInformationRow(CWMSLocalizations.of(context)!.sourceLocation, _currentWorkTaskSourceLocationName),
                          ]),
                        ),
                        // Expanded(child: Container(color: Colors.amber)),
                      ]),
              ),
            ),
            _currentWorkTask != null ?
                Container() :
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 15),
                  child:  Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(children: [
                            CircularProgressIndicator()
                          ]),
                        ),
                        // Expanded(child: Container(color: Colors.amber)),
                      ]),
                ),
          ],
        )
    );
/**
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10),
      child: IntrinsicHeight(
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(children: [
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context)!.number,
                      _currentWorkTask == null ? "" : _currentWorkTask.number),
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context)!.type,
                      _currentWorkTask == null ? "" : _currentWorkTask.type.name),
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context)!.sourceLocation,
                      _currentWorkTask == null ? "" : _currentWorkTask.sourceLocation.name),
                ]),
              ),
              // Expanded(child: Container(color: Colors.amber)),
            ]),
      ),
    );
**/
  }

  void _setupWorkTaskSourceLocationName() async {
    if (_currentWorkTask == null) {
      setState(() {

        _currentWorkTaskSourceLocationName = "";
      });
    }
    else if(_currentWorkTask?.type == WorkTaskType.LIST_PICK) {
      // list pick may have multiple source location, let's get the
      // first location of the pick in the list
      PickListService.getPickListByNumber(_currentWorkTask!.referenceNumber!).then((pickList) {

        if (pickList.picks.isEmpty) {
          _currentWorkTaskSourceLocationName = "";
        }

        // sort the picks
        PickService.sortPicks(pickList.picks, Global.getLastActivityLocation(), Global.isMovingForward());
        Pick? nextPick = pickList.picks.firstWhereOrNull((pick) => pick.quantity! > pick.pickedQuantity!);
        if (nextPick == null) {
          setState(() {

            _currentWorkTaskSourceLocationName  = "";
          });
        }
        else {
          setState(() {

            _currentWorkTaskSourceLocationName  = nextPick.sourceLocation!.name!;
          });
        }


      });


    }
    else {
      setState(() {

        _currentWorkTaskSourceLocationName = _currentWorkTask!.sourceLocation!.name!;
      });
    }
  }
  Widget _buildButtons(BuildContext context) {
    return buildThreeButtonRow(
        context,
        ElevatedButton(
          onPressed: _currentWorkTask == null ? null : _acknowledgeWorkTask,
          child: Text(CWMSLocalizations
              .of(context)
              .start),
        ),
        ElevatedButton(
          onPressed: _currentWorkTask == null ? null : _skipWorkTask,
          child: Text(CWMSLocalizations
              .of(context)
              .skip),
        ),
        badge.Badge(
          showBadge: true,
          badgeStyle: badge.BadgeStyle(
            padding: EdgeInsets.all(8),
            badgeColor: Colors.deepPurple,
          ),
          badgeContent: Text(
            _inventoryOnRF == null || _inventoryOnRF.length == 0 ? "0" : _inventoryOnRF.length.toString(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          child:
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              onPressed: _inventoryOnRF.length == 0 ? null : _startDeposit,
              child: Text(CWMSLocalizations.of(context)!.depositInventory),
            ),
          ),
        )
    );

  }

  Future<void> _skipWorkTask() async {

    showLoading(context);
    await WorkTaskService.unacknowledgeWorkTask(_currentWorkTask!, true);

    Navigator.of(context).pop();

    _refresh();
  }

  // call the deposit form to deposit the inventory on the RF
  Future<void> _refresh() async {

    setState(() {

      _currentWorkTask = null;
    });
    this._getNextWorkTask();

    // refresh the inventory on the RF
    _reloadInventoryOnRF();
  }

  // call the deposit form to deposit the inventory on the RF
  Future<void> _startDeposit() async {
    // cancel the timer when we start depositr
    _timer?.cancel();
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the inventory on the RF
    _refresh();
  }
  Future<void> _acknowledgeWorkTask() async {
    if (_currentWorkTask == null) {
      showErrorToast("No available work task for the current user");
      return;
    }

    printLongLogMessage("start to acknowlege current work task ${_currentWorkTask!.number} of type ${_currentWorkTask!.type}");

    if (_currentWorkTask!.type == WorkTaskType.BULK_PICK) {

      _startBulkPick(_currentWorkTask!);

    }
    else if (_currentWorkTask!.type == WorkTaskType.LIST_PICK) {

      _startListPick(_currentWorkTask!);

    }
    else if (_currentWorkTask!.type == WorkTaskType.PICK) {

      _startSinglePick(_currentWorkTask!);

    }
  }

  Future<void> _startBulkPick(WorkTask workTask) async {
    BulkPick bulkPick;
    showLoading(context);
    try {
      bulkPick = await BulkPickService.getBulkPickByNumber(workTask.referenceNumber!);
    }
    on WebAPICallException catch(ex) {
      // ok it is possible that the actual work is already cancelled but the work task is still present,
      // let's cancel the work task as it is no long valid

      Navigator.of(context).pop();
      printLongLogMessage("start to cancel the work task ${workTask.number} as there's no bulk pick attached");

      await _cancelWorkTask(workTask);
      _refresh();
      return;
    }

    Navigator.of(context).pop();
    if (bulkPick.pickedQuantity == bulkPick.quantity) {
      _completeWorkTask(_currentWorkTask!);
      _refresh();
      return;
    }
    printLongLogMessage("bulk pick: ${bulkPick.number}");
    printLongLogMessage("bulk pick source location id: ${bulkPick.sourceLocationId}");
    printLongLogMessage("bulk pick source location: ${bulkPick.sourceLocation == null ? 'N/A' : bulkPick.sourceLocation!.name}");
    Map argumentMap = new HashMap();
    argumentMap['bulkPick'] = bulkPick;
    argumentMap['pickMode'] = PickMode.SYSTEM_DRIVEN;

    printLongLogMessage("flow to bulk pick page");

    await Navigator.of(context).pushNamed("bulk_pick", arguments: argumentMap);


    // get the next work task
    _refresh();
  }

  Future<void> _startListPick(WorkTask workTask) async {
    PickList pickList;
    showLoading(context);
    try {
      pickList = await PickListService.getPickListByNumber(workTask.referenceNumber!);
    }
    on WebAPICallException catch(ex) {
      // ok it is possible that the actual work is already cancelled but the work task is still present,
      // let's cancel the work task as it is no long valid

      Navigator.of(context).pop();
      printLongLogMessage("start to cancel the work task ${workTask.number} as there's no pick list attached");

      await _cancelWorkTask(workTask);
      _refresh();
      return;
    }

    Navigator.of(context).pop();
    // if all the picks in the list are already done, then complate the work task
    if (!pickList.picks.any((pick) => pick.pickedQuantity! < pick!.quantity!)) {
      _completeWorkTask(_currentWorkTask!);
      _refresh();
      return;
    }
    printLongLogMessage("pick list: ${pickList.number}");

    Map argumentMap = new HashMap();
    argumentMap['pickList'] = pickList;
    argumentMap['pickMode'] = PickMode.SYSTEM_DRIVEN;

    printLongLogMessage("flow to list pick page");

    await Navigator.of(context).pushNamed("list_pick", arguments: argumentMap);


    // get the next work task
    _refresh();
  }

  Future<void> _startSinglePick(WorkTask workTask) async {
    Pick? pick;
    showLoading(context);
    try {
      pick = await PickService.getPicksByNumber(workTask.referenceNumber!);
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      // ok it is possible that the actual work is already cancelled but the work task is still present,
      // let's cancel the work task as it is no long valid
      printLongLogMessage("start to cancel the work task ${workTask.number} as there's no bulk pick attached");

      await _cancelWorkTask(workTask);
      _refresh();
      return;
    }

    Navigator.of(context).pop();

    if (pick?.pickedQuantity == pick?.quantity) {
      _completeWorkTask(_currentWorkTask!);
      _refresh();
      return;
    }

    printLongLogMessage("pick: ${pick?.number}");
    printLongLogMessage("pick source location id: ${pick?.sourceLocationId}");
    printLongLogMessage("pick source location: ${pick?.sourceLocation == null ? 'N/A' : pick?.sourceLocation?.name}");
    Map argumentMap = new HashMap();
    argumentMap['pick'] = pick;
    argumentMap['pickMode'] = PickMode.SYSTEM_DRIVEN;

    printLongLogMessage("flow to produce inventory page");

    final result = await Navigator.of(context).pushNamed("pick", arguments: argumentMap);

    if (result ==  null) {
      // the user press Return, let's unacknowledge the work task and then start with the next work task
      await WorkTaskService.unacknowledgeWorkTask(_currentWorkTask!, true);
    }

    // get the next work task
    _refresh();
  }

  Future<void> _completeWorkTask(WorkTask workTask) async {
    showLoading(context);
    await WorkTaskService.completeWorkTask(workTask);

    Navigator.of(context).pop();

  }

  Future<void> _cancelWorkTask(WorkTask workTask) async {
    showLoading(context);
    await WorkTaskService.cancelWorkTask(workTask);

    Navigator.of(context).pop();

  }
  void _reloadInventoryOnRF() {

    try {

      InventoryService.getInventoryOnCurrentRF()
          .then((value) {
        setState(() {
          _inventoryOnRF = value;
        });
      });
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

  }

}