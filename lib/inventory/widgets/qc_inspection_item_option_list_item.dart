
import 'package:cwms_mobile/inventory/models/qc_inspection_request_item_option.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/shared/functions.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/qc_rule_item_comparator.dart';
import '../models/qc_rule_item_type.dart';

class QCInspectionItemOptionListItem extends StatefulWidget {
  QCInspectionItemOptionListItem({this.qcInspectionRequestItemOption}
       ) : super(key: ValueKey(qcInspectionRequestItemOption.id));



  final QCInspectionRequestItemOption qcInspectionRequestItemOption;
  bool _qcResult = null;

  @override
  _QCInspectionItemOptionListItemState createState() => _QCInspectionItemOptionListItemState();


}

class _QCInspectionItemOptionListItemState extends State<QCInspectionItemOptionListItem> {


  @override
  Widget build(BuildContext context) {
    switch(widget.qcInspectionRequestItemOption.qcRuleItem.qcRuleItemType) {
      case QCRuleItemType.NUMBER:
        return buildNumberOption(context);
        break;
      case QCRuleItemType.STRING:
        return buildStringOption(context);
        break;

      default:
        return buildYesNoOption(context);

    }
  }

  Widget buildYesNoOption(BuildContext context) {

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
                  //leading: _buildInventoryImage(),

                  title: Text(
                    widget.qcInspectionRequestItemOption.qcRuleItem.checkPoint,
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    ),
                  ),
                  trailing:
                  Checkbox(
                    tristate: true,
                    value: widget._qcResult,
                    onChanged: (value) {
                      _qcBooleanResultChanged(value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildNumberOption(BuildContext context) {

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
                  //leading: _buildInventoryImage(),

                  title: Text(
                    widget.qcInspectionRequestItemOption.qcRuleItem.checkPoint,
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    ),
                  ),
                  trailing:
                      SizedBox(
                          width: 100,
                          child:  new TextField(
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.]+'))],
                            onChanged: (value) {
                              _qcNumberResultChanged(value);
                            },// Only numbers can be entered
                          ),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget buildStringOption(BuildContext context) {

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
                  //leading: _buildInventoryImage(),

                  title: Text(
                    widget.qcInspectionRequestItemOption.qcRuleItem.checkPoint,
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    ),
                  ),
                  trailing:
                  Checkbox(
                    tristate: true,
                    value: widget._qcResult,
                    onChanged: (value) {
                      _qcBooleanResultChanged(value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  _qcBooleanResultChanged(bool pass){
    setState(() {
      widget._qcResult = pass;
      if (pass == null) {
        widget.qcInspectionRequestItemOption.qcInspectionResult =
            QCInspectionResult.PENDING;
      }
      else if (pass == true) {
        widget.qcInspectionRequestItemOption.qcInspectionResult =
            QCInspectionResult.PASS;
      }
      else if (pass == false) {
        widget.qcInspectionRequestItemOption.qcInspectionResult =
            QCInspectionResult.FAIL;
      }
    });
  }

  _qcNumberResultChanged(String value){
    printLongLogMessage("number value is changed to $value");
    printLongLogMessage("expected value is ${widget.qcInspectionRequestItemOption.qcRuleItem.expectedValue}");
    printLongLogMessage("comparator is ${widget.qcInspectionRequestItemOption.qcRuleItem.qcRuleItemComparator}");


    setState(() {
      // the user didn't input anything
      if (value.isEmpty) {
        widget._qcResult = null;
        widget.qcInspectionRequestItemOption.qcInspectionResult =
            QCInspectionResult.PENDING;
        printLongLogMessage("the user didn't input anything, pending for input");
      }
      else {
        var doubleValue = double.tryParse(value);
        if (doubleValue == null) {
          // the value is not a valid number, QC fail
          widget._qcResult = false;
          widget.qcInspectionRequestItemOption.qcInspectionResult =
              QCInspectionResult.FAIL;
          printLongLogMessage("the user input something that can't convert to number, QC fail");
        }
        else if (_validateNumberResult(doubleValue)){
          widget._qcResult = true;
          widget.qcInspectionRequestItemOption.qcInspectionResult =
              QCInspectionResult.PASS;
          printLongLogMessage("QC pass the validation");

        }
        else {
          // the user's input fail the QC validation
          widget._qcResult = false;
          widget.qcInspectionRequestItemOption.qcInspectionResult =
              QCInspectionResult.FAIL;
          printLongLogMessage("QC fail the validation");

        }
      }
    });
  }


  // check if the user input number is a pass or fail
  bool _validateNumberResult(double value) {

    var expectedValue = double.tryParse(widget.qcInspectionRequestItemOption.qcRuleItem.expectedValue);
    if (expectedValue == null) {
      // the expected value is not defined correctly, QC fail
      return false;
    }
    bool result = true;
    switch(widget.qcInspectionRequestItemOption.qcRuleItem.qcRuleItemComparator) {
      case QCRuleItemComparator.EQUAL:
        result = value == expectedValue;
        break;
      case QCRuleItemComparator.GREAT_OR_EQUAL:
        result = value >=  expectedValue;
        break;
      case QCRuleItemComparator.GREAT_THAN:
        result = value >  expectedValue;
        break;
      case QCRuleItemComparator.LESS_OR_EQUAL:
        result = value <=  expectedValue;
        break;
      case QCRuleItemComparator.LESS_THAN:
        result = value <  expectedValue;
        break;
      default:
        result = false;  // not support, QC fail

    }
    return result;
  }

}
