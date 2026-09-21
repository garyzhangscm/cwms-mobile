import 'package:cwms_mobile/inventory/models/qc_inspection_request_item_option.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/shared/functions.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/qc_rule_item_comparator.dart';
import '../models/qc_rule_item_type.dart';

class QCInspectionItemOptionListItem extends StatefulWidget {
  QCInspectionItemOptionListItem(
      {required this.qcInspectionRequestItemOption, this.value})
      : super(key: ValueKey(qcInspectionRequestItemOption.id));

  final QCInspectionRequestItemOption qcInspectionRequestItemOption;
  bool? _qcResult;
  Object? value;

  @override
  _QCInspectionItemOptionListItemState createState() =>
      _QCInspectionItemOptionListItemState();
}

class _QCInspectionItemOptionListItemState
    extends State<QCInspectionItemOptionListItem> {
  @override
  Widget build(BuildContext context) {
    switch (widget.qcInspectionRequestItemOption.qcRuleItem?.qcRuleItemType) {
      case QCRuleItemType.NUMBER:
        return buildNumberOption(context);
      case QCRuleItemType.STRING:
        return buildStringOption(context);

      default:
        return buildYesNoOption(context);
    }
  }

  Widget buildYesNoOption(BuildContext context) {
    if (widget.value != null) {
      widget._qcResult = widget.value as bool;
    }
    final checked = widget._qcResult == true;
    return _optionCard(
      context,
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.qcInspectionRequestItemOption.qcRuleItem?.checkPoint ?? "",
              style: TextStyle(
                height: 1.25,
                color: Colors.blueGrey[800],
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _qcBooleanResultChanged(!checked),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: checked ? const Color(0xFF6950B5) : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: checked
                      ? const Color(0xFF6950B5)
                      : const Color(0xFF9AA8B8),
                  width: 2,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 25)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionCard(BuildContext context, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E7EF)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0C172B4D),
                  blurRadius: 12,
                  offset: Offset(0, 4)),
            ],
          ),
          child: child,
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
                    widget.qcInspectionRequestItemOption.qcRuleItem
                            ?.checkPoint ??
                        "",
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    ),
                  ),
                  trailing: SizedBox(
                    width: 100,
                    child: new TextFormField(
                      keyboardType: TextInputType.number,
                      initialValue: widget.value is int
                          ? int.parse(widget.value.toString()).toString()
                          : widget.value is double
                              ? double.parse(widget.value.toString()).toString()
                              : null,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9.]+'))
                      ],
                      onChanged: (value) {
                        _qcNumberResultChanged(value);
                      }, // Only numbers can be entered
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
                    widget.qcInspectionRequestItemOption.qcRuleItem
                            ?.checkPoint ??
                        "",
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    ),
                  ),
                  trailing: SizedBox(
                    width: 150,
                    child: new TextFormField(
                      initialValue: widget.value?.toString(),
                      onChanged: (value) {
                        _qcStringResultChanged(value);
                      }, // Only numbers can be entered
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

  _qcBooleanResultChanged(bool value) {
    printLongLogMessage(
        "_qcBooleanResultChanged ${widget.qcInspectionRequestItemOption.qcRuleItem?.checkPoint} is changed to ${value}");

    setState(() {
      widget.qcInspectionRequestItemOption.booleanValue = value;
      widget._qcResult = value;
      widget.value = value;
      if (_validateBooleanResult(value)) {
        widget.qcInspectionRequestItemOption.qcInspectionResult =
            QCInspectionResult.PASS;
      } else {
        widget.qcInspectionRequestItemOption.qcInspectionResult =
            QCInspectionResult.FAIL;
      }
    });
  }

  // check if the user input number is a pass or fail
  bool _validateBooleanResult(bool value) {
    var expectedValue =
        widget.qcInspectionRequestItemOption.qcRuleItem?.expectedValue;
    if (expectedValue == null) {
      // the expected value is not defined correctly, QC fail
      return false;
    }
    bool result = true;
    switch (
        widget.qcInspectionRequestItemOption.qcRuleItem?.qcRuleItemComparator) {
      case QCRuleItemComparator.EQUAL:
        result = value.toString().toLowerCase() == expectedValue.toLowerCase();
        break;
      default:
        result = false; // not support, QC fail
    }
    return result;
  }

  _qcNumberResultChanged(String value) {
    setState(() {
      // the user didn't input anything
      if (value.isEmpty) {
        widget._qcResult = null;
        widget.qcInspectionRequestItemOption.qcInspectionResult =
            QCInspectionResult.PENDING;
        printLongLogMessage(
            "the user didn't input anything, pending for input");
        widget.qcInspectionRequestItemOption.doubleValue = null;
      } else {
        var doubleValue = double.tryParse(value);
        if (doubleValue == null) {
          // the value is not a valid number, QC fail
          widget._qcResult = false;
          widget.qcInspectionRequestItemOption.qcInspectionResult =
              QCInspectionResult.FAIL;
          printLongLogMessage(
              "the user input something that can't convert to number, QC fail");
          widget.qcInspectionRequestItemOption.doubleValue = null;
        } else if (_validateNumberResult(doubleValue)) {
          widget._qcResult = true;
          widget.qcInspectionRequestItemOption.qcInspectionResult =
              QCInspectionResult.PASS;
          printLongLogMessage("QC pass the validation");
          widget.qcInspectionRequestItemOption.doubleValue = doubleValue;
        } else {
          // the user's input fail the QC validation
          widget._qcResult = false;
          widget.qcInspectionRequestItemOption.qcInspectionResult =
              QCInspectionResult.FAIL;
          printLongLogMessage("QC fail the validation");
          widget.qcInspectionRequestItemOption.doubleValue = doubleValue;
        }
      }
    });
  }

  // check if the user input number is a pass or fail
  bool _validateNumberResult(double value) {
    var expectedValue = double.tryParse(
        widget.qcInspectionRequestItemOption.qcRuleItem!.expectedValue ?? "");
    if (expectedValue == null) {
      // the expected value is not defined correctly, QC fail
      return false;
    }
    bool result = true;
    switch (
        widget.qcInspectionRequestItemOption.qcRuleItem?.qcRuleItemComparator) {
      case QCRuleItemComparator.EQUAL:
        result = value == expectedValue;
        break;
      case QCRuleItemComparator.GREAT_OR_EQUAL:
        result = value >= expectedValue;
        break;
      case QCRuleItemComparator.GREAT_THAN:
        result = value > expectedValue;
        break;
      case QCRuleItemComparator.LESS_OR_EQUAL:
        result = value <= expectedValue;
        break;
      case QCRuleItemComparator.LESS_THAN:
        result = value < expectedValue;
        break;
      default:
        result = false; // not support, QC fail
    }
    return result;
  }

  _qcStringResultChanged(String value) {
    printLongLogMessage("_qcStringResultChanged to ${value}");

    setState(() {
      // the user didn't input anything
      if (value.isEmpty) {
        widget._qcResult = null;
        widget.qcInspectionRequestItemOption.qcInspectionResult =
            QCInspectionResult.PENDING;
        printLongLogMessage(
            "the user didn't input anything, pending for input");
        widget.qcInspectionRequestItemOption.stringValue = null;
      } else if (_validateStringResult(value)) {
        widget._qcResult = true;
        widget.qcInspectionRequestItemOption.qcInspectionResult =
            QCInspectionResult.PASS;
        printLongLogMessage("QC pass the validation");
        widget.qcInspectionRequestItemOption.stringValue = value;
      } else {
        // the user's input fail the QC validation
        widget._qcResult = false;
        widget.qcInspectionRequestItemOption.qcInspectionResult =
            QCInspectionResult.FAIL;
        printLongLogMessage("QC fail the validation");
        widget.qcInspectionRequestItemOption.stringValue = value;
      }
    });
  }

  // check if the user input number is a pass or fail
  bool _validateStringResult(String value) {
    var expectedValue =
        widget.qcInspectionRequestItemOption.qcRuleItem?.expectedValue ?? "";
    bool result = true;
    switch (
        widget.qcInspectionRequestItemOption.qcRuleItem?.qcRuleItemComparator) {
      case QCRuleItemComparator.EQUAL:
        result = value == expectedValue;
        break;
      case QCRuleItemComparator.LIKE:
        result = value.contains(expectedValue) || expectedValue.contains(value);
        break;

      default:
        result = false; // not support, QC fail
    }
    return result;
  }
}
