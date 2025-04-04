

import 'package:cwms_mobile/inbound/models/receipt.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ReceiptListItem extends StatefulWidget {
  ReceiptListItem({required this.index, required this.receipt,
          this.highlighted: false,
          required this.onToggleHightlighted}
       ) : super(key: ValueKey(receipt.number));

  final ValueChanged<bool> onToggleHightlighted;

  bool highlighted;

  final int index;
  final Receipt receipt;



  @override
  _ReceiptListItemState createState() => _ReceiptListItemState();


}

class _ReceiptListItemState extends State<ReceiptListItem> {

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
                    widget.receipt.number ?? "",
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    ),

                  ),
                  subtitle: Text(
                      widget.receipt.totalExpectedQuantity.toString() + " / " + widget.receipt.totalReceivedQuantity.toString()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
