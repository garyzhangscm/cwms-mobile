

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InventoryDepositRequestItem extends StatefulWidget {
  InventoryDepositRequestItem({this.index, this.inventoryDepositRequest,
       this.highlighted: false,
       @required this.onToggleHightlighted}
       ) : super(key: ValueKey(index));


  final ValueChanged<bool> onToggleHightlighted;

  final int index;
  final InventoryDepositRequest inventoryDepositRequest;


  bool highlighted;



  @override
  _InventoryDepositRequestItemState createState() => _InventoryDepositRequestItemState();


}

class _InventoryDepositRequestItemState extends State<InventoryDepositRequestItem> {


  void _onToggleHightlighted() {
    if (widget.onToggleHightlighted != null) {

      setState(() {
        widget.highlighted = !widget.highlighted;
      });
      widget.onToggleHightlighted(widget.highlighted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Material(
        // If the user highlight the widget, display green
        // otherwise if there's no open pick, display grey
        color: widget.highlighted ? Colors.lightGreen: Colors.white,
        shape: BorderDirectional(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: .5,
          ),
        ),
        child: InkWell(
          onTap: _onToggleHightlighted,
          child: Padding(
            padding: const EdgeInsets.only(top: 0.0, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListTile(
                  dense: true,
                  // tileColor: widget.highlighted ? Colors.lightGreen:
                  //     widget.order.totalOpenPickQuantity == 0 ?
                  //                Colors.grey : Colors.white,
                  title: Text(
                    widget.inventoryDepositRequest.lpn,
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    ),

                  ),
                  subtitle:
                    Column(
                      children: <Widget>[
                        Row(
                            children: <Widget>[
                              Text(
                                CWMSLocalizations.of(context).item + ": ",
                                textScaleFactor: .9,
                                style: TextStyle(
                                  height: 1.15,
                                  color: Colors.blueGrey[700],
                                  fontSize: 17,
                                )
                              ),
                              Text(
                                  widget.inventoryDepositRequest.itemName,
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
                                  CWMSLocalizations.of(context).inventoryStatus + ": ",
                                  textScaleFactor: .9,
                                  style: TextStyle(
                                    height: 1.15,
                                    color: Colors.blueGrey[700],
                                    fontSize: 17,
                                  )
                              ),
                              Text(
                                  widget.inventoryDepositRequest.inventoryStatusDescription,
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
                                  CWMSLocalizations.of(context).quantity + ": ",
                                  textScaleFactor: .9,
                                  style: TextStyle(
                                    height: 1.15,
                                    color: Colors.blueGrey[700],
                                    fontSize: 17,
                                  )
                              ),
                              Text(
                                  widget.inventoryDepositRequest.quantity.toString(),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


}
