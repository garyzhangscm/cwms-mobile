import 'package:badges/badges.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/work/models/work_task.dart';
import 'package:cwms_mobile/work/services/work_task_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class SystemDrivenWork extends StatefulWidget{

  SystemDrivenWork({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _SystemDrivenWorkState();

}

class _SystemDrivenWorkState extends State<SystemDrivenWork> {

  WorkTask _currentWorkTask;
  List<Inventory>  _inventoryOnRF = [];

  @override
  Future<void> didChangeDependencies() async {
    printLongLogMessage("Start to get the next work");
    showLoading(context);
    WorkTask nextWorkTask;

    _inventoryOnRF = [];
    _reloadInventoryOnRF();
    try {

      nextWorkTask = await WorkTaskService.getNextWorkTask();
      if (nextWorkTask == null) {
        printLongLogMessage("there's no available work task");
      }
      else {
        printLongLogMessage("start to work on the task ${nextWorkTask.number}");
      }
      Navigator.of(context).pop();
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());

    }

    _currentWorkTask = nextWorkTask;


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
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10),
      child: IntrinsicHeight(
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(children: [
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context).number,
                      _currentWorkTask == null ? "" : _currentWorkTask.number),
                  buildTwoSectionInformationRow(CWMSLocalizations.of(context).type,
                      _currentWorkTask == null ? "" : _currentWorkTask.type),
                ]),
              ),
              // Expanded(child: Container(color: Colors.amber)),
            ]),
      ),
    );

  }
  Widget _buildButtons(BuildContext context) {
    return buildTwoButtonRow(
        context,
        ElevatedButton(
          onPressed: _acknowledgeWorkTask,
          child: Text(CWMSLocalizations
              .of(context)
              .acknowledge),
        ),
        Badge(
          showBadge: true,
          padding: EdgeInsets.all(8),
          badgeColor: Colors.deepPurple,
          badgeContent: Text(
            _inventoryOnRF == null || _inventoryOnRF.length == 0 ? "0" : _inventoryOnRF.length.toString(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          child:
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              onPressed: _inventoryOnRF.length == 0 ? null : _startDeposit,
              child: Text(CWMSLocalizations.of(context).depositInventory),
            ),
          ),
        )
    );

  }

  // call the deposit form to deposit the inventory on the RF
  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the inventory on the RF
    _reloadInventoryOnRF();
  }
  void _acknowledgeWorkTask() {
    if (_currentWorkTask == null) {
      showErrorToast("No available work task for the current user");
      return;
    }

    printLongLogMessage("start to acknowlege current work task ${_currentWorkTask.number} of type ${_currentWorkTask.type}");
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