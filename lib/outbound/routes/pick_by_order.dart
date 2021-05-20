
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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:badges/badges.dart';


class PickByOrderPage extends StatefulWidget{

  PickByOrderPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _PickByOrderPageState();

}

class _PickByOrderPageState extends State<PickByOrderPage> {

  // input batch id
  TextEditingController _orderNumberController = new TextEditingController();
  GlobalKey _formKey = new GlobalKey<FormState>();
  // all picks that assigned to current user
  List<Pick> assignedPicks = [];

  // a map of relationship beteen order and pick id
  HashMap orderPicks = new HashMap<String, Set<int>>();


  // map to store order's priority
  // Order can be either hight priority or not.
  // High priority orders will be picked first
  // The priority is set by the client
  // key: order number
  // value: whether it is a high priority order
  HashMap orderPriorityMap = new HashMap<String, bool>();
  // whether the picks from this order can be shared with
  // others to increase the pick performance
  // key: order number
  // value: whether the order can be shared
  HashMap orderSharedFlagMap = new HashMap<String, bool>();

  List<Order> assignedOrders = [];

  // selected orders from the order selection pop up
  List<Order> selectedOrders = [];

  Pick currentPick;

  List<Inventory>  inventoryOnRF;

  @override
  void initState() {
    super.initState();
    print("Start to initial picks to empty list");
    assignedPicks = [];
    currentPick = null;
    orderPicks.clear();
    orderPriorityMap.clear();
    orderSharedFlagMap.clear();
    assignedOrders = [];
    selectedOrders = [];
    inventoryOnRF = new List<Inventory>();

    _reloadInventoryOnRF();

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).pickByOrder)),
      body:
          Column(
            children: [
              _buildOrderNumberScanner(context),
              _buildButtons(context),
              _buildOrderList(context)
            ],
          ),
      // bottomNavigationBar: buildBottomNavigationBar(context)
      endDrawer: MyDrawer(),
    );
  }

  // scan in barcode to add a order into current batch
  Widget _buildOrderNumberScanner(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
              key: _formKey,
              // autovalidateMode: AutovalidateMode.always, //开启自动校验
              child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _orderNumberController,
                      decoration: InputDecoration(
                        labelText: CWMSLocalizations
                            .of(context)
                            .orderNumber,
                        hintText: CWMSLocalizations
                            .of(context)
                            .inputOrderNumberHint,
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
              onPressed: _onAddingOrder,
              textColor: Colors.white,
              child: Text(CWMSLocalizations.of(context).addOrder),
            ),

          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child:
            RaisedButton(
              color: Theme.of(context).primaryColor,
              onPressed: _onChooseOrder,
              textColor: Colors.white,
              child: Text(CWMSLocalizations.of(context).chooseOrder),
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
                  onPressed: inventoryOnRF.length == 0 ? null : _startDeposit,
                  child: Text(CWMSLocalizations.of(context).depositInventory),
                ),
              )
          ),
        ],
    );
  }


  Widget _buildOrderList(BuildContext context) {

    return
      Expanded(
        child: ListView.separated(
            separatorBuilder: (context, index) => Divider(
              color: Colors.black,
            ),
            itemCount: assignedOrders.length,
            itemBuilder: (BuildContext context, int index) {

              return OrderListItem(
                index: index,
                order: assignedOrders[index],
                highPriorityFlag: orderPriorityMap[assignedOrders[index].number],
                sharedFlag: orderSharedFlagMap[assignedOrders[index].number],
                onPriorityChanged:  (order) =>  _changePriority(order),
                onSharedFlagChanged:  (order) =>  _changeSharedFlag(order),
                onRemove:  (index) =>  _removeOrder(index)
              );
            }),
      );
  }
  void _changePriority(Order order) {
    print("will change the priority for order: ${order.number}");
    setState(() {
      orderPriorityMap[order.number] = !orderPriorityMap[order.number];
    });

  }
  void _changeSharedFlag(Order order) {
    print("will change the shared flag for order: ${order.number}");

    setState(() {
      orderSharedFlagMap[order.number] = !orderSharedFlagMap[order.number];
    });
  }
  void _removeOrder(int index) {
    print("will remove for order: ${assignedOrders[index].number}");
    setState(() {
      // remove the picks first
      _deassignPickFromUser(assignedOrders[index]);
      // remove the order from the user
      assignedOrders.removeAt(index);
    });
  }

  // Prompt to let the user choose existing orders to add
  void _onAddingOrder() async {

    print("Will get information for ${_orderNumberController.text} ");

    // check if hte order is already in the list
    // if so, we won't bother refresh the list
    if (_orderNumberController.text.isNotEmpty &&
        !_orderAlreadyInList(_orderNumberController.text)) {

      Order order =
        await OrderService.getOrderByNumber(_orderNumberController.text);


      if (order != null) {
        _assignOrderToUser(order);
        print("Will add order ${order.number} to the list");
        _orderNumberController.clear();
      }
    }

  }
  void _assignOrderToUser(Order order) {
    // only continue if the order is not in the list yet

    int index = assignedOrders.indexWhere(
            (element) => element.number == order.number);
    if (index < 0) {

      setState(() {
        orderPriorityMap[order.number] = false;
        orderSharedFlagMap[order.number] = false;
        assignedOrders.add(order);
        _assignPickToUser(order);


      });
    }

  }


  void _assignPickToUser(Order order) async {
    List<Pick> picksByOrder =  await PickService.getPicksByOrder(order.id);

    assignedPicks.addAll(picksByOrder);

    // save the relationship between the order and the picks so that
    // when we remove the order from current assignment, we can
    // remove the picks as well
    Set<int> existingPicks = orderPicks[order.number];
    if (existingPicks == null) {
      existingPicks = new Set<int>();
    }

    picksByOrder.forEach((pick) => existingPicks.add(pick.id));
    orderPicks[order.number] = existingPicks;

    print("_assignPickToUser: Now we have ${assignedPicks.length} picks from ${orderPicks.length} orders assigned");


  }

  void _deassignPickFromUser(Order order) {
    // find the pick ids and remove them from the pick list

    Set<int> existingPicks = orderPicks[order.number];
    existingPicks.forEach((pickId) =>
        assignedPicks.removeWhere((assignedPick) => assignedPick.id == pickId));

    // remove order from the relationship map
    orderPicks.remove(order.number);
    print("_deassignPickFromUser: Now we have ${assignedPicks.length} picks from ${orderPicks.length} orders assigned");

  }

  bool _orderAlreadyInList(String orderNumber) {
    return
      assignedOrders.indexWhere((element) => element.number == orderNumber) >= 0;
  }
  void _onChooseOrder() async {

    selectedOrders = [];
    _showOrdersWithOpenPickDialog();


  }



  void _onStartingPicking() async {

    print("we get ${assignedPicks.length} picks by order ${_orderNumberController.text}");

    await this._startPickingForOrder();

  }

  _startPickingForOrder() async {


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
      print("pick result: $pickResult for pick: ${currentPick.number}");

      // refresh the orders
      if (pickResult.result == true) {
        // update the current pick
        currentPick.pickedQuantity
          = currentPick.pickedQuantity + pickResult.confirmedQuantity;
        // update the order's open pick quantity to reflect the
        // pick status
        Order order = _getOrderByPick(currentPick);
        if (order != null) {
          setState(() {

            order.totalOpenPickQuantity -= pickResult.confirmedQuantity;
            order.totalPickedQuantity +=  pickResult.confirmedQuantity;
          });
        }

        // refresh the pick on the RF
        _reloadInventoryOnRF();


        // continue with next available pick
        _startPickingForOrder();
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

  Order _getOrderByPick(Pick pick) {
    // Since the pick doesn't have the information of the pick, we will
    // need to get the order number from the map orderPicks, which
    // is the only place we store the relationship between
    // order number and pick id

    Order order;
    Iterator<MapEntry<String, Set<int>>> orderPickIterator = orderPicks.entries.iterator;
    while(orderPickIterator.moveNext()) {
      MapEntry<String, Set<int>> orderPick = orderPickIterator.current;
      String orderNumber = orderPick.key;
      Set<int> pickIdSet =  orderPick.value;
      // check if the pick belongs to the current order
      if (pickIdSet.contains(pick.id)) {
        order = assignedOrders.firstWhere((assignedOrder) => assignedOrder.number == orderNumber);
        if (order != null) {
          // we found such order, let's return
          break;
        }
      }

    }

    return order;
  }

  Future<void> _startBarcodeScanner() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print("barcode scanned: $barcodeScanRes");
    _orderNumberController.text = barcodeScanRes;

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
  Future<void> _showOrdersWithOpenPickDialog() async {

    showLoading(context);
    List<Order> ordersWithOpenPick =
        await OrderService.getAvailableOrdersWithPick();

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
                    _confirmOrderSelection();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            ListTile(title: Text(CWMSLocalizations
                      .of(context)
                      .chooseOrder)),
            _buildOrdersWithOpenPickList(context, ordersWithOpenPick)
          ],
        );
        //使用AlertDialog会报错
        //return AlertDialog(content: child);
        return Dialog(child: child);
      },
    );
  }

  Widget _buildOrdersWithOpenPickList(BuildContext context,
      List<Order> ordersWithOpenPick) {
    return
      Expanded(
        child: ListView.builder(
            itemCount: ordersWithOpenPick.length,
            itemBuilder: (BuildContext context, int index) {

              return OrderListItem(
                  index: index,
                  order: ordersWithOpenPick[index],
                  highPriorityFlag: false,
                  sharedFlag: false,
                  displayOnlyFlag: true,
                  onPriorityChanged:  null,
                  onSharedFlagChanged: null,
                  onRemove:  null,
                  onToggleHightlighted:  (selected) => _selectOrderFromList(selected, ordersWithOpenPick[index])
              );
            }),
      );
  }

  void _selectOrderFromList(bool selected, Order order) {
    // check if the order is already in the list
    int index = selectedOrders.indexWhere(
            (element) => element.number == order.number);
    if (selected && index < 0) {
      // the user select the order but it is not in the list yet
      // let's add it to the list
      selectedOrders.add(order);
    }
    else if (!selected && index >= 0) {
      // the user unselect the order and it is already in the list
      // let's remove it from the list
      selectedOrders.removeAt(index);
    }
  }

  void _confirmOrderSelection() {
    // let's add assign the selected orders into current user
    selectedOrders.forEach((order) {
      _assignOrderToUser(order);
    });

  }

  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the pick on the RF
    _reloadInventoryOnRF();
  }



}