

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/audit_count_result.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_batch.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
import 'package:cwms_mobile/inventory/services/item.dart';
import 'package:cwms_mobile/shared/functions.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class InventoryListItem extends StatefulWidget {
  InventoryListItem({this.index, this.inventory}
       ) : super(key: ValueKey(inventory.id));



  final int index;
  final Inventory inventory;

  @override
  _InventoryListItemState createState() => _InventoryListItemState();


}

class _InventoryListItemState extends State<InventoryListItem> {

  @override
  Widget build(BuildContext context) {
    // print("build list itme for cycle count result: ${widget.cycleCountResult}");
    // print("build list itme for cycle count result: ${widget.cycleCountResult.batchId}");
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

                  title: _buildInventoryDetail(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryImage() {
    return Image.asset(
      "assets/images/avatar.png",
      width: 80,
    );

  }
  Widget _buildInventoryDetail() {
    return
      new Container(
        child:
          Column(
            children: <Widget>[
              _buildInformationRow(
                  CWMSLocalizations.of(context).item, widget.inventory.item.name),
              _buildInformationRow(
                  CWMSLocalizations.of(context).item, widget.inventory.item.description),
              _buildInformationRow(
                  CWMSLocalizations.of(context).itemPackageType,
                      widget.inventory.itemPackageType.description),
              _buildInformationRow(
                  CWMSLocalizations.of(context).inventoryStatus,
                  widget.inventory.inventoryStatus.description),
              _buildInformationRow(
                  CWMSLocalizations.of(context).quantity,
                  widget.inventory.quantity.toString()),
          ]
      ));
  }

  Widget _buildInformationRow(String name, String value) {
    return
      Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child:
          Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child:
                  Text(
                      name,
                      textScaleFactor: .9,
                      style: TextStyle(
                        height: 1.15,
                        color: Colors.blueGrey[700],
                        fontSize: 17,
                      )
                  ),
                ),
                Text(
                    value,
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    )
                ),
              ]
          ),
      );
  }



}
