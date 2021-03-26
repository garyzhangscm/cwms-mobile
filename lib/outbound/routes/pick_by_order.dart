
import 'dart:collection';

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/services/order.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/outbound/widgets/order_list_item.dart';
import 'package:cwms_mobile/shared/bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:infinite_listview/infinite_listview.dart';


class PickByOrderPage extends StatefulWidget{

  PickByOrderPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _PickByOrderPageState();

}

class _PickByOrderPageState extends State<PickByOrderPage> {

  // input batch id
  TextEditingController _orderNumberController = new TextEditingController();
  GlobalKey _formKey = new GlobalKey<FormState>();
  List<Pick> picks = [];
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

  List<Order> orders = [];

  Pick currentPick;


  @override
  void initState() {
    super.initState();
    print("Start to initial picks to empty list");
    picks = [];
    currentPick = null;
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
      bottomNavigationBar: buildBottomNavigationBar(context)
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
            padding: const EdgeInsets.only(left: 10, right: 10),
            child:
            RaisedButton(
              color: Theme.of(context).primaryColor,
              onPressed: _onAddingOrder,
              textColor: Colors.white,
              child: Text(CWMSLocalizations.of(context).addOrder),
            ),

          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child:
            RaisedButton(
              color: Theme.of(context).primaryColor,
              onPressed: _onChooseOrder,
              textColor: Colors.white,
              child: Text(CWMSLocalizations.of(context).chooseOrder),
            ),

          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: RaisedButton(
              color: Theme.of(context).primaryColor,
              onPressed: _onStartingPicking,
              textColor: Colors.white,
              child: Text(CWMSLocalizations.of(context).start),
            ),
          ),
        ],
    );
  }


  Widget _buildOrderList(BuildContext context) {

    return
      Expanded(
        child: ListView.builder(
            itemCount: orders.length,
            itemBuilder: (BuildContext context, int index) {

              return OrderListItem(
                index: index,
                order: orders[index],
                highPriorityFlag: orderPriorityMap[orders[index].number],
                sharedFlag: orderSharedFlagMap[orders[index].number],
                onPriorityChanged:  (order) =>  _changePriority(order),
                onSharedFlagChanged:  (order) =>  _changeSharedFlag(order),
                onRemove:  (index) =>  _removeOrder(index)
              );
            }),
      );
/***
    if (orders.isEmpty) {

      return Column(children: <Widget>[
        ListTile(title:Text("Empty Order List")),
      ]);
    }
    else {

    }

    return
      Expanded(
        child: ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              return OrderListItem(orders[index]);
            }),
      );**/
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
    print("will remove for order: ${orders[index].number}");
    setState(() {
      orders.removeAt(index);
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

        print("Will add order ${order.number} to the list");
        setState(() {
          orderPriorityMap[order.number] = false;
          orderSharedFlagMap[order.number] = false;
          orders.add(order);

        });
        _orderNumberController.clear();
      }
    }

  }

  bool _orderAlreadyInList(String orderNumber) {
    return
      orders.indexWhere((element) => element.number == orderNumber) >= 0;
  }
  void _onChooseOrder() async {



  }


  void _onStartingPicking() async {
    List<Pick> picksByOrder =  await PickService.getPicksByOrder(_orderNumberController.text);

    this.picks = picksByOrder;

    print("we get ${picks.length} picks by order ${_orderNumberController.text}");

    await this._startPickingForOrder();

  }

  _startPickingForOrder() async {


    // flow to pick page with the first pick
    currentPick = _getNextValidPick();

    if (currentPick != null) {
      final result = await Navigator.of(context).pushNamed("pick", arguments: currentPick);
      int pickedQuantity = result as int;
      print("confirmed with picked quantity: $pickedQuantity");

    }
  }
  Future<void> _startBarcodeScanner() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print("barcode scanned: $barcodeScanRes");
    _orderNumberController.text = barcodeScanRes;

  }

  Pick _getNextValidPick() {
    if (picks.isEmpty) {
       return null;
    }
    else {
      return picks.firstWhere((pick) => pick.quantity > pick.pickedQuantity);
    }
  }

}