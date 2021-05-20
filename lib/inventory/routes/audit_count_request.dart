import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/audit_count_request.dart';
import 'package:cwms_mobile/inventory/models/audit_count_result.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/services/audit_count_request.dart';
import 'package:cwms_mobile/inventory/services/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/widgets/audit_count_list_item.dart';
import 'package:cwms_mobile/inventory/widgets/count_request_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AuditCountRequestPage extends StatefulWidget{

  AuditCountRequestPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _AuditCountRequestPageState();

}

class _AuditCountRequestPageState extends State<AuditCountRequestPage> {

  // input batch

  GlobalKey _formKey = new GlobalKey<FormState>();
  List<AuditCountResult> _inventories = [];

  AuditCountRequest _auditCountRequest;

  @override
  void didChangeDependencies() {
    // print("_CycleCountRequestPageState / didChangeDependencies / 1");
    super.didChangeDependencies();
    // print("_CycleCountRequestPageState / didChangeDependencies / 2");
    _auditCountRequest = ModalRoute.of(context).settings.arguments;
    // print("_CycleCountRequestPageState / didChangeDependencies / 3");

    AuditCountRequestService.getInventorySummariesForAuditCounts(_auditCountRequest)
        .then((inventories) {
      // print("_CycleCountRequestPageState / didChangeDependencies / 4");

      setState(() {

        _inventories = inventories;
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    // print("_CycleCountRequestPageState / rebuild!");
    return Scaffold(
      appBar: AppBar(title: Text("${CWMSLocalizations.of(context).auditCount} - ${_auditCountRequest?.location?.name}")),
      body: _buildInventoryList(context),
      bottomNavigationBar:_buildBottomNavigationBar(context),
      floatingActionButton:
        FloatingActionButton( //悬浮按钮
            child: Icon(Icons.add),
            onPressed:_onAddItem
        ),
      endDrawer: MyDrawer(),
      );
  }


  Widget _buildBottomNavigationBar(BuildContext context) {

    return
      BottomNavigationBar(
        items: <BottomNavigationBarItem>[

          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: CWMSLocalizations.of(context).confirmAuditCount),
          BottomNavigationBarItem(icon: Icon(Icons.next_plan), label: CWMSLocalizations.of(context).skipAuditCount),
          BottomNavigationBarItem(icon: Icon(Icons.cancel), label: CWMSLocalizations.of(context).cancelAuditCount),

        ],
        currentIndex: 0,
        fixedColor: Colors.blue,
        onTap: (index) => _onActionItemTapped(index),

      );

  }
  void _onActionItemTapped(int index) {
    if (index == 0) {
      _onConfirmAuditCount();
    }
    else if (index == 1) {
      _onSkipAuditCount();
    }
    else if (index == 1) {
      // index == 2
      _onCancelAuditCount();
    }
  }
  void _onAddItem() {

  }

  Widget _buildInventoryList(BuildContext context) {
    // print("_buildInventorySummaryList: ${_inventorySummaries.length}");
    return
      Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
        child:
        ListView.separated(

      //分割器构造器
        separatorBuilder: (context, index) => Divider(height: .0),
        itemCount: _inventories.length,

        itemBuilder: (BuildContext context, int index) {
          return AuditCountListItem(
              index: index,
              auditCountResult: _inventories[index],
              onLPNValueChange:(lpn) => _setupUnexpectedLpn(index, lpn),
              onItemValueChange: (item) => _setupUnexpectedItem(index, item),
              newItemFlag: _inventories[index].item == null,
              onQuantityValueChange:  (newValue) => _inventories[index].countQuantity = int.parse(newValue)
          );
        })
      );

  }

  _setupUnexpectedLpn(int index, String lpn) {
    // print("will change the item of index / $index to $item");
  }
  _setupUnexpectedItem(int index, Item item) {
    // print("will change the item of index / $index to $item");
  }
  void _onConfirmAuditCount() async {
    FormState formState = _formKey.currentState as FormState;

    if (!formState.validate()) {
      // validation fail
      return;
    }

    // print("form validation passed");

    // printLongLogMessage("start to confirm cycle count with inventory:");
    // printLongLogMessage("===========================================");
    // skip all the empty inventory with null item
    _inventories.forEach((element) {

      // printLongLogMessage(element.toJson().toString());
    });

    _inventories.removeWhere((inventory) =>
    inventory.item == null
    );

    // printLongLogMessage("===========================================");
    // skip all the empty inventory with null item
    _inventories.forEach((element) {

      // printLongLogMessage(element.toJson().toString());
    });
    await AuditCountRequestService.confirmAuditCount(
        _auditCountRequest, _inventories);
    //return true to the previous page

    Navigator.pop(context, true);
  }

  void _onSkipAuditCount() {

    // do nothing but return true to the previous page
    // The previous page is supposed to remove the request
    // from current assignment but since it is not finished yet
    // it will be pickup by the next count attempt
    Navigator.pop(context, true);
  }

  void _onCancelAuditCount() async {

    // cancel audit count is not allowed

  }
}