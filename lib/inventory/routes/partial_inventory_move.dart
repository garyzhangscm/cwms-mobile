import 'dart:collection';

import 'package:badges/badges.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/widgets/inventory_deposit_request_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/item.dart';
import '../models/item_unit_of_measure.dart';

// Page to allow the user scan in an LPN and start the put away process
// The LPN can be in receiving stage / storage location / etc
// with or without any pre-assigned destination
class PartialInventoryMovePage extends StatefulWidget{

  PartialInventoryMovePage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _PartialInventoryMovePageState();

}

class _PartialInventoryMovePageState extends State<PartialInventoryMovePage> {

  // allow user to scan in LPN
  TextEditingController _lpnController = new TextEditingController();
  GlobalKey _formKey = new GlobalKey<FormState>();
  TextEditingController _quantityController = new TextEditingController();
  FocusNode _quantityFocusNode = FocusNode();
  ItemUnitOfMeasure _selectedItemUnitOfMeasure;


  List<Inventory>  inventoryOnRF;

  FocusNode _lpnFocusNode = FocusNode();

  var _itemNames = Set<String>();
  Map<String, Item> _itemMap = HashMap();
  var _selectedItemName = "";


  @override
  void initState() {
    super.initState();

    inventoryOnRF = [];
    _itemNames = Set<String>();
    _itemMap.clear();
    _selectedItemName = "";

    _lpnFocusNode.addListener(() {
      print("lpnFocusNode.hasFocus: ${_lpnFocusNode.hasFocus}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
        _onLoadingLPNInformation();
      }
    });

    _reloadInventoryOnRF();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("CWMS - Partial Inventory Move")),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[

              _buildLPNController(context),
              _itemNames.isEmpty ?
                Container() :
                  _itemNames.length == 1 ?
                      _buildItemInformation(context, _itemNames.first)
                      :
                      _builItemController(context),
              _selectedItemName == "" ?
                  Container() :
                  _builItemDescriptionController(context),
              _buildQuantityController(context),
              _buildButtons(context),
              _buildDepositRequestList(context)
            ],
          ),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildLPNController(BuildContext context) {
    return buildTwoSectionInputRow(CWMSLocalizations.of(context).lpn,
        TextFormField(
            controller: _lpnController,
            autofocus: true,
            // 校验用户名（不能为空）
            validator: (v) {
              return v.trim().isNotEmpty ?
              null :
              CWMSLocalizations.of(context).missingField(
                  CWMSLocalizations.of(context).lpn);
            })
    );
  }
  Widget _buildItemInformation(BuildContext context, String itemName) {
    return buildTwoSectionInformationRow(
        CWMSLocalizations.of(context).item,
        itemName);
  }

  Widget _builItemController(BuildContext context) {
    return DropdownButton(
      // hint: Text(CWMSLocalizations.of(context).pleaseSelect),
      items: _getItemNames(),
      value: _selectedItemName,
      elevation: 1,
      isExpanded: true,
      icon: Icon(
        Icons.list,
        size: 20,
      ),
      onChanged: (T) {
        //下拉菜单item点击之后的回调
        setState(() {
          _selectedItemName = T;
        });
      },
    );
  }

  _builItemDescriptionController(BuildContext context) {

    if (_itemMap.containsKey(_selectedItemName)) {

      return buildTwoSectionInformationRow(
          CWMSLocalizations.of(context).item,
          _itemMap.putIfAbsent(_selectedItemName, () => null).description);
    }

    return buildTwoSectionInformationRow(
        CWMSLocalizations.of(context).item, "");
  }

  _buildQuantityController(BuildContext context) {
    return
      buildThreeSectionInputRow(
        CWMSLocalizations.of(context).quantity,
        TextFormField(
            keyboardType: TextInputType.number,
            controller: _quantityController,
            textInputAction: TextInputAction.next,
            autofocus: true,
            focusNode: _quantityFocusNode,
            onFieldSubmitted: (v){
              printLongLogMessage("start to focus on lpn node");
              _lpnFocusNode.requestFocus();

            },
            decoration: InputDecoration(
                isDense: true
            ),
            // 校验ITEM NUMBER（不能为空）
            validator: (v) {
              if (v.trim().isEmpty) {
                return "please type in quantity";
              }
              if (!_validateQuantity()) {

                return "over receive is not allowed";
              }
              return null;
            }),
        _getItemUnitOfMeasures().isEmpty ?
          Container() :
          DropdownButton(
            hint: Text(CWMSLocalizations.of(context).pleaseSelect),
            items: _getItemUnitOfMeasures(),
            value: _selectedItemUnitOfMeasure,
            elevation: 1,
            isExpanded: true,
            icon: Icon(
              Icons.list,
              size: 20,
            ),
            onChanged: (T) {
              //下拉菜单item点击之后的回调
              setState(() {
                _selectedItemUnitOfMeasure = T;
              });
            },
          )
      );
  }

  List<DropdownMenuItem> _getItemUnitOfMeasures() {

    List<DropdownMenuItem> dropdownMenuItems = [];

    if (!_itemMap.containsKey(_selectedItemName)) {

      return dropdownMenuItems;
    }
    Item item = _itemMap.putIfAbsent(_selectedItemName, () => null);

    for (int i = 0; i < item.defaultItemPackageType.itemUnitOfMeasures.length; i++) {

      dropdownMenuItems.add(DropdownMenuItem(
        value:  item.defaultItemPackageType.itemUnitOfMeasures[i],
        child: Text(item.defaultItemPackageType.itemUnitOfMeasures[i].unitOfMeasure.name),
      ));
    }

  }

  bool _validateQuantity() {
    return true;
  }
  List<DropdownMenuItem> _getItemNames() {
    List<DropdownMenuItem> dropdownMenuItems = [];

    _itemNames.forEach((itemName) {
      dropdownMenuItems.add(DropdownMenuItem(
        value: itemName,
        child: Text(itemName),
      ));
    });

    return dropdownMenuItems;
  }

  void _onLoadingLPNInformation() async {

    if (_lpnController.text.isEmpty) {

      showErrorDialog(context, "please input the LPN number");
      return;
    }

    _loadItemsFromLPN(_lpnController.text);
  }

  /// Get the items from the LPN
  Future<void> _loadItemsFromLPN(String lpn) async {
    if (lpn.trim().isEmpty) {
      // if the user hasn't input the LPN, return an empty list
      return new Set();
    }
    // get the invetory from the LPN

    showLoading(context);
    List<Inventory> inventories = await InventoryService.findInventory(lpn :_lpnController.text, includeDetails: false);

    inventories.forEach((inventory) {
      _itemNames.add(inventory.item.name);
      _itemMap.putIfAbsent(inventory.item.name, () => inventory.item);

    });

    Navigator.of(context).pop();
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
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child:
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                // onPressed: _onAddingLPN,
                child: Text(CWMSLocalizations.of(context).add),
              ),

          ),

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
                child:
                  ElevatedButton(
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




  Widget _buildDepositRequestList(BuildContext context) {
    List<InventoryDepositRequest> inventoryDepositRequests =
        InventoryService.getInventoryDepositRequests(inventoryOnRF, true, true);
    return
      Expanded(
        child: ListView.builder(
            itemCount: inventoryDepositRequests.length,
            itemBuilder: (BuildContext context, int index) {

              return InventoryDepositRequestItem(
                  index: index,
                  inventoryDepositRequest: inventoryDepositRequests[index],
              );
            }),
      );
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