

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_kpi_transaction.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WorkOrderKPIItem extends StatefulWidget {
  WorkOrderKPIItem({this.index, this.workOrderKPITransaction,
       @required this.onRemove}
       ) : super(key: ValueKey(
          (workOrderKPITransaction.username == null ? "" : workOrderKPITransaction.username)
              +
          (workOrderKPITransaction.workingTeamName == null ? "": workOrderKPITransaction.workingTeamName)));


  final ValueChanged<int> onRemove;


  final int index;
  final WorkOrderKPITransaction workOrderKPITransaction;



  @override
  _WorkOrderKPIItemState createState() => _WorkOrderKPIItemState();


}

class _WorkOrderKPIItemState extends State<WorkOrderKPIItem> {

  void _removeKPITransactionFromlist() {
      widget.onRemove(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Material(
        // If the user highlight the widget, display green
        // otherwise if there's no open pick, display grey
        color: Colors.white,
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

                  title: _buildKPIResult(),
                  trailing:
                  IconButton(
                      icon: new Icon(Icons.delete),
                      onPressed: () => _removeKPITransactionFromlist())

                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKPIResult() {
    return
      new Container(

        child:
        new Column(
            children: [
              // LPN Controller
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child:
                Row(
                  children: [

                    Padding(
                      padding: const EdgeInsets.only(right: 25.0),
                      child:
                      Text(CWMSLocalizations.of(context)!.userName),
                    ),

                    Text(widget.workOrderKPITransaction.username == null ? "" : widget.workOrderKPITransaction.username)
                  ],
                ),
              ),
              // Item controller
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child:
                Row(
                  children: [

                    Padding(
                      padding: const EdgeInsets.only(right: 25.0),
                      child:
                      Text(CWMSLocalizations.of(context)!.workingTeamName),
                    ),

                    Text(widget.workOrderKPITransaction.workingTeamName == null ? "" : widget.workOrderKPITransaction.workingTeamName)
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child:
                Row(
                  children: [

                    Padding(
                      padding: const EdgeInsets.only(right: 25.0),
                      child:
                      Text(widget.workOrderKPITransaction.amount.toString()),
                    ),

                    Text(widget.workOrderKPITransaction.kpiMeasurement.toString().substring(15))
                  ],
                ),
              ),
            ]
        ),
      );
  }








}
