
import 'dart:collection';
import 'dart:core';

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/models/pick_result.dart';
import 'package:cwms_mobile/outbound/services/order.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/outbound/widgets/order_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/bottom_navigation_bar.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/services/work_order.dart';
import 'package:cwms_mobile/workorder/widgets/work_order_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:badges/badges.dart';


class PickByWorkOrderPage extends StatefulWidget{

  PickByWorkOrderPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _PickByWorkOrderPageState();

}

class _PickByWorkOrderPageState extends State<PickByWorkOrderPage> {

  // input batch id
  TextEditingController _workOrderNumberController = new TextEditingController();
  GlobalKey _formKey = new GlobalKey<FormState>();
  // all picks that assigned to current user
  List<Pick> assignedPicks = [];

  // a map of relationship beteen order and pick id
  // we will use this map to remove the picks when we remove the
  // work order from the assignment
  HashMap workOrderPicks = new HashMap<String, Set<int>>();


  // map to store order's priority
  // Order can be either hight priority or not.
  // High priority orders will be picked first
  // The priority is set by the client
  // key: order number
  // value: whether it is a high priority order
  HashMap workOrderPriorityMap = new HashMap<String, bool>();
  // whether the picks from this order can be shared with
  // others to increase the pick performance
  // key: order number
  // value: whether the order can be shared
  HashMap workOrderSharedFlagMap = new HashMap<String, bool>();

  List<WorkOrder> assignedWorkOrders = [];

  // selected orders from the order selection pop up
  List<WorkOrder> selectedWorkOrders = [];

  Pick currentPick;

  List<Inventory>  inventoryOnRF;

  @override
  void initState() {
    super.initState();
    print("Start to initial picks to empty list");
    assignedPicks = [];
    currentPick = null;
    workOrderPicks.clear();
    workOrderPriorityMap.clear();
    workOrderSharedFlagMap.clear();
    assignedWorkOrders = [];
    selectedWorkOrders = [];
    inventoryOnRF = new List<Inventory>();

    _reloadInventoryOnRF();

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).pickByWorkOrder)),
      body:
          Column(
            children: [
              _buildWorkOrderNumberScanner(context),
              _buildButtons(context),
              _buildWorkOrderList(context)
            ],
          ),
      // bottomNavigationBar: buildBottomNavigationBar(context)
      endDrawer: MyDrawer(),
    );
  }

  // scan in barcode to add a order into current batch
  Widget _buildWorkOrderNumberScanner(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
              key: _formKey,
              // autovalidateMode: AutovalidateMode.always, //开启自动校验
              child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _workOrderNumberController,
                      decoration: InputDecoration(
                        labelText: CWMSLocalizations
                            .of(context)
                            .workOrderNumber,
                        hintText: CWMSLocalizations
                            .of(context)
                            .inputWorkOrderNumberHint,
                        suffixIcon: IconButton(
                          onPressed: () => _startBarcodeScanner(),
                          icon: Icon(Icons.scanner),
                        ),
                      ),
                    ),
                  ]
              )
          )
      );
  }
  Widget _buildButtons(BuildContext context) {

    return Column(
      children: [
        buildTowButtonRow(context,
          ElevatedButton(
              onPressed: _onAddingWorkOrder,
              child: Text(CWMSLocalizations.of(context).addWorkOrder)
          ),
          ElevatedButton(
              onPressed: _onChooseWorkOrder,
              child: Text(CWMSLocalizations.of(context).chooseWorkOrder),
          ),
        ),
        buildTowButtonRow(context,
            ElevatedButton(
                onPressed: _onStartingPicking,
                child: Text(CWMSLocalizations.of(context).start),
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
      ],
    );

    /***
    return
      Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        //交叉轴的布局方式，对于column来说就是水平方向的布局方式
        crossAxisAlignment: CrossAxisAlignment.center,
        //就是字child的垂直布局方向，向上还是向下
        verticalDirection: VerticalDirection.down,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child:
            RaisedButton(
              color: Theme.of(context).primaryColor,
              onPressed: _onAddingWorkOrder,
              textColor: Colors.white,
              child: Text(CWMSLocalizations.of(context).addWorkOrder),
            ),

          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child:
            RaisedButton(
              color: Theme.of(context).primaryColor,
              onPressed: _onChooseWorkOrder,
              textColor: Colors.white,
              child: Text(CWMSLocalizations.of(context).chooseWorkOrder),
            ),

          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: RaisedButton(
              color: Theme.of(context).primaryColor,
              onPressed: _onStartingPicking,
              textColor: Colors.white,
              child: Text(CWMSLocalizations.of(context).start),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child:
              Badge(
                showBadge: true,
                padding: EdgeInsets.all(8),
                badgeColor: Colors.deepPurple,
                badgeContent: Text(
                  inventoryOnRF.length.toString(),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                child: RaisedButton(
                  color: inventoryOnRF.length == 0 ? Colors.grey : Theme.of(context).primaryColor,
                  textColor: inventoryOnRF.length == 0 ? Colors.black : Colors.white,
                  onPressed: inventoryOnRF.length == 0 ? null : _startDeposit,
                  child: Text(CWMSLocalizations.of(context).depositInventory),
                ),
              )
          ),
        ],
    );
        **/
  }


  Widget _buildWorkOrderList(BuildContext context) {

    return
      Expanded(
        child: ListView.separated(
            separatorBuilder: (context, index) => Divider(
              color: Colors.black,
            ),
            itemCount: assignedWorkOrders.length,
            itemBuilder: (BuildContext context, int index) {

              return WorkOrderListItem(
                index: index,
                workOrder: assignedWorkOrders[index],
                highPriorityFlag: workOrderPriorityMap[assignedWorkOrders[index].number],
                sharedFlag: workOrderSharedFlagMap[assignedWorkOrders[index].number],
                onPriorityChanged:  (order) =>  _changePriority(order),
                onSharedFlagChanged:  (order) =>  _changeSharedFlag(order),
                onRemove:  (index) =>  _removeWorkOrder(index)
              );
            }),
      );
  }
  void _changePriority(WorkOrder workOrder) {
    print("will change the priority for order: ${workOrder.number}");
    setState(() {
      workOrderPriorityMap[workOrder.number] = !workOrderPriorityMap[workOrder.number];
    });

  }
  void _changeSharedFlag(WorkOrder workOrder) {
    print("will change the shared flag for order: ${workOrder.number}");

    setState(() {
      workOrderSharedFlagMap[workOrder.number] = !workOrderSharedFlagMap[workOrder.number];
    });
  }
  void _removeWorkOrder(int index) {
    print("will remove for order: ${assignedWorkOrders[index].number}");
    setState(() {
      // remove the picks first
      _deassignPickFromUser(assignedWorkOrders[index]);
      // remove the order from the user
      assignedWorkOrders.removeAt(index);
    });
  }

  // Prompt to let the user choose existing orders to add
  void _onAddingWorkOrder() async {

    print("Will get information for ${_workOrderNumberController.text} ");

    // check if hte order is already in the list
    // if so, we won't bother refresh the list
    if (_workOrderNumberController.text.isNotEmpty &&
        !_orderAlreadyInList(_workOrderNumberController.text)) {

      WorkOrder workOrder =
        await WorkOrderService.getWorkOrderByNumber(_workOrderNumberController.text);


      if (workOrder != null) {
        _assignWorkOrderToUser(workOrder);
        print("Will add work order ${workOrder.number} to the list");
        _workOrderNumberController.clear();
      }
    }

  }

  void _onChooseWorkOrder() async {

    selectedWorkOrders = [];
    _showWorkOrdersWithOpenPickDialog();


  }


  void _assignWorkOrderToUser(WorkOrder workOrder) {
    // only continue if the order is not in the list yet

    int index = assignedWorkOrders.indexWhere(
            (element) => element.number == workOrder.number);
    if (index < 0) {
      // setup the quantites before assigning the work order
      workOrder.totalLineExpectedQuantity = 0;
      workOrder.totalLineOpenQuantity = 0;
      workOrder.totalLineInprocessQuantity = 0;
      workOrder.totalLineDeliveredQuantity = 0;
      workOrder.totalLineConsumedQuantity = 0;
      workOrder.workOrderLines.forEach((workOrderLine) {
        workOrder.totalLineExpectedQuantity += workOrderLine.expectedQuantity;
        workOrder.totalLineOpenQuantity += workOrderLine.openQuantity;
        workOrder.totalLineInprocessQuantity += workOrderLine.inprocessQuantity;
        workOrder.totalLineDeliveredQuantity += workOrderLine.deliveredQuantity;
        workOrder.totalLineConsumedQuantity += workOrderLine.consumedQuantity;
      });

      setState(() {
        workOrderPriorityMap[workOrder.number] = false;
        workOrderSharedFlagMap[workOrder.number] = false;
        assignedWorkOrders.add(workOrder);
        _assignPickToUser(workOrder);


      });
    }

  }


  void _assignPickToUser(WorkOrder workOrder) async {
    List<Pick> picksByWorkOrder =  await PickService.getPicksByWorkOrder(workOrder);

    assignedPicks.addAll(picksByWorkOrder);

    // save the relationship between the work order and the picks so that
    // when we remove the order from current assignment, we can
    // remove the picks as well
    Set<int> existingPicks = workOrderPicks[workOrder.number];
    if (existingPicks == null) {
      existingPicks = new Set<int>();
    }

    picksByWorkOrder.forEach((pick) => existingPicks.add(pick.id));
    workOrderPicks[workOrder.number] = existingPicks;

    print("_assignPickToUser: Now we have ${assignedPicks.length} picks from ${workOrderPicks.length} orders assigned");


  }

  void _deassignPickFromUser(WorkOrder workOrder) {
    // find the pick ids and remove them from the pick list

    Set<int> existingPicks = workOrderPicks[workOrder.number];
    existingPicks.forEach((pickId) =>
        assignedPicks.removeWhere((assignedPick) => assignedPick.id == pickId));

    // remove order from the relationship map
    workOrderPicks.remove(workOrder.number);
    print("_deassignPickFromUser: Now we have ${assignedPicks.length} picks from ${workOrderPicks.length} orders assigned");

  }

  bool _orderAlreadyInList(String workOrderNumber) {
    return
      assignedWorkOrders.indexWhere((element) => element.number == workOrderNumber) >= 0;
  }



  void _onStartingPicking() async {

    print("we get ${assignedPicks.length} picks by order ${_workOrderNumberController.text}");

    await this._startPickingForWorkOrder();

  }

  _startPickingForWorkOrder() async {


    // flow to pick page with the first pick
    currentPick = _getNextValidPick();

    if (currentPick != null) {
      final result = await Navigator.of(context).pushNamed("pick", arguments: currentPick);
      if (result == null) {
        // if the user click the return button instead of confirming
        // let's do nothing
        return;
      }
      var pickResult = result as PickResult;
      print("pick result: ${pickResult.result} for pick: ${currentPick.number}");

      // refresh the orders
      if (pickResult.result == true) {
        // update the current pick
        currentPick.pickedQuantity
          = currentPick.pickedQuantity + pickResult.confirmedQuantity;
        // update the order's open pick quantity to reflect the
        // pick status
        WorkOrder workOrder = _getWorkOrderByPick(currentPick);
        if (workOrder != null) {
          setState(() {

            workOrder.totalLineOpenQuantity -= pickResult.confirmedQuantity;
            workOrder.totalLineDeliveredQuantity +=  pickResult.confirmedQuantity;
          });
        }

        // refresh the pick on the RF
        _reloadInventoryOnRF();


        // continue with next available pick
        _startPickingForWorkOrder();
      }

    }
    else {
      // we don't have any picks
      showErrorDialog(context, "No More Picks");
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

  WorkOrder _getWorkOrderByPick(Pick pick) {
    // Since the pick doesn't have the information of the pick, we will
    // need to get the order number from the map orderPicks, which
    // is the only place we store the relationship between
    // order number and pick id

    WorkOrder workOrder;
    Iterator<MapEntry<String, Set<int>>> workOrderPickIterator = workOrderPicks.entries.iterator;
    while(workOrderPickIterator.moveNext()) {
      MapEntry<String, Set<int>> workOrderPick = workOrderPickIterator.current;
      String workOrderNumber = workOrderPick.key;
      Set<int> pickIdSet =  workOrderPick.value;
      // check if the pick belongs to the current order
      if (pickIdSet.contains(pick.id)) {
        workOrder = assignedWorkOrders.firstWhere((assignedWorkOrder) => assignedWorkOrder.number == workOrderNumber);
        if (workOrder != null) {
          // we found such order, let's return
          break;
        }
      }

    }

    return workOrder;
  }

  Future<void> _startBarcodeScanner() async {

    /*
    *
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print("barcode scanned: $barcodeScanRes");
    _workOrderNumberController.text = barcodeScanRes;
    * */



  }

  Pick _getNextValidPick() {
    print(" =====   _getNextValidPick      =====");
    assignedPicks.forEach((pick) {
      print(">> ${pick.number} / ${pick.quantity} / ${pick.pickedQuantity}");
    });
    if (assignedPicks.isEmpty) {
       return null;
    }
    else {
      return assignedPicks.firstWhere((pick) => pick.quantity > pick.pickedQuantity, orElse: () => null);
    }
  }

  // prompt a dialog for user to choose valid orders
  Future<void> _showWorkOrdersWithOpenPickDialog() async {

    showLoading(context);
    List<WorkOrder> workOrdersWithOpenPick =
        await WorkOrderService.getAvailableWorkOrdersWithPick();

    // 隐藏loading框
    Navigator.of(context).pop();
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        var child = Column(
          children: <Widget>[
            Row(
              children: [
                FlatButton(
                  child: Text(CWMSLocalizations
                            .of(context)
                            .cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                FlatButton(
                  child: Text(CWMSLocalizations
                              .of(context)
                              .confirm),
                  onPressed: () {
                    _confirmWorkOrderSelection();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            ListTile(title: Text(CWMSLocalizations
                      .of(context)
                      .chooseWorkOrder)),
            _buildWorkOrdersWithOpenPickList(context, workOrdersWithOpenPick)
          ],
        );
        //使用AlertDialog会报错
        //return AlertDialog(content: child);
        return Dialog(child: child);
      },
    );
  }

  Widget _buildWorkOrdersWithOpenPickList(BuildContext context,
      List<WorkOrder> workOrdersWithOpenPick) {
    return
      Expanded(
        child: ListView.builder(
            itemCount: workOrdersWithOpenPick.length,
            itemBuilder: (BuildContext context, int index) {

              return WorkOrderListItem(
                  index: index,
                  workOrder: workOrdersWithOpenPick[index],
                  highPriorityFlag: false,
                  sharedFlag: false,
                  displayOnlyFlag: true,
                  onPriorityChanged:  null,
                  onSharedFlagChanged: null,
                  onRemove:  null,
                  onToggleHightlighted:  (selected) => _selectWorkOrderFromList(selected, workOrdersWithOpenPick[index])
              );
            }),
      );
  }

  void _selectWorkOrderFromList(bool selected, WorkOrder workOrder) {
    // check if the order is already in the list
    int index = selectedWorkOrders.indexWhere(
            (element) => element.number == workOrder.number);
    if (selected && index < 0) {
      // the user select the order but it is not in the list yet
      // let's add it to the list
      selectedWorkOrders.add(workOrder);
    }
    else if (!selected && index >= 0) {
      // the user unselect the order and it is already in the list
      // let's remove it from the list
      selectedWorkOrders.removeAt(index);
    }
  }

  void _confirmWorkOrderSelection() {
    // let's add assign the selected orders into current user
    selectedWorkOrders.forEach((workOrder) {
      _assignWorkOrderToUser(workOrder);
    });

  }

  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the pick on the RF
    _reloadInventoryOnRF();
  }



}