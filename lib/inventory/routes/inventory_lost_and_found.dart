import 'package:badges/badges.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/models/item_unit_of_measure.dart';
import 'package:cwms_mobile/inventory/models/lpn_capture_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
import 'package:cwms_mobile/inventory/services/item.dart';
import 'package:cwms_mobile/inventory/widgets/item_query.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/models/cwms_http_exception.dart';
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:progress_dialog/progress_dialog.dart';


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


  FocusNode _itemNumberFocusNode = FocusNode();
  FocusNode _quantityFocusNode = FocusNode();
  FocusNode _lpnFocusNode = FocusNode();

  List<InventoryStatus> _validInventoryStatus;
  InventoryStatus _selectedInventoryStatus;
  ItemPackageType _selectedItemPackageType;
  ItemUnitOfMeasure _selectedItemUnitOfMeasure;
  Item _currentItem;
  bool _readyToConfirm = true;

  ProgressDialog _progressDialog;

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

    _lpnFocusNode.addListener(() {
      print("_lpnFocusNode.hasFocus: ${_lpnFocusNode.hasFocus}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty && _readyToConfirm) {
        // if we tab out, then add the LPN to the list
        // set _readyToConfirm to false to disable the 'confirm' button
        // so that we won't create the same LPN twice

        _readyToConfirm = false;
        printLongLogMessage("1. set _readyToConfirm to false ");
        _enterOnLPNController();
      }
    });

    inventoryOnRF = [];

    _reloadInventoryOnRF();
  }
  final  _formKey = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).inventoryAdjust)),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              // show RF as the destination location of the adjust LPN
              buildTwoSectionInformationRow(CWMSLocalizations.of(context).location,
                  Global.lastLoginRFCode),

              // ask the user to input item number
              buildTwoSectionInputRow(CWMSLocalizations.of(context).item,
                Focus(
                    child: ItemQuery(
                        itemNumberController: _itemController,
                        autofocus: true,
                        focusNode: _itemNumberFocusNode,
                        onItemSelected: (selectedItem) {
                          if (selectedItem != null) {

                            setState(() {
                              _currentItem = selectedItem;
                            });
                            _quantityFocusNode.requestFocus();
                          }
                        },
                        validator: (v) {
                          if (v.trim().isEmpty) {
                            return CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).item);
                          }

                          return null;
                        }

                    ),
                    onFocusChange: (hasFocus) {
                      if (!hasFocus && _itemController.text
                          .trim()
                          .isNotEmpty) {
                        ItemService.getItemByName(
                            _itemController.text.trim()).then(
                                (itemRes) {
                              if (itemRes != null) {
                                // we find the item by name, let's save it
                                printLongLogMessage("set current item to ${itemRes.name}");
                                setState(() {
                                  _currentItem = itemRes;
                                });
                              }

                            });
                      }
                    }
                ),
              ),
              // Allow the user to choose item package type
              buildTwoSectionInputRow(
                  CWMSLocalizations.of(context).itemPackageType,

                  _getItemPackageTypeItems().isEmpty ?
                  Container() :
                  DropdownButton(
                    // hint: Text(CWMSLocalizations.of(context).pleaseSelect),
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
              ),
              // Allow the user to choose inventory status
              buildTwoSectionInputRow(
                  CWMSLocalizations.of(context).inventoryStatus,
                  DropdownButton(
                    //  hint: Text(CWMSLocalizations.of(context).pleaseSelect),
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
              ),
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
              ),
              buildTwoSectionInputRow(
                CWMSLocalizations.of(context).lpn+ ": ",
                Focus(
                  child:
                  SystemControllerNumberTextBox(
                      type: "lpn",
                      controller: _lpnController,
                      readOnly: false,
                      showKeyboard: false,
                      focusNode: _lpnFocusNode,
                      autofocus: true,
                      validator: (v) {
                        // if we only need one LPN, then make sure the user input the LPN in this form.
                        // otherwise, we will flow to next LPN Capture form to let the user capture
                        // more LPNs
                        if (v.trim().isEmpty && _getRequiredLPNCount(int.parse(_quantityController.text)) == 1) {
                          return CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).lpn);
                        }

                        return null;
                      }),
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
    return buildTwoButtonRow(context,

        ElevatedButton(
          onPressed: !_readyToConfirm || _currentItem == null ? null :
              () {
            if (_formKey.currentState.validate() && _readyToConfirm) {

              _readyToConfirm = false;
              printLongLogMessage("2. _readyToConfirm = ${_readyToConfirm} ");
              _onInventoryAdjustConfirm(
                  int.parse(_quantityController.text),
                  _lpnController.text
              );
            }

          },
          child: Text(CWMSLocalizations
              .of(context)
              .confirm),
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

  }


  // check how many LPNs we will need to receive
  // based on the quantity that the user input,
  // the UOM that the user select
  int _getRequiredLPNCount(int totalQuantity) {

    int lpnCount = 0;

    if (_selectedItemPackageType.trackingLpnUOM == null) {
      // the tracking LPN UOM is not defined for this item package type, so we don't know
      // how to calculate how many LPNs we may need based on the UOM and quantity
      lpnCount = 1;
    }
    else if (_selectedItemUnitOfMeasure.quantity == _selectedItemPackageType.trackingLpnUOM.quantity) {
      // we are receiving at LPN uom level, then see what's the quantity the user specify
      lpnCount = totalQuantity;
    }
    else if (_selectedItemUnitOfMeasure.quantity > _selectedItemPackageType.trackingLpnUOM.quantity) {
      // we are receiving at some higher level, see how many LPN uom we will need
      lpnCount = (totalQuantity * _selectedItemUnitOfMeasure.quantity / _selectedItemPackageType.trackingLpnUOM.quantity) as int;
    }
    else {
      // we are receiving at some lower level than the tracking LPN UOM,
      // no matter how many we are receiving, we will only need one lpn, we will rely on
      // the user to input the right quantity that can be done in one single lpn
      lpnCount = 1;
    }
    return lpnCount;

  }

  List<DropdownMenuItem> _getItemUnitOfMeasures() {
    List<DropdownMenuItem> items = [];

    if ( _selectedItemPackageType == null || _selectedItemPackageType.itemUnitOfMeasures == null ||
        _selectedItemPackageType.itemUnitOfMeasures.length == 0) {
      // if the user has not selected any item package type yet
      // return nothing
      return items;
    }

    for (int i = 0; i < _selectedItemPackageType.itemUnitOfMeasures.length; i++) {

      items.add(DropdownMenuItem(
        value:  _selectedItemPackageType.itemUnitOfMeasures[i],
        child: Text( _selectedItemPackageType.itemUnitOfMeasures[i].unitOfMeasure.name),
      ));
    }

    // we may have _selectedItemUnitOfMeasure setup by previous item package type.
    // or manually by user. If it is setup by the user, then we won't refresh it
    // otherwise, we will reload the default receiving uom
    // if _selectedItemPackageType.itemUnitOfMeasures doesn't containers the _selectedItemUnitOfMeasure
    // then we know that we just changed the item package type or item, so we will need
    // to refresh the _selectedItemUnitOfMeasure to the default inbound receiving uom as well
    if (_selectedItemUnitOfMeasure == null ||
        !_selectedItemPackageType.itemUnitOfMeasures.any((element) => element.hashCode == _selectedItemUnitOfMeasure.hashCode)) {
      // if the user has not select any item unit of measure yet, then
      // default the value to the one marked as 'default for inbound receiving'

      _selectedItemUnitOfMeasure = _selectedItemPackageType.itemUnitOfMeasures
          .firstWhere((element) => element.id == _selectedItemPackageType.defaultInboundReceivingUOM.id);
    }

    return items;
  }

  // call the deposit form to deposit the inventory on the RF
  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the inventory on the RF
    _reloadInventoryOnRF();
  }


  List<DropdownMenuItem> _getInventoryStatusItems() {
    List<DropdownMenuItem> items = [];
    if (_validInventoryStatus == null || _validInventoryStatus.length == 0) {
      return items;
    }

    // _selectedInventoryStatus = _validInventoryStatus[0];
    for (int i = 0; i < _validInventoryStatus.length; i++) {
      items.add(DropdownMenuItem(
        value: _validInventoryStatus[i],
        child: Text(_validInventoryStatus[i].description),
      ));
    }

    if (_validInventoryStatus.length == 1 ||
        _selectedInventoryStatus == null) {
      // if we only have one valid inventory status, then
      // default the selection to it
      // if the user has not select any inventdry status yet, then
      // default the value to the first option as well
      _selectedInventoryStatus = _validInventoryStatus[0];
    }
    return items;
  }

  List<DropdownMenuItem> _getItemPackageTypeItems() {
    List<DropdownMenuItem> items = [];


    if (_currentItem != null && _currentItem.itemPackageTypes.length > 0) {
      // _selectedItemPackageType = item.itemPackageTypes[0];

      for (int i = 0; i < _currentItem.itemPackageTypes.length; i++) {

        items.add(DropdownMenuItem(
          value: _currentItem.itemPackageTypes[i],
          child: Text(_currentItem.itemPackageTypes[i].description),
        ));
      }

      if (_currentItem.itemPackageTypes.length == 1 ||
          _selectedItemPackageType == null) {
        // if we only have one item package type for this item, then
        // default the selection to it
        // if the user has not select any item package type yet, then
        // default the value to the first option as well
        _selectedItemPackageType = _currentItem.itemPackageTypes[0];
      }
    }
    return items;
  }




  void _onInventoryAdjustConfirm(int confirmedQuantity,
      String lpn) async {

    if (lpn.isNotEmpty) {
      showLoading(context);
      // first of all, validate the LPN
      try {
        bool validLpn = await InventoryService.validateNewLpn(lpn);
        if (!validLpn) {
          Navigator.of(context).pop();
          showErrorDialog(context, "LPN is not valid, please make sure it follow the right format");
          _readyToConfirm = true;
          printLongLogMessage("3. set _readyToConfirm to ${_readyToConfirm} ");
          return;
        }
        printLongLogMessage("LPN ${lpn} passed the validation");
      }
      on CWMSHttpException catch(ex) {

        Navigator.of(context).pop();
        showErrorDialog(context, "${ex.code} - ${ex.message}");
        printLongLogMessage("4. set _readyToConfirm to ${_readyToConfirm} ");
        _readyToConfirm = true;
        return;

      }
      Navigator.of(context).pop();
    }


    int lpnCount = _getRequiredLPNCount(confirmedQuantity);

    // see if we are receiving single lpn or multiple lpn
    if (lpnCount == 1) {
      // if we haven't specify the UOM that we will need to track the LPN
      // or we are receiving at less than LPN uom level,
      // or we are receiving at LPN uom level but we only receive 1 LPN, then proceed with single LPN
      _onAdjustSingleLpnConfirm(confirmedQuantity, lpn);
    }
    else {
      _onAdjustMultiLpnConfirm(confirmedQuantity, lpn);
    }

  }
  void _onAdjustSingleLpnConfirm(int confirmedQuantity,
      String lpn) async {

    showLoading(context);
    // make sure this is a valid LPN



    // refresh the work order to reflect the produced quantity

    Inventory inventory = await createInventory(lpn, confirmedQuantity * _selectedItemUnitOfMeasure.quantity);
    try {
      await InventoryService.addInventory(inventory);
    }
    on CWMSHttpException catch(ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, "${ex.code} - ${ex.message}");
      return;

    }
    Navigator.of(context).pop();

    _refreshScreenAfterAdjust();

  }
  Future<Inventory> createInventory(String lpn, int quantity) async {
    Inventory inventory = new Inventory();
    inventory.item = _currentItem;
    // in 3pl environment, let's set the inventory's client id based on the item
    // client id
    if (_currentItem.clientId != null) {
      printLongLogMessage("current item belongs to client ${_currentItem.clientId}" +
      ", we will setup the inventory with the same client id");
      inventory.clientId = _currentItem.clientId;
    }
    inventory.quantity = quantity;
    WarehouseLocation rfLocation = await WarehouseLocationService.getWarehouseLocationByName(
        Global.lastLoginRFCode
    );
    inventory.location = rfLocation;
    inventory.locationId = rfLocation.id;
    inventory.lpn = lpn;
    inventory.warehouseId = Global.currentWarehouse.id;
    inventory.inventoryStatus = _selectedInventoryStatus;
    inventory.itemPackageType = _selectedItemPackageType;
    inventory.virtual = false;
    return inventory;
  }


  void _onAdjustMultiLpnConfirm(int confirmedQuantity,
      String lpn) async {

    // let's see how many LPNs we will need
    int lpnCount = _getRequiredLPNCount(confirmedQuantity);

    printLongLogMessage("we will need to receive $lpnCount LPNs");
    if (lpnCount == 1) {
      // we will only need one LPN, let's just proceed with the current LPN
      _onAdjustSingleLpnConfirm(confirmedQuantity, lpn);

    }
    else if (lpnCount > 1) {
      // we will need multiple LPNs, let's prompt a dialog to capture the lpns

      Set<String> capturedLpn = new Set();
      // if the user already scna in a lpn, then add it
      if (lpn.isNotEmpty) {
        capturedLpn.add(lpn);
        printLongLogMessage("add current LPN $lpn first so that the user don't have to scan in again");
      }
      LpnCaptureRequest lpnCaptureRequest = new LpnCaptureRequest.withData(
          _currentItem,
          _selectedItemPackageType,
          _selectedItemPackageType.trackingLpnUOM,
          lpnCount, capturedLpn,
          true
      );

      final result = await Navigator.of(context)
          .pushNamed("lpn_capture", arguments: lpnCaptureRequest);

      // printLongLogMessage("returned from the capture lpn form. result == null? : ${result == null}");
      if (result == null) {
        // the user press Return, let's do nothing

        return null;
      }

      lpnCaptureRequest = result as LpnCaptureRequest;

      if (lpnCaptureRequest.result == false) {
        // this happens when the user click 'cancel' button
        return null;
      }
      // receive with multiple LPNs
      _adjustMultipleLpns(lpnCaptureRequest);
    }

  }

  void _adjustMultipleLpns(LpnCaptureRequest lpnCaptureRequest) async {

    showLoading(context);
    // make sure the user input a valid LPN
    try {
      Iterator<String> lpnIterator = lpnCaptureRequest.capturedLpn.iterator;
      while(lpnIterator.moveNext()) {

        bool validLpn = await InventoryService.validateNewLpn(lpnIterator.current);
        if (!validLpn) {
          Navigator.of(context).pop();
          showErrorDialog(context, "LPN is not valid, please make sure it follow the right format");
          return;
        }
        printLongLogMessage("LPN ${lpnIterator.current} passed the validation");
      }
    }
    on CWMSHttpException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, "${ex.code} - ${ex.message}");
      return;

    }
    try {
      // start receive LPNs one by one and show the progress bar
      _setupProgressBar();
      Iterator<String> lpnIterator = lpnCaptureRequest.capturedLpn.iterator;
      int totalLPNCount = lpnCaptureRequest.capturedLpn.length;
      int currentLPNIndex = 1;

      while(lpnIterator.moveNext()) {
        String lpn = lpnIterator.current;
        double progress = currentLPNIndex * 100 / totalLPNCount;
        String message = CWMSLocalizations.of(context).receivingCurrentLpn + ": " +
            lpn + ", " + currentLPNIndex.toString() + " / " + totalLPNCount.toString();

        _progressDialog.update(progress: progress, message: message);

        Inventory inventory = await createInventory(lpn, lpnCaptureRequest.lpnUnitOfMeasure.quantity);

        await InventoryService.addInventory(inventory);

        currentLPNIndex++;
      }

    }
    on CWMSHttpException catch(ex) {
      Navigator.of(context).pop();
      showErrorDialog(context, "${ex.code} - ${ex.message}");
      return;

    }

    if (_progressDialog.isShowing()) {
      _progressDialog.hide();
    }

    Navigator.of(context).pop();

    _refreshScreenAfterAdjust();

  }

  _setupProgressBar() {

    _progressDialog = new ProgressDialog(
      context,
      type: ProgressDialogType.Normal,
      isDismissible: false,
      showLogs: true,
    );

    _progressDialog.style(message: CWMSLocalizations.of(context).receivingMultipleLpns);
    if (!_progressDialog.isShowing()) {
      _progressDialog.show();
    }
  }
  _refreshScreenAfterAdjust() {
    print("inventory adjust!");

    showToast("inventory adjust complete");
    // we will allow the user to continue receiving with the same
    // receipt and line
    _lpnController.clear();
    _quantityController.clear();
    _itemController.clear();
    setState(() {
      _currentItem = null;
      _readyToConfirm = true;
      printLongLogMessage("5. set _readyToConfirm to ${_readyToConfirm} ");
    });

    _itemNumberFocusNode.requestFocus();


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

  void _enterOnLPNController({int tryTime = 10}) async {
    // we may come here when the user scan / press
    // enter in the LPN controller. In either case, we will need to make sure
    // the lpn doesn't have focus before we start confirm

    if (tryTime <= 0) {
      // do nothing as we run out of try time

      setState(() {
        // enable the confirm button
        printLongLogMessage("6. set _readyToConfirm to ${_readyToConfirm} ");
        _readyToConfirm = true;
      });
      return;
    }
    if (_lpnFocusNode.hasFocus) {
      printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnLPNController(tryTime: tryTime - 1));

      return;

    }
    // if we are here, then it means we already have the full LPN
    // due to how  flutter handle the input, we will get the enter
    // action listner handler fired before the input characters are
    // full assigned to the lpnController.

    printLongLogMessage("lpn controller lost focus, its value is ${_lpnController.text}");
    if (_formKey.currentState.validate()) {
      print("form validation passed");
      _onInventoryAdjustConfirm(
          int.parse(_quantityController.text),
          _lpnController.text);
    }


  }



}