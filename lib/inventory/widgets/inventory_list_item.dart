

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
import 'package:cwms_mobile/shared/functions.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../shared/global.dart';
import '../models/inventory_quantity_for_display.dart';
import '../models/item_unit_of_measure.dart';

class InventoryListItem extends StatefulWidget {
  InventoryListItem({this.index, this.inventory,
    required this.onQuantityChanged,
    required this.onStatusChanged,
    required this.onAttributeChanged}
       ) : inventoryQuantityForDisplay =  InventoryService.getInventoryQuantityForDisplay(inventory!),
        super(key: ValueKey(inventory.id));

  final ValueChanged<int> onQuantityChanged;   // return new quantity
  final ValueChanged<InventoryStatus> onStatusChanged;     // return id of the new status
  final ValueChanged<Inventory> onAttributeChanged;  // return inventory with same data but different attribute

  final int? index;
  final Inventory? inventory;

  InventoryQuantityForDisplay inventoryQuantityForDisplay;

  @override
  _InventoryListItemState createState() => _InventoryListItemState();


}

class _InventoryListItemState extends State<InventoryListItem> {

  void _onQuantityChanged(int newQuantity) {
      widget.onQuantityChanged(newQuantity);
  }

  void _onStatusChanged(InventoryStatus inventoryStatus) {
    widget.onStatusChanged(inventoryStatus);
  }


  void _onAttributeChanged(Inventory newInventory) {
    widget.onAttributeChanged(newInventory);
  }


  TextEditingController _newQuantityController = new TextEditingController();
  ItemUnitOfMeasure? _newQuantityItemUnitOfMeasure;

  InventoryStatus? _selectedInventoryStatus;

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
                const Divider(),
                ListTile(
                  dense: true,
                  // tileColor: widget.highlighted ? Colors.lightGreen:
                  //     widget.order.totalOpenPickQuantity == 0 ?
                  //                Colors.grey : Colors.white,
                  //leading: _buildInventoryImage(),

                  title: _buildInventoryDetail(),
                  /**
                  trailing: IconButton(
                        icon: new Icon(Icons.print),
                        onPressed: () => _printLPNLabel()
                    ),**/
                  trailing: PopupMenuButton<String>(
                    onSelected: (String? value) {
                      if (value == "print_label") {


                        showToast("print label from PDA is not support");
                      }
                      else if (value == "change_quantity") {

                        _openChangeQuantityDialog();
                      }
                      else if (value == "change_attribute") {

                        showToast("change attribute from PDA is not support");
                      }
                      else if (value == "change_status") {

                        _openChangeStatusDialog();
                      }
                    },
                    itemBuilder:
                        (BuildContext context) => <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: "print_label",
                              child: Text("Print"),
                            ),
                            const PopupMenuItem<String>(
                              value: "change_quantity",
                              child: Text("Change Quantity"),
                            ),
                            const PopupMenuItem<String>(
                              value: "change_status",
                              child: Text("Change Status"),
                            ),
                            const PopupMenuItem<String>(
                              value: "change_attribute",
                              child: Text("Change Attribute"),
                            ),
                        ],
                  ),

                ),
                const Divider(),
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
                  CWMSLocalizations.of(context).location,
                  widget.inventory!.location!.name!),
              _buildInformationRow(
                  CWMSLocalizations.of(context).lpn, widget.inventory!.lpn ?? ""),
              _buildInformationRow(
                  CWMSLocalizations.of(context).item, widget.inventory!.item?.name ?? ""),
              _buildInformationRow(
                  CWMSLocalizations.of(context).item, widget.inventory!.item?.description ?? ""),
              _buildInformationRow(
                  CWMSLocalizations.of(context).itemPackageType,
                      widget.inventory?.itemPackageType?.description ?? ""),
              _buildInformationRow(
                  CWMSLocalizations.of(context).inventoryStatus,
                  widget.inventory?.inventoryStatus?.description ?? ""),
              _buildInformationRow(
                  CWMSLocalizations.of(context).quantity,
                  widget.inventoryQuantityForDisplay.inventory.quantity.toString() +
                      "( " + widget.inventoryQuantityForDisplay.quantity.toString() + " " +
                      widget.inventoryQuantityForDisplay.displayItemUnitOfMeasure.unitOfMeasure!.name! + " )"
              ),
              widget.inventory?.item?.trackingColorFlag == true?
                  _buildInformationRow(
                      CWMSLocalizations.of(context).color,
                      widget.inventory?.color ?? "") :
                  Container(),
              widget.inventory?.item?.trackingStyleFlag == true?
                  _buildInformationRow(
                      CWMSLocalizations.of(context).style,
                      widget.inventory?.style ?? "") :
                  Container(),
              widget.inventory?.item?.trackingProductSizeFlag == true?
                  _buildInformationRow(
                      CWMSLocalizations.of(context).productSize,
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


  Future<void> _openChangeQuantityDialog() async {
    printLongLogMessage("start to change quantity for inventory ${widget.inventory?.id} / ${widget.inventory?.lpn}");
    /**
    _newQuantityItemUnitOfMeasure = widget.inventory?.itemPackageType?.itemUnitOfMeasures.firstWhere(
        (itemUnitOfMeasure) => itemUnitOfMeasure.unitOfMeasure?.id == widget.inventoryQuantityForDisplay.displayItemUnitOfMeasure.unitOfMeasure?.id
    );
        **/

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {

        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState){
              return AlertDialog(
                  title: Text(CWMSLocalizations.of(context).changeQuantity),
                  content:
                    Column(
                      children: <Widget>[
                        buildTwoSectionInformationRow(CWMSLocalizations.of(context).lpn,
                            widget.inventoryQuantityForDisplay.inventory.lpn!),
                        buildTwoSectionInformationRow(CWMSLocalizations.of(context).originalQuantity,
                            widget.inventoryQuantityForDisplay.inventory.quantity.toString() +
                                "( " + widget.inventoryQuantityForDisplay.quantity.toString() + " " +
                                widget.inventoryQuantityForDisplay.displayItemUnitOfMeasure.unitOfMeasure!.name! + " )"),
                        buildThreeSectionInputRow(
                            CWMSLocalizations.of(context).newQuantity,
                            TextFormField(
                                controller: _newQuantityController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                autofocus: true,
                                validator: (v) {

                                  if (v?.trim().isEmpty ?? true) {
                                    return "please type in the quantity";
                                  }
                                  return null;
                                }),
                            DropdownButton(
                              hint: Text(CWMSLocalizations.of(context).select),
                              items: _getItemUnitOfMeasures(),
                              value: _newQuantityItemUnitOfMeasure,
                              elevation: 1,
                              isExpanded: true,
                              icon: Icon(
                                Icons.list,
                                size: 20,
                              ),
                              onChanged: (ItemUnitOfMeasure? value) {
                                printLongLogMessage("item unit of measure is changed to ${value?.unitOfMeasure?.name}");
                                //下拉菜单item点击之后的回调
                                setState(() {
                                  _newQuantityItemUnitOfMeasure = value;
                                });
                              },
                            )
                        ),
                        buildTwoButtonRowWithWidth(context,
                          ElevatedButton(
                            child: Text(CWMSLocalizations.of(context).cancel),
                            onPressed: () {
                              _onQuantityChanged(widget.inventory!.quantity!);
                              Navigator.of(context).pop();
                            },
                          ),
                          MediaQuery.of(context).size.width * 0.3,
                          ElevatedButton(
                            child: Text(CWMSLocalizations.of(context).confirm),
                            onPressed: _newQuantityItemUnitOfMeasure == null || _newQuantityController.text.isEmpty ? null :
                                () async {
                              try {
                                int newQuantity = await _changeQuantity();
                                _onQuantityChanged(newQuantity);

                                Navigator.of(context).pop();
                              }
                              on Exception catch(ex) {
                                showToast(ex.toString());
                              }
                            },
                          ),
                          MediaQuery.of(context).size.width * 0.3,
                        ),
                      ]
                  )
              );
            }
        );

     }
    );
  }

  Future<int> _changeQuantity() async {

    if (_newQuantityItemUnitOfMeasure == null || _newQuantityController.text.isEmpty) {

      throw new Exception("quantity is empty");
    }
    int newQuantity = int.parse(_newQuantityController.text);
    // let's get the actual quantity
    newQuantity = newQuantity * (_newQuantityItemUnitOfMeasure?.quantity ?? 0);

    if (newQuantity == (widget.inventory?.quantity ?? 0)) {
      // quantity not changed, let's do nothing
      return newQuantity;
    }
    else if (newQuantity == 0) {
      // remove the inventory
      showLoading(context);
      await InventoryService.removeInventory(widget.inventory!.id!);
      Navigator.of(context).pop();
      return newQuantity;
    }
    else {
      showLoading(context);
      await InventoryService.changeQuantity(widget.inventory!.id!, newQuantity);
      Navigator.of(context).pop();
      return newQuantity;
    }
  }


  List<DropdownMenuItem<ItemUnitOfMeasure>> _getItemUnitOfMeasures() {
    List<DropdownMenuItem<ItemUnitOfMeasure>> items = [];


    for (int i = 0; i < widget.inventory!.itemPackageType!.itemUnitOfMeasures.length; i++) {

      items.add(DropdownMenuItem(
        value:  widget.inventory!.itemPackageType!.itemUnitOfMeasures[i],
        child: Text( widget.inventory!.itemPackageType!.itemUnitOfMeasures[i].unitOfMeasure?.name ?? ""),
      ));
    }

    return items;
  }


  Future<void> _openChangeStatusDialog() async {
    printLongLogMessage("start to change status for inventory ${widget.inventory?.id} / ${widget.inventory?.lpn}");

    showLoading(context);

    // get all inventory status to display

    List<InventoryStatus> _validInventoryStatus = await InventoryStatusService.getAllInventoryStatus();

    /**
        _newQuantityItemUnitOfMeasure = widget.inventory?.itemPackageType?.itemUnitOfMeasures.firstWhere(
        (itemUnitOfMeasure) => itemUnitOfMeasure.unitOfMeasure?.id == widget.inventoryQuantityForDisplay.displayItemUnitOfMeasure.unitOfMeasure?.id
        );
     **/

    printLongLogMessage("got ${_validInventoryStatus.length} inventory status");

    _selectedInventoryStatus = _validInventoryStatus.firstWhere(
        (inventoryStatus) => inventoryStatus.id == widget.inventory?.inventoryStatus?.id
    );
    printLongLogMessage("_selectedInventoryStatus is setup to ${_selectedInventoryStatus?.description ?? "N/A"}");
    Navigator.of(context).pop();

    await showDialog<void>(
        context: context,
        builder: (BuildContext context) {

          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState){
                return AlertDialog(
                    title: Text(CWMSLocalizations.of(context).changeQuantity),
                    content:
                    Column(
                        children: <Widget>[
                          buildTwoSectionInformationRow("${CWMSLocalizations.of(context).lpn} : ",
                              widget.inventory?.lpn ?? ""),
                          buildSingleSectionInformationRow("${CWMSLocalizations.of(context).original } ${CWMSLocalizations.of(context).inventoryStatus } : "),
                          buildSingleSectionInformationRow(
                              widget.inventoryQuantityForDisplay.inventory.inventoryStatus?.description ?? ""),
                          buildSingleSectionInformationRow("${CWMSLocalizations.of(context).newValue } ${CWMSLocalizations.of(context).inventoryStatus } : "),
                          buildSingleSectionInputRow(
                              DropdownButton(
                                hint: Text(CWMSLocalizations.of(context).select),
                                items: _getInventoryStatusItems(_validInventoryStatus),
                                value: _selectedInventoryStatus,
                                elevation: 1,
                                isExpanded: true,
                                icon: Icon(
                                  Icons.list,
                                  size: 20,
                                ),
                                onChanged: (InventoryStatus? value) {
                                  printLongLogMessage("invenotry status to ${value?.name}");
                                  //下拉菜单item点击之后的回调
                                  setState(() {
                                    _selectedInventoryStatus = value;
                                  });
                                },
                              )
                          ),
                          buildTwoButtonRowWithWidth(context,
                            ElevatedButton(
                              child: Text(CWMSLocalizations.of(context).cancel),
                              onPressed: () {
                                _onStatusChanged(widget.inventory!.inventoryStatus!);
                                Navigator.of(context).pop();
                              },
                            ),
                            MediaQuery.of(context).size.width * 0.3,
                            ElevatedButton(
                              child: Text(CWMSLocalizations.of(context).confirm),
                              onPressed: _selectedInventoryStatus == null  ? null :
                                  ()  async {
                                    try {

                                      await _changeStatus();
                                      _onStatusChanged(_selectedInventoryStatus!);
                                      Navigator.of(context).pop();
                                    }
                                    on Exception catch(ex) {
                                      showToast(ex.toString());
                                    }
                                  },
                            ),
                            MediaQuery.of(context).size.width * 0.3,
                          ),
                        ]
                    )
                );
              }
          );

        }
    );
  }

  Future<void> _changeStatus() async {

    if (_selectedInventoryStatus == null) {

      throw new Exception("no inventory status is selected");
    }
    if (widget.inventory?.inventoryStatus?.id != _selectedInventoryStatus!.id) {
      widget.inventory?.inventoryStatus = _selectedInventoryStatus;

      showLoading(context);
      await InventoryService.changeInventory(widget.inventory!);
      Navigator.of(context).pop();
    }
  }

  List<DropdownMenuItem<InventoryStatus>> _getInventoryStatusItems(List<InventoryStatus> validInventoryStatus) {
    List<DropdownMenuItem<InventoryStatus>> items = [];
    if (validInventoryStatus == null || validInventoryStatus.length == 0) {
      return items;
    }

    // _selectedInventoryStatus = _validInventoryStatus[0];
    for (int i = 0; i < validInventoryStatus.length; i++) {
      items.add(DropdownMenuItem(
        value: validInventoryStatus[i],
        child: Text(validInventoryStatus[i].description ?? ""),
      ));
    }

    if (validInventoryStatus.length == 1 ||
        _selectedInventoryStatus == null) {
      // if we only have one valid inventory status, then
      // default the selection to it
      // if the user has not select any inventdry status yet, then
      // default the value to the first option as well
      _selectedInventoryStatus = validInventoryStatus[0];
    }
    return items;
  }

}
