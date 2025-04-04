

import 'package:cwms_mobile/inventory/models/cycle_count_batch.dart';
import 'package:cwms_mobile/shared/functions.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CountBatchListItem extends StatefulWidget {
  CountBatchListItem({this.index, this.countBatch,
       this.displayOnlyFlag: false,
       this.highlighted: false,
      this.cycleCountFlag: true,
      this.auditCountFlag: false,

       @required this.onRemove,
       @required this.onToggleHightlighted}
       ) : super(key: ValueKey(countBatch!.batchId));

  final ValueChanged<int>? onRemove;
  final ValueChanged<bool>? onToggleHightlighted;

  final int? index;
  final CycleCountBatch? countBatch;
  final bool? displayOnlyFlag;
  // whether we display the information for
  // audit count or cycle count
  final bool auditCountFlag;
  final bool cycleCountFlag;
  bool highlighted;



  @override
  _CountBatchListItemState createState() => _CountBatchListItemState();


}

class _CountBatchListItemState extends State<CountBatchListItem> {


  void _removeOrderFromlist() {
    if (widget.displayOnlyFlag == false) {
      widget.onRemove!(widget!.index!);
    }
  }
  void _onToggleHightlighted() {
    if (widget.onToggleHightlighted != null) {
      setState(() {
        widget.highlighted = !widget.highlighted;
      });
      widget.onToggleHightlighted!(widget.highlighted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Material(
        // If the user highlight the widget, display green
        // otherwise if there's no open pick, display grey
        color: widget.highlighted ? Colors.lightGreen:
        ((widget.countBatch?.openLocationCount == 0  && widget.cycleCountFlag == true) ||
            (widget.countBatch?.openAuditLocationCount == 0  && widget.auditCountFlag == true)) ?
              Colors.grey : Colors.white,
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
                    widget.countBatch!.batchId ?? "",
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    ),

                  ),
                  trailing:
                    widget.displayOnlyFlag == true?
                      Text("") :
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                           IconButton(
                             icon: new Icon(Icons.delete),
                             onPressed: () => _removeOrderFromlist()
                           ),
                        ]
                      ),
                  subtitle: Text(
                      widget.countBatch!.openLocationCount.toString() + " / " +
                          widget.countBatch!.finishedLocationCount.toString() + " / " +
                          widget.countBatch!.cancelledLocationCount.toString() + " / " +
                          widget.countBatch!.openAuditLocationCount.toString() + " / " +
                          widget.countBatch!.finishedAuditLocationCount.toString()
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
