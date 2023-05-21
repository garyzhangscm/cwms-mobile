

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../inventory/models/reversed_inventory_information.dart';

class ReversedInventoryItem extends StatefulWidget {
  ReversedInventoryItem({this.index, this.reversedInventoryInformation, }
       ) : super(key: ValueKey(index));


  final int index;
  final ReversedInventoryInformation reversedInventoryInformation;

  @override
  _ReversedInventoryItemState createState() => _ReversedInventoryItemState();


}

class _ReversedInventoryItemState extends State<ReversedInventoryItem> {


  @override
  Widget build(BuildContext context) {

    if (widget.reversedInventoryInformation.reverseInProgress == true) {
      // show loading indicator if the inventory still reverse in progress
      return SizedBox(
          height: 150,
          child:  Stack(
            alignment:Alignment.center ,
            fit: StackFit.expand, //未定位widget占满Stack整个空间
            children: <Widget>[
              buildReversedInventoryDisplay(context),
              Padding(
                padding: const EdgeInsets.only(top: 100.0, bottom: 100),
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
    }
    else {
      return buildReversedInventoryDisplay(context);

    }
  }

  Widget buildReversedInventoryDisplay(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Material(
        // If the user highlight the widget, display green
        // otherwise if there's no open pick, display grey
        color: widget.reversedInventoryInformation.reverseResult ? Colors.lightGreen: Colors.white,
        shape: BorderDirectional(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: .5,
          ),
        ),
        child: InkWell(
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
                    widget.reversedInventoryInformation.lpn,
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
                                  widget.reversedInventoryInformation.itemName,
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
                                  widget.reversedInventoryInformation.quantity.toString(),
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
