

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/audit_count_result.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_batch.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
import 'package:cwms_mobile/inventory/services/item.dart';
import 'package:cwms_mobile/shared/functions.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../shared/global.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class InventoryListItem extends StatefulWidget {
  InventoryListItem({this.index, this.inventory}
       ) : super(key: ValueKey(inventory?.id));



  final int? index;
  final Inventory? inventory;

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
                  trailing: IconButton(
                        icon: new Icon(Icons.print),
                        onPressed: () => _printLPNLabel()
                    ),
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
  void _printLPNLabel() {
      InventoryService.printLPNLabel(widget.inventory!.lpn!, widget.inventory!.location!.locationGroup!.name!);
  }

  Widget _buildInventoryDetail() {
    return
      new Container(
        child:
          Column(
            children: <Widget>[
               _buildInformationRow(
                  CWMSLocalizations.of(context)!.location,
                  widget.inventory!.location!.name!),
              _buildInformationRow(
                  CWMSLocalizations.of(context)!.lpn, widget.inventory!.lpn ?? ""),
              _buildInformationRow(
                  CWMSLocalizations.of(context)!.item, widget.inventory!.item?.name ?? ""),
              _buildInformationRow(
                  CWMSLocalizations.of(context)!.item, widget.inventory!.item?.description ?? ""),
              _buildInformationRow(
                  CWMSLocalizations.of(context)!.itemPackageType,
                      widget.inventory?.itemPackageType?.description ?? ""),
              _buildInformationRow(
                  CWMSLocalizations.of(context)!.inventoryStatus,
                  widget.inventory?.inventoryStatus?.description ?? ""),
              _buildInformationRow(
                  CWMSLocalizations.of(context)!.quantity,
                  widget.inventory?.quantity.toString() ?? ""),
              widget.inventory?.item?.trackingColorFlag == true?
                  _buildInformationRow(
                      CWMSLocalizations.of(context)!.color,
                      widget.inventory?.color ?? "") :
                  Container(),
              widget.inventory?.item?.trackingStyleFlag == true?
                  _buildInformationRow(
                      CWMSLocalizations.of(context)!.style,
                      widget.inventory?.style ?? "") :
                  Container(),
              widget.inventory?.item?.trackingProductSizeFlag == true?
                  _buildInformationRow(
                      CWMSLocalizations.of(context)!.productSize,
                      widget.inventory?.productSize ?? "") :
                  Container(),
              widget.inventory?.item?.trackingInventoryAttribute1Flag == true && Global.currentInventoryConfiguration?.inventoryAttribute1Enabled == true?
                  _buildInformationRow(
                      Global.currentInventoryConfiguration?.getInventoryAttributeDisplayName("attribute1") + ":",
                      widget.inventory?.attribute1 ?? "") :
                  Container(),
              widget.inventory?.item?.trackingInventoryAttribute2Flag == true && Global.currentInventoryConfiguration?.inventoryAttribute2Enabled == true?
                  _buildInformationRow(
                      Global.currentInventoryConfiguration?.getInventoryAttributeDisplayName("attribute2") + ":",
                      widget.inventory?.attribute2 ?? "") :
                  Container(),
              widget.inventory?.item?.trackingInventoryAttribute3Flag == true && Global.currentInventoryConfiguration?.inventoryAttribute3Enabled == true?
                  _buildInformationRow(
                      Global.currentInventoryConfiguration?.getInventoryAttributeDisplayName("attribute3") + ":",
                      widget.inventory?.attribute3 ?? "") :
                  Container(),
              widget.inventory?.item?.trackingInventoryAttribute4Flag == true && Global.currentInventoryConfiguration?.inventoryAttribute4Enabled == true?
                  _buildInformationRow(
                      Global.currentInventoryConfiguration?.getInventoryAttributeDisplayName("attribute4") + ":",
                      widget.inventory?.attribute4 ?? "") :
                  Container(),
              widget.inventory?.item?.trackingInventoryAttribute5Flag == true && Global.currentInventoryConfiguration?.inventoryAttribute5Enabled == true?
                  _buildInformationRow(
                      Global.currentInventoryConfiguration?.getInventoryAttributeDisplayName("attribute5") + ":",
                      widget.inventory?.attribute5 ?? "") :
                  Container(),
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
