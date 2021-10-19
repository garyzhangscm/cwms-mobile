

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/audit_count_result.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_batch.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request_item_option.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
import 'package:cwms_mobile/inventory/services/item.dart';
import 'package:cwms_mobile/shared/functions.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

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
                        _qcResultChanged(value);
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

  _qcResultChanged(bool pass){
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


}
