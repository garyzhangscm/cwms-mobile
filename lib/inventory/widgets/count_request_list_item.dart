

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_batch.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/services/item.dart';
import 'package:cwms_mobile/shared/functions.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class CountRequestListItem extends StatefulWidget {
  CountRequestListItem({this.index, this.cycleCountResult,
       this.onItemValueChange,
       @required this.onQuantityValueChange}
       ) : super(key: ValueKey(cycleCountResult.id));

  final ValueChanged<String> onQuantityValueChange;
  final ValueChanged<Item> onItemValueChange;



  final int index;
  final CycleCountResult cycleCountResult;



  @override
  _CountRequestListItemState createState() => _CountRequestListItemState();


}

class _CountRequestListItemState extends State<CountRequestListItem> {

  TextEditingController _quantityController = new TextEditingController();
  TextEditingController _itemController = new TextEditingController();

  void _onQuantityValueChange(String value) {
      widget.onQuantityValueChange(value);
  }

  void _onItemValueChange(String value) {
    printLongLogMessage("item name changed to ${value}");

    ItemService.getItemByName(value).then((item) {

      widget.onItemValueChange(item);

    });

  }

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

                  title: _buildCycleCountResult(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCycleCountResult() {
    return
      new Container(

        child:
        new Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child:
                Row(
                  children: [
                    Text("Item: "),
                    // if the cycle count result doesn't have item,
                    // it means the locaiton doesn't any inventory
                    widget.cycleCountResult.item == null ?

                    new Expanded(
                      child: TextFormField(
                          textAlign: TextAlign.end,
                          controller: _itemController,
                          onFieldSubmitted: (value) => _onItemValueChange(value),
                          decoration: InputDecoration(
                            suffixIcon:
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                              mainAxisSize: MainAxisSize.min, // added line
                              children: <Widget>[
                                IconButton(
                                  onPressed: _startItemBarcodeScanner,
                                  icon: Icon(Icons.scanner),
                                )
                              ],
                            ),
                          ),
                        )
                    )
                        :
                    Text(widget.cycleCountResult.item.name)
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child:
                Row(
                  children: [
                    Text("Item: "),
                    widget.cycleCountResult.item == null ?
                    Text("")
                        :
                    Text(widget.cycleCountResult.item.description)
                  ],
                ),
              ),
              Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child:
                  Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 2.0),
                        child:
                            Text("Expected Quantity: "),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 25.0),
                        child:
                            Text(widget.cycleCountResult.quantity.toString()),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 2.0),
                        child:
                            Text("Actual Quantity: "),
                      ),
                      new Expanded(
                        // flex: 3,
                        child: TextFormField(
                            maxLength: 10,
                            textAlign: TextAlign.end,
                            keyboardType: TextInputType.number,
                            controller: _quantityController,
                            onFieldSubmitted: (value) => _onQuantityValueChange(value),
                            // 校验ITEM NUMBER（不能为空）
                            validator: (v) {
                              // if we specify a item, either by manually input
                              // or an existing item, we will force the user to type in the quantity
                              if (( _itemController.text.isNotEmpty || widget.cycleCountResult.item != null) &&
                                  v.trim() == "") {
                                return "please type in quantity";
                              }
                              return null;
                            }),
                      ),
                    ],
                  )
              ),
            ]
        ),
      );
  }

  Future<void> _startItemBarcodeScanner() async {

    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    printLongLogMessage("barcode scanned: $barcodeScanRes");
    return barcodeScanRes;

  }




}
