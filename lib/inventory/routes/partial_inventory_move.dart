import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:badges/badges.dart' as badge;
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../../exception/WebAPICallException.dart';
import '../../shared/global.dart';
import '../../shared/http_client.dart';
import '../../warehouse_layout/services/warehouse_location.dart';
import '../models/item.dart';
import '../models/item_unit_of_measure.dart';

import '../../shared/services/barcode_service.dart';
import '../../shared/models/barcode.dart';

// Page to allow the user scan in an LPN and start the put away process
// The LPN can be in receiving stage / storage location / etc
// with or without any pre-assigned destination
class PartialInventoryMovePage extends StatefulWidget{

  PartialInventoryMovePage({Key? key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _PartialInventoryMovePageState();

}

class _PartialInventoryMovePageState extends State<PartialInventoryMovePage> {

  // allow user to scan in LPN
  TextEditingController _lpnController = new TextEditingController();
  GlobalKey _formKey = new GlobalKey<FormState>();
  TextEditingController _quantityController = new TextEditingController();
  ItemUnitOfMeasure? _selectedItemUnitOfMeasure;


  List<Inventory>  inventoryOnRF = [];

  FocusNode _lpnFocusNode = FocusNode();

  var _itemNames = Set<String>();
  Map<String, Item> _itemMap = HashMap();
  // map to save the total quantity of the map so that
  // the partial move won't exceed the total quantity of the
  // item on the LPN
  Map<String, int> _itemQuantityMap = HashMap();
  var _selectedItemName = "";
  Timer? _timer;  // timer to refresh inventory on RF every 2 second


  List<InventoryDepositRequest> _inventoryDepositRequests = [];

  @override
  void initState() {
    super.initState();

    inventoryOnRF = [];
    _itemNames = Set<String>();
    _itemMap.clear();
    _itemQuantityMap.clear();
    _selectedItemName = "";
    _inventoryDepositRequests = [];

    _lpnFocusNode.addListener(() {
      print("lpnFocusNode.hasFocus: ${_lpnFocusNode.hasFocus}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
        // allow the user to input barcode

        Barcode barcode = BarcodeService.parseBarcode(_lpnController.text);
        if (barcode.is_2d == true) {
          // for 2d barcode, let's get the result and set the LPN back to the text
          String lpn = BarcodeService.getLPN(barcode);
          printLongLogMessage("get lpn from lpn?: ${lpn}");
          if (lpn == "") {

            showErrorDialog(context, "can't get LPN from the barcode");
            return;
          }
          else {
            _lpnController.text = lpn;
          }
        }

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
    return buildTwoSectionInputRow(CWMSLocalizations.of(context)!.lpn,
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
              return v!.trim().isNotEmpty ?
              null :
              CWMSLocalizations.of(context)!.missingField(
                  CWMSLocalizations.of(context)!.lpn);
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
    _inventoryDepositRequests = [];
  }
  Widget _buildItemInformation(BuildContext context, String itemName) {
    return buildTwoSectionInformationRow(
        CWMSLocalizations.of(context)!.item,
        itemName);
  }

  Widget _builItemController(BuildContext context) {
    return DropdownButton(
      // hint: Text(CWMSLocalizations.of(context)!.pleaseSelect),
      items: _getItemNames(),
      value: _selectedItemName,
      elevation: 1,
      isExpanded: true,
      icon: Icon(
        Icons.list,
        size: 20,
      ),
      onChanged: (String? value) {
        //下拉菜单item点击之后的回调
        setState(() {
          _selectedItemName = value!;
        });
      },
    );
  }

  _builItemDescriptionController(BuildContext context) {

    if (_itemMap.containsKey(_selectedItemName)) {

      return buildTwoSectionInformationRow(
          CWMSLocalizations.of(context)!.item,
          _itemMap[_selectedItemName]?.description ?? "");
    }

    return buildTwoSectionInformationRow(
        CWMSLocalizations.of(context)!.item, "");
  }

  _buildQuantityController(BuildContext context) {
    return
      buildThreeSectionInputRow(
        CWMSLocalizations.of(context)!.quantity,
        TextFormField(
            keyboardType: TextInputType.number,
            controller: _quantityController,
            autofocus: true,
            decoration: InputDecoration(
                isDense: true
            ),
            // 校验ITEM NUMBER（不能为空）
            validator: (v) {
              if (v!.trim().isEmpty) {
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
            hint: Text(CWMSLocalizations.of(context)!.pleaseSelect),
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
            onChanged: (ItemUnitOfMeasure? value) {
              //下拉菜单item点击之后的回调
              setState(() {
                _selectedItemUnitOfMeasure = value;
              });
            },
          )
      );
  }

  List<DropdownMenuItem<ItemUnitOfMeasure>> _getItemUnitOfMeasures() {

    List<DropdownMenuItem<ItemUnitOfMeasure>> dropdownMenuItems = [];

    if (!_itemMap.containsKey(_selectedItemName)) {

      return dropdownMenuItems;
    }
    Item item = _itemMap[_selectedItemName]!;

    for (int i = 0; i < item.defaultItemPackageType!.itemUnitOfMeasures.length; i++) {

      dropdownMenuItems.add(DropdownMenuItem(
        value:  item.defaultItemPackageType?.itemUnitOfMeasures[i],
        child: Text(item.defaultItemPackageType?.itemUnitOfMeasures[i].unitOfMeasure!.name ?? ""),
      ));
    }

    // we may have _selectedItemUnitOfMeasure setup by previous item package type.
    // or manually by user. If it is setup by the user, then we won't refresh it
    // otherwise, we will reload the default receiving uom
    // if _selectedItemPackageType.itemUnitOfMeasures doesn't containers the _selectedItemUnitOfMeasure
    // then we know that we just changed the item package type or item, so we will need
    // to refresh the _selectedItemUnitOfMeasure to the default inbound receiving uom as well
    if (_selectedItemUnitOfMeasure == null ||
        !item.defaultItemPackageType!.itemUnitOfMeasures.any((element) => element.hashCode == _selectedItemUnitOfMeasure.hashCode)) {
      // if the user has not select any item unit of measure yet, then
      // default the value to the one marked as 'default for inbound receiving'

      _selectedItemUnitOfMeasure = item.defaultItemPackageType?.itemUnitOfMeasures
          .firstWhereOrNull((element) => element.id == item.defaultItemPackageType?.defaultInboundReceivingUOM?.id);
    }
/**
    if (item.defaultItemPackageType.itemUnitOfMeasures.length == 1) {
      _selectedItemUnitOfMeasure = item.defaultItemPackageType.itemUnitOfMeasures[0];
    }
    **/
    return dropdownMenuItems;
  }

  bool _validateQuantity() {
    return true;
  }
  List<DropdownMenuItem<String>> _getItemNames() {
    List<DropdownMenuItem<String>> dropdownMenuItems = [];

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
      showToast(CWMSLocalizations.of(context)!.noInventoryFound);
      _clearLPN();
      return;
    }
    inventories.forEach((inventory) {
      _itemNames.add(inventory.item!.name!);
      _itemMap[inventory.item!.name!] = inventory.item!;
      int accumulativeQuantity = _itemQuantityMap.putIfAbsent(inventory.item!.name!, () => 0);
      _itemQuantityMap[inventory.item!.name!] = accumulativeQuantity + inventory!.quantity!;

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
          child: Text(CWMSLocalizations.of(context)!.add),
        ),

        badge.Badge(
          showBadge: true,
          badgeStyle: badge.BadgeStyle(
            padding: EdgeInsets.all(8),
            badgeColor: Colors.deepPurple,
          ),
          badgeContent: Text(
            inventoryOnRF.length.toString(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          child:
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              onPressed: inventoryOnRF.length == 0 ? null : _startDeposit,
              child: Text(CWMSLocalizations.of(context)!.depositInventory),
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
                child: Text(CWMSLocalizations.of(context)!.add),
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
                    child: Text(CWMSLocalizations.of(context)!.depositInventory),
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
    _inventoryDepositRequests = [];
  }




  Widget _buildDepositRequestList(BuildContext context) {
    /**
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
**/
    return
      Expanded(
          child: ListView.separated(
            itemCount: _inventoryDepositRequests.length,
            itemBuilder: (BuildContext context, int index) {

              return _buildInventoryDepositRequestListTile(context, index);
            },
            separatorBuilder: (context, index) => Divider(
              color: Colors.black,
            ),
          )
      );
  }


  Widget _buildInventoryDepositRequestListTile(BuildContext context, int index) {

    printLongLogMessage("index ${index}");
    printLongLogMessage("_reversedInventories[index].reverseInProgress: ${_inventoryDepositRequests[index].requestInProcess}");
    printLongLogMessage("_reversedInventories[index].reverseInProgress: ${_inventoryDepositRequests[index].requestResult}");

    if (_inventoryDepositRequests[index].requestInProcess == true) {
      // show loading indicator if the inventory still reverse in progress
      printLongLogMessage("show loading for index $index / ${_inventoryDepositRequests[index].lpn}");
      return SizedBox(
          height: 75,
          child:  Stack(
            alignment:Alignment.center ,
            fit: StackFit.expand, //未定位widget占满Stack整个空间
            children: <Widget>[
              ListTile(
                title: Text(CWMSLocalizations.of(context).lpn + ": " + _inventoryDepositRequests[index].lpn!),
                subtitle:
                Column(
                    children: <Widget>[
                      Row(
                          children: <Widget>[
                            Text(
                                CWMSLocalizations.of(context)!.item + ": ",
                                textScaleFactor: .9,
                                style: TextStyle(
                                  height: 1.15,
                                  color: Colors.blueGrey[700],
                                  fontSize: 17,
                                )
                            ),
                            Text(
                                _inventoryDepositRequests[index].itemName!,
                                textScaleFactor: .9,
                                style: TextStyle(
                                  height: 1.15,
                                  color: Colors.blueGrey[700],
                                  fontSize: 17,
                                )
                            ),
                          ]
                      ),
                      Row(
                          children: <Widget>[
                            Text(
                                CWMSLocalizations.of(context)!.quantity + ": ",
                                textScaleFactor: .9,
                                style: TextStyle(
                                  height: 1.15,
                                  color: Colors.blueGrey[700],
                                  fontSize: 17,
                                )
                            ),
                            Text(
                                _inventoryDepositRequests[index].quantity.toString(),
                                textScaleFactor: .9,
                                style: TextStyle(
                                  height: 1.15,
                                  color: Colors.blueGrey[700],
                                  fontSize: 17,
                                )
                            ),
                          ]
                      ),
                    ]
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                child:  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(children: [
                          CircularProgressIndicator()
                        ]),
                      ),
                      // Expanded(child: Container(color: Colors.amber)),
                    ]),
              ),
            ],
          )
      );
    }
    else if(_inventoryDepositRequests[index].requestResult == true) {
      return
        SizedBox(
            height: 95,
            child:
            ListTile(
              title: Text(CWMSLocalizations.of(context)!.lpn + ": " + _inventoryDepositRequests[index].newLpn!),
              subtitle:
                Column(
                  children: <Widget>[
                    Row(
                        children: <Widget>[
                          Text(
                              "From LPN: ",
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                          Text(
                              _inventoryDepositRequests[index].lpn!,
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                        ]
                    ),
                    Row(
                        children: <Widget>[
                          Text(
                              CWMSLocalizations.of(context)!.item + ": ",
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                          Text(
                              _inventoryDepositRequests[index].itemName!,
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                        ]
                    ),
                    Row(
                        children: <Widget>[
                          Text(
                              CWMSLocalizations.of(context)!.quantity + ": ",
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                          Text(
                              _inventoryDepositRequests[index].quantity.toString(),
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                        ]
                    ),

                  ]
              ),

              tileColor: Colors.lightGreen,
              trailing:
                IconButton(
                    icon: new Icon(Icons.print_rounded),
                    onPressed: () => _printLPNLabel(_inventoryDepositRequests[index].newLpn!))
            )
        );
    }
    else {
      double height = min(75 + (_inventoryDepositRequests[index].result!.length! / 50) * 15, 120);
      return
        SizedBox(
            height: height,
            child:
            ListTile(
              title: Text(CWMSLocalizations.of(context)!.lpn + ": " + _inventoryDepositRequests[index].lpn!),
              subtitle:
              Column(
                  children: <Widget>[
                    Row(
                        children: <Widget>[
                          Text(
                              CWMSLocalizations.of(context)!.item + ": ",
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                          Text(
                              _inventoryDepositRequests[index].itemName!,
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                        ]
                    ),
                    Row(
                        children: <Widget>[
                          Text(
                              CWMSLocalizations.of(context)!.quantity + ": ",
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                          Text(
                              _inventoryDepositRequests[index].quantity.toString(),
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                        ]
                    ),
                    Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(CWMSLocalizations.of(context)!.result + ": " + _inventoryDepositRequests[index].result.toString(),
                                maxLines: 3,
                                style: TextStyle(
                                    color: Colors.lightBlue,
                                    fontWeight: FontWeight.normal)),
                          ),
                        ]
                    ),
                  ]
              ),

              tileColor: Colors.amberAccent,
            )
        );

    }
  }

  void _printLPNLabel(String lpn) {
    showLoading(context);
    InventoryService.printLPNLabel(lpn).then(
            (value) =>
                Navigator.of(context).pop()
    ).catchError((err) {

      Navigator.of(context).pop();
      printLongLogMessage("error while print LPN label, error message: \n ${err.toString()}");
      showErrorDialog(context, "error while print LPN label, error message: \n ${err.toString()}");
    });
  }

  void _onAddingLPN() {

      // showLoading(context);
      // move the inventory being scanned onto RF
      printLongLogMessage("==>> Start to adding LPN for deposit");
      printLongLogMessage("quantity: ${_quantityController.text}");


      InventoryDepositRequest inventoryDepositRequest =
          new InventoryDepositRequest();
      inventoryDepositRequest.lpn = _lpnController.text;
      int quantity = int.parse(_quantityController.text);
      if (_selectedItemUnitOfMeasure != null) {
        quantity *= _selectedItemUnitOfMeasure!.quantity!;
        printLongLogMessage("by considering the selected UOM, the final quantity is ${quantity}");
      }


      inventoryDepositRequest.quantity = quantity;
      inventoryDepositRequest.itemName = _selectedItemName;

      inventoryDepositRequest.requestInProcess = true;
      inventoryDepositRequest.requestResult = false;
      inventoryDepositRequest.result = "";

      _inventoryDepositRequests.insert(0, inventoryDepositRequest);

      _moveInventoryAsync(inventoryDepositRequest,
          _selectedItemUnitOfMeasure!.unitOfMeasure!.name!,
          retryTime: 0);

      // Navigator.of(context).pop();
      showToast("LPN putaway request sent");
      setState(() {
        _lpnController.text = "";
        _itemNames = Set<String>();
        _itemMap.clear();
        _itemQuantityMap.clear();
        _selectedItemName = "";
      });

      _lpnFocusNode.requestFocus();

      // showToast(CWMSLocalizations.of(context)!.actionComplete);
  }


  void _moveInventoryAsync(InventoryDepositRequest inventoryDepositRequest, String unitOfMeasure,  {int retryTime = 0}) {
    WarehouseLocationService.getWarehouseLocationByName(
        Global.lastLoginRFCode!
    ).then((rfLocation) async {
      List<Inventory> resultInventories = await InventoryService.moveInventory(
          lpn: inventoryDepositRequest!.lpn!,
          quantity: inventoryDepositRequest!.quantity!,
          itemName: inventoryDepositRequest!.itemName!,
          unitOfMeasure: unitOfMeasure,
          destinationLocation: rfLocation
      );


      _reloadInventoryOnRF();

      inventoryDepositRequest.newLpn = resultInventories[0].lpn;
      inventoryDepositRequest.requestInProcess = false;
      inventoryDepositRequest.requestResult = true;
      inventoryDepositRequest.result = "";

      setState(() {
        _inventoryDepositRequests;
      });
    }).catchError((err) {
      printLongLogMessage("Get error, let's prepare for retry, we have retried $retryTime, capped at ${CWMSHttpClient.timeoutRetryTime}");
      if (err is DioError &&
          // err.type == DioErrorType.connectTimeout &&
          retryTime <= CWMSHttpClient.timeoutRetryTime) {
        // for timeout error and we are still in the retry threshold, let's try again

        if (retryTime <= CWMSHttpClient.timeoutRetryTime) {

          Future.delayed(const Duration(milliseconds: 2000),
                  () => _moveInventoryAsync(inventoryDepositRequest, unitOfMeasure, retryTime: retryTime + 1));
        }
        else {
          inventoryDepositRequest.requestInProcess = false;
          inventoryDepositRequest.requestResult = false;
          inventoryDepositRequest.result = "Fail to move LPN: " + inventoryDepositRequest!.lpn! + " after trying ${CWMSHttpClient.timeoutRetryTime}  times";

          setState(() {
            _inventoryDepositRequests;
          });
        }


      }
      else if (err is WebAPICallException){
        // for any other error display it
        final webAPICallException = err as WebAPICallException;

        inventoryDepositRequest.requestInProcess = false;
        inventoryDepositRequest.requestResult = false;
        inventoryDepositRequest.result = webAPICallException.errMsg() + ", LPN: " + inventoryDepositRequest!.lpn!;

        setState(() {
          _inventoryDepositRequests;
        });
      }
      else {

        inventoryDepositRequest.requestInProcess = false;
        inventoryDepositRequest.requestResult = false;
        inventoryDepositRequest.result =err.toString() + ", LPN: " + inventoryDepositRequest!.lpn!;

        setState(() {
          _inventoryDepositRequests;
        });
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