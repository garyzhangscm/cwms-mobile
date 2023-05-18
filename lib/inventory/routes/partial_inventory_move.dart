import 'dart:async';
import 'dart:collection';

import 'package:badges/badges.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/widgets/inventory_deposit_request_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../exception/WebAPICallException.dart';
import '../../shared/global.dart';
import '../../shared/http_client.dart';
import '../../warehouse_layout/services/warehouse_location.dart';
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
  ItemUnitOfMeasure _selectedItemUnitOfMeasure;


  List<Inventory>  inventoryOnRF;

  FocusNode _lpnFocusNode = FocusNode();

  var _itemNames = Set<String>();
  Map<String, Item> _itemMap = HashMap();
  // map to save the total quantity of the map so that
  // the partial move won't exceed the total quantity of the
  // item on the LPN
  Map<String, int> _itemQuantityMap = HashMap();
  var _selectedItemName = "";
  Timer _timer;  // timer to refresh inventory on RF every 2 second


  @override
  void initState() {
    super.initState();

    inventoryOnRF = [];
    _itemNames = Set<String>();
    _itemMap.clear();
    _itemQuantityMap.clear();
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
  void dispose() {
    super.dispose();
    // remove any timer so we won't need to load the next work again after
    // the user return from this page
    _timer?.cancel();


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
              _selectedItemName == "" ?
                Container() :
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
            focusNode: _lpnFocusNode,
            decoration: InputDecoration(
              suffixIcon:
                IconButton(
                  onPressed: () => _clearLPN(),
                  icon: Icon(Icons.close),
                ),
            ),
            validator: (v) {
              return v.trim().isNotEmpty ?
              null :
              CWMSLocalizations.of(context).missingField(
                  CWMSLocalizations.of(context).lpn);
            })
    );
  }

  void _clearLPN() {

    setState(() {
      _lpnController.text = "";
      _itemNames = Set<String>();
      _itemMap.clear();
      _itemQuantityMap.clear();
      _selectedItemName = "";
    });

    _lpnFocusNode.requestFocus();
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
            autofocus: true,
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
            underline: Container(
              height: 0,
              color: Colors.deepPurpleAccent,
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
    if (item.defaultItemPackageType.itemUnitOfMeasures.length == 1) {
      _selectedItemUnitOfMeasure = item.defaultItemPackageType.itemUnitOfMeasures[0];
    }
    return dropdownMenuItems;
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

  // load the inventory information that is associated with the LPN
  // if there's only one item on the LPN, then display the item
  // otherwise, list all the items and let the user choose one
  // to move
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
      return;
    }
    // get the invetory from the LPN

    showLoading(context);
    List<Inventory> inventories = await InventoryService.findInventory(lpn :_lpnController.text, includeDetails: true);

    if (inventories.isEmpty) {

      Navigator.of(context).pop();
      showToast(CWMSLocalizations.of(context).noInventoryFound);
      _clearLPN();
      return;
    }
    inventories.forEach((inventory) {
      _itemNames.add(inventory.item.name);
      _itemMap[inventory.item.name] = inventory.item;
      int accumulativeQuantity = _itemQuantityMap.putIfAbsent(inventory.item.name, () => 0);
      _itemQuantityMap[inventory.item.name] = accumulativeQuantity + inventory.quantity;

    });

    _itemMap.forEach((key, value) {
      printLongLogMessage("item \n================= ${key}       ===============");
      printLongLogMessage("${value.toJson()}");
    });

    setState(() {
      _itemNames;
      _itemMap;
      _itemQuantityMap;
      if (_itemMap.isNotEmpty) {
        printLongLogMessage("get ${_itemMap.length} items");

        _selectedItemName = _itemNames.first;
      }
    });

    Navigator.of(context).pop();
  }

  Widget _buildButtons(BuildContext context) {

    return buildTwoButtonRow(context,
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Theme.of(context).primaryColor,
          ),
          onPressed: _lpnController.text.isNotEmpty && _selectedItemName != "" &&
                     _selectedItemUnitOfMeasure != null && _quantityController.text.isNotEmpty ?
              _onAddingLPN : null,
          child: Text(CWMSLocalizations.of(context).add),
        ),

        Badge(
          showBadge: true,
          padding: EdgeInsets.all(8),
          badgeColor: Colors.deepPurple,
          badgeContent: Text(
            inventoryOnRF.length.toString(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          child:
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              onPressed: inventoryOnRF.length == 0 ? null : _startDeposit,
              child: Text(CWMSLocalizations.of(context).depositInventory),
            ),
          ),
        )
    );
      /**
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
          **/
  }

  // call the deposit form to deposit the inventory on the RF
  Future<void> _startDeposit() async {
    _timer?.cancel();
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the inventory on the RF
    // when we come back from the deposit page, we will refresh
    // 3 times as the deposit happens async so when we return from
    // the deposit page, the last deposit may not be actually done yet
    _reloadInventoryOnRF(refreshCount: 3);
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



  void _onAddingLPN() {

      // showLoading(context);
      // move the inventory being scanned onto RF
      printLongLogMessage("==>> Start to adding LPN for deposit");
      printLongLogMessage("quantity: ${_quantityController.text}");

      int quantity = int.parse(_quantityController.text);
      String lpn = _lpnController.text;
      _moveInventoryAsync(lpn, quantity,
          _selectedItemName,
          _selectedItemUnitOfMeasure.unitOfMeasure.name,
          retryTime: 0);

      // Navigator.of(context).pop();
      _clearLPN();

      showToast("LPN putaway request sent");
      // showToast(CWMSLocalizations.of(context).actionComplete);
  }


  void _moveInventoryAsync(String lpn, int quantity,
      String itemName, String unitOfMeasure,  {int retryTime = 0}) {
    WarehouseLocationService.getWarehouseLocationByName(
        Global.lastLoginRFCode
    ).then((rfLocation) async {
      await InventoryService.moveInventory(
          lpn: lpn,
          quantity: quantity,
          itemName: itemName,
          unitOfMeasure: unitOfMeasure,
          destinationLocation: rfLocation
      );
      _reloadInventoryOnRF();
    }).catchError((err) {
      printLongLogMessage("Get error, let's prepare for retry, we have retried $retryTime, capped at ${CWMSHttpClient.timeoutRetryTime}");
      if (err is DioError &&
          // err.type == DioErrorType.connectTimeout &&
          retryTime <= CWMSHttpClient.timeoutRetryTime) {
        // for timeout error and we are still in the retry threshold, let's try again

        if (retryTime <= CWMSHttpClient.timeoutRetryTime) {

          Future.delayed(const Duration(milliseconds: 2000),
                  () => _moveInventoryAsync(lpn, quantity,
                  itemName, unitOfMeasure, retryTime: retryTime + 1));
        }
        else {
          // do nothing as we already running out of retry time
          showErrorDialog(context, "Fail to move LPN: " + lpn + " after trying ${CWMSHttpClient.timeoutRetryTime}  times");
        }


      }
      else if (err is WebAPICallException){
        // for any other error display it
        final webAPICallException = err as WebAPICallException;
        showErrorDialog(context, webAPICallException.errMsg() + ", LPN: " + lpn);
      }
      else {

        showErrorDialog(context, err.toString() + ", LPN: " + lpn);
      }
    });
  }
  void _reloadInventoryOnRF({int refreshCount = 0}) {

    InventoryService.getInventoryOnCurrentRF()
        .then((value) {
      setState(() {
        inventoryOnRF = value;
        if (refreshCount > 0) {

          _timer = Timer(new Duration(seconds: 2), () {
            this._reloadInventoryOnRF(refreshCount: refreshCount - 1);
          });
        }
        else {
          _timer?.cancel();
        }
      });
    });

  }

}