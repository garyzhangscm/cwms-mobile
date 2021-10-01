import 'package:badges/badges.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inbound/models/receipt.dart';
import 'package:cwms_mobile/inbound/models/receipt_line.dart';
import 'package:cwms_mobile/inbound/services/receipt.dart';
import 'package:cwms_mobile/inbound/widgets/receipt_line_list_item.dart';
import 'package:cwms_mobile/inbound/widgets/receipt_list_item.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
import 'package:cwms_mobile/inventory/services/item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class InventoryLostFoundPage extends StatefulWidget{

  InventoryLostFoundPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _InventoryLostFoundPageState();

}

class _InventoryLostFoundPageState extends State<InventoryLostFoundPage> {

  // input batch id

  TextEditingController _itemController = new TextEditingController();
  TextEditingController _quantityController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();


  List<InventoryStatus> _validInventoryStatus;
  InventoryStatus _selectedInventoryStatus;
  ItemPackageType _selectedItemPackageType;
  Item item;

  List<Inventory>  inventoryOnRF = [];

  @override
  void initState() {
    super.initState();
    _selectedInventoryStatus = new InventoryStatus();
    _selectedItemPackageType = new ItemPackageType();

    // get all inventory status to display
    InventoryStatusService.getAllInventoryStatus()
        .then((value) {
      setState(() {
        _validInventoryStatus = value;
        if (_validInventoryStatus.length > 0) {
          _selectedInventoryStatus = _validInventoryStatus[0];
        }
      });
    });


    inventoryOnRF = [];

    _reloadInventoryOnRF();
  }
  final  _formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).inventoryAdjust)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              // show RF as the destination location of the adjust LPN
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                          Text(CWMSLocalizations.of(context).location,
                            textAlign: TextAlign.left,
                          ),
                      ),
                      Text(Global.lastLoginRFCode,
                        textAlign: TextAlign.left,
                      ),
                    ]
                ),
              ),
              // ask the user to input item number
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                // confirm the location
                Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                            Text(CWMSLocalizations.of(context).item,
                              textAlign: TextAlign.left,
                            ),
                      ),
                      Expanded(
                        child:
                        Focus(
                          child: TextFormField(
                              controller: _itemController,
                              // 校验ITEM NUMBER（不能为空）
                              validator: (v) {
                                if (v.trim().isEmpty) {
                                  return CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).item);
                                }

                                return null;
                              }),
                          onFocusChange: (hasFocus) {
                            if (!hasFocus && _itemController.text
                                .trim()
                                .isNotEmpty) {
                              ItemService.getItemByName(
                                  _itemController.text.trim()).then(
                                      (itemRes) {
                                        if (itemRes != null) {
                                          // we find the item by name, let's save it
                                          setState(() {
                                            item = itemRes;
                                          });
                                        }

                                  });
                            }
                          }
                        ),
                      )

                    ]
                ),
              ),
              // Allow the user to choose item package type
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                Row(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                            Text(CWMSLocalizations.of(context).itemPackageType,
                              textAlign: TextAlign.left,
                            ),
                      ),
                      Expanded(
                          child:
                          DropdownButton(
                            hint: Text(""),
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
                          )
                      )
                    ]
                ),
              ),
              // Allow the user to choose inventory status
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                Row(
                    children: <Widget>[

                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                            Text(CWMSLocalizations.of(context).inventoryStatus,
                              textAlign: TextAlign.left,
                            ),
                      ),
                      Expanded(
                          child:
                          DropdownButton(
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
                              //下拉菜单item点击之后的回调
                              setState(() {
                                _selectedInventoryStatus = T;
                              });
                            },
                          )
                      )
                    ]
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                // always force the user to input / confirm the quantity
                // picked this time
                Row(
                    children: <Widget>[

                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                            Text(CWMSLocalizations
                                .of(context)
                                .quantity + ": ",
                              textAlign: TextAlign.left,
                            ),
                      ),
                      Expanded(
                        child:
                        Focus(
                          child: TextFormField(
                              keyboardType: TextInputType.number,
                              controller: _quantityController,
                              // 校验ITEM NUMBER（不能为空）
                              validator: (v) {
                                if (v.trim().isEmpty) {
                                  return "please type in quantity";
                                }

                                return null;
                              }),
                        ),
                      )
                    ]
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 5, bottom: 5),
                child:
                // always force the user to input / confirm the quantity
                // picked this time
                Row(
                    children: <Widget>[

                      Padding(
                        padding: EdgeInsets.only(right: 20),
                        child:
                            Text(CWMSLocalizations
                                .of(context)
                                .lpn+ ": ",
                              textAlign: TextAlign.left,
                            ),
                      ),
                      Expanded(
                        child:
                        Focus(

                          child: SystemControllerNumberTextBox(
                              type: "lpn",
                              controller: _lpnController,
                              readOnly: false,
                              validator: (v) {
                                if (v.trim().isEmpty) {
                                  return CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).lpn);
                                }

                                return null;
                              }),
                        ),
                      )
                    ]
                ),
              ),
              _buildButtons(context)

            ],
          ),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return
      Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        //交叉轴的布局方式，对于column来说就是水平方向的布局方式
        crossAxisAlignment: CrossAxisAlignment.center,
        //就是字child的垂直布局方向，向上还是向下
        verticalDirection: VerticalDirection.down,
        children: [
          // button to confirm receiving
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child:
            RaisedButton(
              color: Theme.of(context).primaryColor,

              onPressed: item == null ? null :
                  () {
                    if (_formKey.currentState.validate()) {
                      print("form validation passed");
                      _onInventoryAdjustConfirm();
                    }

                  },
              textColor: Colors.white,
              child: Text(CWMSLocalizations
                  .of(context)
                  .confirm),
            ),

          ),
          // button to deposit inventory
          Padding(
              padding: const EdgeInsets.only(left: 10),
              child:
              Badge(
                showBadge: true,
                padding: EdgeInsets.all(8),
                badgeColor: Colors.deepPurple,
                badgeContent: Text(
                  inventoryOnRF.length.toString(),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                child: RaisedButton(
                  onPressed: inventoryOnRF.length == 0 ? null : _startDeposit,
                  child: Text(CWMSLocalizations.of(context).depositInventory),
                ),
              )
          ),
        ],
      );
  }

  // call the deposit form to deposit the inventory on the RF
  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the inventory on the RF
    _reloadInventoryOnRF();
  }

  /***
   *
      Widget _buildButtons(BuildContext context) {
      return
      SizedBox(
      width: double.infinity,
      height: 50,
      child:
      Row(
      children: <Widget> [
      Expanded(
      child:
      Padding(
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      child:
      ElevatedButton(
      onPressed: () {
      if (_formKey.currentState.validate()) {
      print("form validation passed");
      _onInventoryAdjustConfirm();
      }

      },
      child: Text(CWMSLocalizations
      .of(context)
      .confirm),
      ),
      ),
      ),
      ]
      )

      );
      }
   */




  List<DropdownMenuItem> _getInventoryStatusItems() {
    List<DropdownMenuItem> items = new List();
    if (_validInventoryStatus == null || _validInventoryStatus.length == 0) {
      return items;
    }

    _selectedInventoryStatus = _validInventoryStatus[0];
    for (int i = 0; i < _validInventoryStatus.length; i++) {
      print("start to create download list for _getInventoryStatusItems: ");
      items.add(DropdownMenuItem(
        value: _validInventoryStatus[i],
        child: Text(_validInventoryStatus[i].description),
      ));
    }
    return items;
  }

  List<DropdownMenuItem> _getItemPackageTypeItems() {
    List<DropdownMenuItem> items = new List();

    if (item != null && item.itemPackageTypes.length > 0) {
      _selectedItemPackageType = item.itemPackageTypes[0];

      for (int i = 0; i < item.itemPackageTypes.length; i++) {

        items.add(DropdownMenuItem(
          value: item.itemPackageTypes[i],
          child: Text(item.itemPackageTypes[i].description),
        ));
      }
    }
    return items;
  }




  void _onInventoryAdjustConfirm() async {

    showLoading(context);

    print("inventory adjust!");
    // refresh the work order to reflect the produced quantity
    Inventory inventory = new Inventory();
    inventory.item = item;
    inventory.quantity = int.parse(_quantityController.text);
    WarehouseLocation rfLocation = await WarehouseLocationService.getWarehouseLocationByName(
        Global.lastLoginRFCode
    );
    inventory.location = rfLocation;
    inventory.locationId = rfLocation.id;
    inventory.lpn = _lpnController.text;
    inventory.warehouseId = Global.currentWarehouse.id;
    inventory.inventoryStatus = _selectedInventoryStatus;
    inventory.itemPackageType = _selectedItemPackageType;
    inventory.virtual = false;
    try {
      await InventoryService.addInventory(inventory);
    }
    on WebAPICallException catch(ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }
    Navigator.of(context).pop();
    showToast("inventory adjust complete");
    // we will allow the user to continue receiving with the same
    // receipt and line
    _lpnController.clear();
    _quantityController.clear();
    _itemController.clear();
    setState(() {
      item = null;
    });

    // refresh the inventory on the RF
    _reloadInventoryOnRF();

  }

  void _reloadInventoryOnRF() {

    InventoryService.getInventoryOnCurrentRF()
        .then((value) {
      setState(() {
        inventoryOnRF = value;
      });
    });

  }



}