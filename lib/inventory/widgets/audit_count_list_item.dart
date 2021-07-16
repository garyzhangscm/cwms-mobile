

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/audit_count_result.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_batch.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
import 'package:cwms_mobile/inventory/services/item.dart';
import 'package:cwms_mobile/shared/functions.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class AuditCountListItem extends StatefulWidget {
  AuditCountListItem({this.index, this.auditCountResult,
    this.onItemValueChange, this.onLPNValueChange,
    this.onRemove, this.onInventoryStatusValueChange,
    this.onItemPackageTypeValueChange,
    @required this.onQuantityValueChange}
       ) : super(key: ValueKey(auditCountResult.id));


  final ValueChanged<String> onQuantityValueChange;
  final ValueChanged<Item> onItemValueChange;
  final ValueChanged<InventoryStatus> onInventoryStatusValueChange;
  final ValueChanged<ItemPackageType> onItemPackageTypeValueChange;
  final ValueChanged<String> onLPNValueChange;
  final ValueChanged<int> onRemove;

  final int index;
  final AuditCountResult auditCountResult;



  @override
  _AuditCountListItemState createState() => _AuditCountListItemState();


}

class _AuditCountListItemState extends State<AuditCountListItem> {


  TextEditingController _itemController = new TextEditingController();
  TextEditingController _quantityController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();

  List<InventoryStatus> _validInventoryStatus;
  InventoryStatus _selectedInventoryStatus;
  ItemPackageType _selectedItemPackageType;
  Item _unexpectedItem;


  @override
  void initState() {
    super.initState();
    _unexpectedItem = new Item();
    _selectedInventoryStatus = new InventoryStatus();
    _selectedItemPackageType = new ItemPackageType();


    InventoryStatusService.getAllInventoryStatus()
        .then((value) {
      _validInventoryStatus = value;
      if (_validInventoryStatus.length > 0) {
        _selectedInventoryStatus = _validInventoryStatus[0];
        _onInventoryStatusValueChange(_selectedInventoryStatus.name);
      }
    });

  }

  void _onItemValueChange(String value) {
    printLongLogMessage("item name changed to $value");
    ItemService.getItemByName(value).then((item) {
      setState(() {

        _unexpectedItem = item;
      });

      widget.onItemValueChange(item);
    });
  }

  void _onInventoryStatusValueChange(String value) {
    printLongLogMessage("inventory status changed to $value");
    InventoryStatusService.getInventoryStatusByName(value)
        .then((inventoryStatus) {
            widget.onInventoryStatusValueChange(inventoryStatus);

    });
  }

  void _onItemPackageTypeValueChange(String value) {
    printLongLogMessage("item package type name changed to $value");

    if (_unexpectedItem != null ) {
      ItemPackageType itemPackageType
          = _unexpectedItem.itemPackageTypes.firstWhere(
              (itemPackageType) => itemPackageType.name == value);
      if (itemPackageType != null) {
          widget.onItemPackageTypeValueChange(itemPackageType);

      }
    }

  }

  void _onLPNValueChange(String value) {

    printLongLogMessage("lpn changed to $value");


      widget.onLPNValueChange(value);

  }

  void _onQuantityValueChange(String value) {
    widget.onQuantityValueChange(value);
  }
  void _removeAuditResultFromlist() {
    widget.onRemove(widget.index);
  }



  @override
  Widget build(BuildContext context) {
    // print("build list itme for cycle count result: ${widget.cycleCountResult}");
    // print("build list itme for cycle count result: ${widget.cycleCountResult.batchId}");
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Material(
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

                  title: _buildAuditCountResult(),
                  trailing:
                      IconButton(
                          icon: new Icon(Icons.delete),
                          onPressed: () => _removeAuditResultFromlist()
                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuditCountResult() {
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
                        Text(CWMSLocalizations.of(context).lpn),
                    ),
                    // if the cycle count result doesn't have item,
                    // it means the locaiton doesn't any inventory
                    widget.auditCountResult.unexpectedItem == true ?
                    new Expanded(
                        child: TextFormField(
                          textAlign: TextAlign.end,
                          controller: _lpnController,
                          onChanged: (value) => _onLPNValueChange(value),
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
                    Text(widget.auditCountResult.lpn)
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
                        Text(CWMSLocalizations.of(context).item),
                    ),
                    // if the cycle count result doesn't have item,
                    // it means the locaiton doesn't any inventory
                    widget.auditCountResult.unexpectedItem == true ?
                    new Expanded(
                      child: TextFormField(
                          textAlign: TextAlign.end,
                          controller: _itemController,
                          onChanged: (value) => _onItemValueChange(value),
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
                    Text(widget.auditCountResult.inventory.item.name)
                  ],
                ),
              ),
              // Item Description Controller
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child:
                Row(
                  children: [

                    Padding(
                      padding: const EdgeInsets.only(right: 25.0),
                      child:
                        Text(CWMSLocalizations.of(context).item),
                    ),

                    widget.auditCountResult.unexpectedItem == true ?
                    Text(_unexpectedItem == null ? "" : _unexpectedItem.description)
                          :
                    Text(widget.auditCountResult.inventory.item.description)
                  ],
                ),
              ),
              // item package type
              Padding(
                padding:
                    widget.auditCountResult.unexpectedItem == true ?
                    EdgeInsets.only(top: 1) : EdgeInsets.only(top: 10),
                child:
                Row(
                    children: <Widget>[

                      Padding(
                        padding: const EdgeInsets.only(right: 25.0),
                        child:
                          Text(CWMSLocalizations.of(context).itemPackageType,
                            textAlign: TextAlign.left,
                          ),
                      ),
                      widget.auditCountResult.unexpectedItem == true ?
                      Expanded(
                          child:
                          DropdownButtonFormField<ItemPackageType>(
                              hint: Text("请选择"),
                              items: _getItemPackageTypeItems(),
                              value: _selectedItemPackageType,
                              elevation: 1,
                              isExpanded: true,
                              icon: Icon(
                                Icons.list,
                                size: 20,
                              ),
                              onChanged: (T) {
                                //下拉菜单item点击之后的回调
                                setState(() {
                                  _selectedItemPackageType = T;
                                });
                              },
                              validator: (v) {
                                // if we specify a item, either by manually input
                                // or an existing item, we will force the user to type in the quantity
                                if (v == null || v.name.isEmpty) {
                                  return CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).itemPackageType);
                                }
                                return null;
                              }
                          )
                      )
                          :

                      Text(widget.auditCountResult.inventory.itemPackageType.name)

                    ]
                ),
              ),
              //Inventory Status
              Padding(
                padding:
                  widget.auditCountResult.unexpectedItem == true ?
                  EdgeInsets.only(top: 1) : EdgeInsets.only(top: 10),
                child:
                Row(
                    children: <Widget>[

                      Padding(
                        padding: const EdgeInsets.only(right: 25.0),
                        child:
                          Text(CWMSLocalizations.of(context).inventoryStatus,
                            textAlign: TextAlign.left,
                          ),
                      ),

                      widget.auditCountResult.unexpectedItem == true ?
                      Expanded(
                          child:
                          DropdownButtonFormField<InventoryStatus>(
                              hint: Text("请选择"),
                              items: _getInventoryStatusItems(),
                              value: _selectedInventoryStatus,
                              elevation: 1,
                              isExpanded: true,
                              icon: Icon(
                                Icons.list,
                                size: 20,
                              ),
                              onChanged: (T) {
                                _onInventoryStatusValueChange(T.name);
                                //下拉菜单item点击之后的回调
                                setState(() {
                                  _selectedInventoryStatus = T;
                                });
                              },
                              validator: (v) {
                                // if we specify a item, either by manually input
                                // or an existing item, we will force the user to type in the quantity
                                if (v == null  || v.name.isEmpty) {
                                  return CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).inventoryStatus);
                                }
                                return null;
                              }
                          )
                      )
                      :
                      Text(widget.auditCountResult.inventory.itemPackageType.name)
                    ]
                ),
              ),
              // count quantity
              Padding(
                  padding: EdgeInsets.only(top: 1),
                  child:
                  Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 25.0),
                        child:
                            Text(CWMSLocalizations.of(context).countQuantity),
                      ),
                      new Expanded(
                        // flex: 3,
                        child: TextFormField(
                            maxLength: 10,
                            textAlign: TextAlign.end,
                            keyboardType: TextInputType.number,
                            controller: _quantityController,
                            onChanged:(value) => _onQuantityValueChange(value),
                            // 校验ITEM NUMBER（不能为空）
                            validator: (v) {
                              // if we specify a item, either by manually input
                              // or an existing item, we will force the user to type in the quantity
                              if (( _itemController.text.isNotEmpty ||
                                      widget.auditCountResult.unexpectedItem != true ) &&
                                  v.trim() == "") {
                                return CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).countQuantity);
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
/*
*
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    printLongLogMessage("barcode scanned: $barcodeScanRes");
    return barcodeScanRes;
* */

  }

  List<DropdownMenuItem<ItemPackageType>> _getItemPackageTypeItems() {
    List<DropdownMenuItem<ItemPackageType>> items = new List();

    if (_unexpectedItem == null || _unexpectedItem.itemPackageTypes == null) {
      return items;
    }
    if (_unexpectedItem.itemPackageTypes != null &&
            _unexpectedItem.itemPackageTypes.length > 0) {
      _selectedItemPackageType = _unexpectedItem.itemPackageTypes[0];
      _onItemPackageTypeValueChange(_selectedItemPackageType.name);

      for (int i = 0; i < _unexpectedItem.itemPackageTypes.length; i++) {

        items.add(DropdownMenuItem<ItemPackageType>(
          value: _unexpectedItem.itemPackageTypes[i],
          child: Text(_unexpectedItem.itemPackageTypes[i].description),
        ));
      }
    }
    return items;
  }

  List<DropdownMenuItem<InventoryStatus>> _getInventoryStatusItems() {
    List<DropdownMenuItem<InventoryStatus>> items = new List();
    if (_validInventoryStatus == null) {
      return items;
    }
    for (int i = 0; i < _validInventoryStatus.length; i++) {
      print("start to create download list for _getInventoryStatusItems: ");
      items.add(DropdownMenuItem<InventoryStatus>(
        value: _validInventoryStatus[i],
        child: Text(_validInventoryStatus[i].description),
      ));
    }

    return items;
  }




}
