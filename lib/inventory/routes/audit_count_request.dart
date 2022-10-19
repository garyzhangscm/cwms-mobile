import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/audit_count_request.dart';
import 'package:cwms_mobile/inventory/models/audit_count_request_action.dart';
import 'package:cwms_mobile/inventory/models/audit_count_result.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/services/audit_count_request.dart';
import 'package:cwms_mobile/inventory/services/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/widgets/audit_count_list_item.dart';
import 'package:cwms_mobile/inventory/widgets/count_result_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
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
      // if the audit count result(inventories) doesn't have the inventory attribute
      // setup yet, it normally means we may have unexpected inventory / item in the
      // location during the cycle count. We will need to init the
      // AuditCountResult.inventory to an empty inventory structure so when the user
      // start to input item and lpn, we can setup the inventory accordingly
      inventories.where((auditCountResult) => auditCountResult.inventory == null)
          .forEach((auditCountResult)   {
            printLongLogMessage("setup audit count result for ${auditCountResult.id}");

            auditCountResult.inventory =  new Inventory();
            auditCountResult.inventory.location = _auditCountRequest.location;
            auditCountResult.inventory.warehouseId =  Global.currentWarehouse.id;
            auditCountResult.unexpectedItem = true;
            printLongLogMessage("DONE setup audit count result for ${auditCountResult.id}");
      });


      setState(() {

        _inventories = inventories;
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    // print("_CycleCountRequestPageState / rebuild!");
    printLongLogMessage("_auditCountRequest.location == null? ${_auditCountRequest.location == null}");
    return Scaffold(
      appBar: AppBar(title: Text("${CWMSLocalizations.of(context).auditCount} - ${_auditCountRequest?.location?.name}")),
      resizeToAvoidBottomInset: true,
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
          // cancel audit count is now allowed yet
          // BottomNavigationBarItem(icon: Icon(Icons.cancel), label: CWMSLocalizations.of(context).cancelAuditCount),

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
    else  {
      // index == 1
      _onSkipAuditCount();
    }
  }

  AuditCountResult _getUnexpectedAuditCountResult() {

    AuditCountResult auditCountResult = new AuditCountResult();


    auditCountResult.batchId = _auditCountRequest.batchId;
    auditCountResult.location = _auditCountRequest.location;
    auditCountResult.inventory =  new Inventory();
    auditCountResult.inventory.location = _auditCountRequest.location;
    auditCountResult.inventory.warehouseId =  Global.currentWarehouse.id;
    auditCountResult.lpn = "";
    auditCountResult.item = new Item();
    auditCountResult.quantity = 0;
    auditCountResult.countQuantity = 0;
    auditCountResult.warehouseId = Global.currentWarehouse.id;
    auditCountResult.warehouse = Global.currentWarehouse;
    auditCountResult.unexpectedItem = true;
    return auditCountResult;
  }

  void _onAddItem() {

    AuditCountResult auditCountResult = _getUnexpectedAuditCountResult();




    setState(() {
      _inventories.add(auditCountResult);
      printLongLogMessage("new result added: ${auditCountResult.toJson().toString()}");
    });
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
              onItemPackageTypeValueChange:(itemPackageType) => _setupUnexpectedItemPackageType(index, itemPackageType),
              onInventoryStatusValueChange:(inventoryStatus) => _setupUnexpectedInventoryStatus(index, inventoryStatus),
              onQuantityValueChange:  (newValue) {
                printLongLogMessage("index: ${index}, inventory: ${_inventories[index].lpn}, quantity changed to ${newValue}");
                _inventories[index].countQuantity = int.parse(newValue);
              },
              onRemove: (index) => _removeInventory(index),
          );
        })
      );

  }

  _removeInventory(int index) {

    setState(() {

      _inventories.removeAt(index);
    });
  }
  _setupUnexpectedLpn(int index, String lpn) {
    // print("will change the item of index / $index to $item");

    setState(() {
      _inventories[index].lpn = lpn;
      _inventories[index].inventory.lpn = lpn;
    });
  }
  _setupUnexpectedItem(int index, Item item) {
    // print("will change the item of index / $index to $item");
    setState(() {
      _inventories[index].item = item;
      _inventories[index].inventory.item = item;
    });
  }
  _setupUnexpectedItemPackageType(int index, ItemPackageType itemPackageType) {
    // print("will change the item of index / $index to $item");
    // setState(() {
      _inventories[index].inventory.itemPackageType = itemPackageType;
    // });
  }
  _setupUnexpectedInventoryStatus(int index, InventoryStatus inventoryStatus) {
    // print("will change the item of index / $index to $item");
    // setState(() {
      _inventories[index].inventory.inventoryStatus = inventoryStatus;
    //});
  }
  void _onConfirmAuditCount() async {
    // since the user is able to confirm the cycle count, let's assume the user is
    // already in the location
    Global.setLastActivityLocation(_auditCountRequest.location);

    showLoading(context);

    FormState formState = _formKey.currentState as FormState;

    if (!formState.validate()) {
      // validation fail
      return;
    }
    _inventories.forEach((element) {
      printLongLogMessage(element.toJson().toString());
    }) ;

    _inventories.removeWhere((inventory) =>
      inventory.item == null
    );
    await AuditCountRequestService.confirmAuditCount(
        _auditCountRequest, _inventories);

    // hide the loading page
    Navigator.of(context).pop();

    //return true to the previous page
    Navigator.pop(context, AuditCountRequestAction.CONFIRMED);
  }

  void _onSkipAuditCount() {
    // since the user is able to skip the cycle count, let's assume the user is
    // already in the location


    // Note: we can't set the last activity location to the current location.
    // otherwise we won't be able to go back to the previous locaiton if we
    // skip all locations in the batch
    // Global.setLastActivityLocation(_auditCountRequest.location);

    // do nothing but return true to the previous page
    // The previous page is supposed to remove the request
    // from current assignment but since it is not finished yet
    // it will be pickup by the next count attempt
    Navigator.pop(context, AuditCountRequestAction.SKIPPED);
  }

}