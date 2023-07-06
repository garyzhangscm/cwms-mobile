import 'dart:async';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/widgets/inventory_deposit_request_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../shared/http_client.dart';


class InventoryDepositPage extends StatefulWidget{

  InventoryDepositPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _InventoryDepositPageState();

}

class _InventoryDepositPageState extends State<InventoryDepositPage> {

  // show LPN and Item
  // allow the user to choose LPN or Item if there're
  // multiple LPN to deposit, or multiple Item on the same LPN to deposit
  TextEditingController _locationController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();
  List<Inventory> inventoryOnRF;
  InventoryDepositRequest inventoryDepositRequest;

  final  _formKey = GlobalKey<FormState>();
  FocusNode _locationFocusNode = FocusNode();
  FocusNode _lpnFocusNode = FocusNode();
  FocusNode _lpnControllerFocusNode = FocusNode();



  @override
  void initState() {
    super.initState();
    print("Start to get inventory on RF");
    inventoryDepositRequest = new InventoryDepositRequest();
    inventoryOnRF = [];

    _locationFocusNode.addListener(() {
      if (!_locationFocusNode.hasFocus && _locationController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _onDepositConfirmAsync(inventoryDepositRequest);

      }
    });

    _lpnFocusNode.addListener(() {
      print("_lpnFocusNode.hasFocus: ${_lpnFocusNode.hasFocus}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list

        setState(() {

          inventoryDepositRequest = _getNextInventoryToDeposit(_lpnController.text);
          if (inventoryDepositRequest == null) {
            showErrorDialog(context, "can't find inventory with lpn ${_lpnController.text} to deposit");

          }
          else {
            // move focus to the location
            _locationFocusNode.requestFocus();
          }
        });

      }
    });

    _locationController.clear();
    _locationFocusNode.requestFocus();

    Future.delayed(Duration.zero, () {
      _refreshInventoryOnRF();
    });
  }
  // remove the inventory from inventory On RF once we complete a inventory deposit
  // request. We will remove the inventory from the local
  Future<void>  _removeInventoryOnRf(InventoryDepositRequest inventoryDepositRequest) async{

    inventoryOnRF = inventoryOnRF.where((inventory) =>
        !inventoryDepositRequest.inventoryIdList.contains(inventory.id)
    ).toList();
    await _displayInventoryForDeposit();
  }
  Future<void> _displayInventoryForDeposit() async {

    if (inventoryOnRF.isEmpty) {
      // no inventory on the RF yet
      // return to the previous page
      printLongLogMessage("start to show dialog");
      await showDialog(
          context: context,
          builder: (context) {
            return
              AlertDialog(
                title: Text(""),
                content: Text("No more inventory on the RF"),
                actions: <Widget>[

                  ElevatedButton(
                    child: Text("Confirm"),
                    onPressed: () {
                      Navigator.of(context).pop(true); //关闭对话框
                    },
                  ),
                ],
              );
          }
      );
      // return to the previous page after display the message
      Navigator.of(context).pop();
    }
    else {
      setState(() {

        inventoryDepositRequest = _getNextInventoryToDeposit();
        _lpnController.text = inventoryDepositRequest.lpn;
        // see if we will need to
      // _locationController.text = "";
      });
    }
  }
  void _refreshInventoryOnRF() {
    showLoading(context);

    InventoryService.getInventoryOnCurrentRF().then((value)  async {
      inventoryOnRF = value;
      Navigator.of(context).pop();

      await _displayInventoryForDeposit();
    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text("CWMS - Deposit")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          // autovalidateMode: AutovalidateMode.always, //开启自动校验
          child: Column(
            children: <Widget>[
              _buildLPNScanner(context),
              buildTwoSectionInformationRow(
                  "Item:",
                inventoryDepositRequest == null ? "" : inventoryDepositRequest.itemName,
              ),
              buildTwoSectionInformationRow(
                "Item:",
                inventoryDepositRequest == null ? "" : inventoryDepositRequest.itemDescription,
              ),
              buildTwoSectionInformationRow(
                "Inventory Status:",
                inventoryDepositRequest == null ? "" : inventoryDepositRequest.inventoryStatusDescription,
              ),
              buildTwoSectionInformationRow(
                "Quantity:",
                  inventoryDepositRequest == null ? "" :  inventoryDepositRequest.quantity.toString()
              ),
              _buildDestinationLocationRow(context),
              _buildLocationScanner(context),
              Padding(
                padding: const EdgeInsets.only(top: 25),
                child: ConstrainedBox(
                  constraints: BoxConstraints.expand(height: 55.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    onPressed: inventoryDepositRequest == null || inventoryDepositRequest.lpn == null || inventoryDepositRequest.lpn.isEmpty ?
                       null :
                       () {
                         if (_formKey.currentState.validate()) {
                           print("form validation passed");
                           _onDepositConfirmAsync(inventoryDepositRequest);
                         }

                      },
                    child: Text("Confirm"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildDestinationLocationRow(BuildContext context) {

    if (inventoryDepositRequest == null) {
      // there's no more to deposit
      return
        buildTwoSectionInformationRow(
          "Location:", ""
        );
    }
    else if (inventoryDepositRequest.nextLocation == null) {
      // the inventory has no destination location assigned yet, let the user
      // to allocate one or manually choose one destination
      return Padding(
        padding: EdgeInsets.only(top: 5, bottom: 5),
        child:
        Row(
            children: <Widget>[
              Padding(padding: EdgeInsets.only(right: 10),
                child: Text("Location:", textAlign: TextAlign.left),
              ),
              IconButton(
                onPressed: () => _allocateLocation(),
                icon: Icon(Icons.approval_rounded),
              ),
            ]
        ),
      );
    }
    else {

      // there's already destination location assigned, show the location
      return buildTwoSectionInformationRow(
        "Location:", inventoryDepositRequest.nextLocation.name,
      );
    }
  }

  // scan in barcode to add a order into current batch
  Widget _buildLPNScanner(BuildContext context) {
    return
      Focus(
          child:
          RawKeyboardListener(
              focusNode: _lpnFocusNode,
              child:
              TextFormField(
                  controller: _lpnController,
                  showCursor: true,
                  autofocus: true,
                  focusNode: _lpnControllerFocusNode,

                  decoration: InputDecoration(
                    suffixIcon:
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                      mainAxisSize: MainAxisSize.min, // added line
                      children: <Widget>[
                        IconButton(
                          onPressed: () => _clearField(),
                          icon: Icon(Icons.close),
                        ),
                        IconButton(
                          onPressed: _singleLPNDeposit() ? null : _showLPNDialog,
                          icon: Icon(Icons.list),
                        ),
                        IconButton(
                            icon: new Icon(Icons.print),
                            onPressed: () => _printLPNLabel()
                        ),
                      ],
                    ),
                  )

              )
          )
      );


    return
      Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
             children: <Widget>[
                 TextFormField(
                    controller: _lpnController,
                    // readOnly: true,
                    decoration: InputDecoration(
                      labelText: CWMSLocalizations
                          .of(context)
                          .lpn,
                      hintText: CWMSLocalizations
                          .of(context)
                          .inputLPNHint,
                      suffixIcon:
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                          mainAxisSize: MainAxisSize.min, // added line
                          children: <Widget>[
                            IconButton(
                              onPressed: () => _clearField(),
                              icon: Icon(Icons.close),
                            ),
                            IconButton(
                              onPressed: _singleLPNDeposit() ? null : _showLPNDialog,
                              icon: Icon(Icons.list),
                            ),
                          ],
                        ),
                    ),
                 ),

             ]
          )
      );
  }

  void _printLPNLabel() {
    if (_lpnController.text.isNotEmpty) {

      InventoryService.printLPNLabel(_lpnController.text);
    }
  }

  _clearField() {
    _lpnController.text = "";
    setState(() {
      inventoryDepositRequest = new InventoryDepositRequest();
    });
    _lpnControllerFocusNode.requestFocus();

  }

  _allocateLocation() {
    // allocatet a location for the inventory. If the LPN
    // already has a location , reallocate the inventory
    showLoading(context);
    InventoryService.findInventory(lpn: inventoryDepositRequest.lpn)
        .then((inventoryList) {
          inventoryList.forEach((inventory) async {
            printLongLogMessage("will allocate location for lpn ${inventory.lpn}");
            printLongLogMessage("item family: ${inventory.item.toJson()}");
            await InventoryService.allocateLocation(inventory);
          });

          // refresh to show the destination location
          _refreshInventoryOnRF();
          _getNextInventoryToDeposit(inventoryDepositRequest.lpn);
          Navigator.of(context).pop();

    });

  }
  // scan in location barcode to confirm
  Widget _buildLocationScanner(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _locationController,
                  autofocus: true,
                  focusNode: _locationFocusNode,
                  decoration: InputDecoration(
                    labelText: CWMSLocalizations
                        .of(context)
                        .location,
                    hintText: CWMSLocalizations
                        .of(context)
                        .inputLocationHint,
                    suffixIcon:
                      IconButton(
                        onPressed: _startLocationBarcodeScanner,
                        icon: Icon(Icons.scanner),
                      ),

                  ),
                ),

              ]
          )
      );
  }

  InventoryDepositRequest _getNextInventoryToDeposit([String lpn]) {

    printLongLogMessage("_getNextInventoryToDeposit with lpn ${lpn}");
    InventoryDepositRequest inventoryDepositRequest;
    if (lpn != null && lpn.isNotEmpty) {
      inventoryDepositRequest = InventoryService.getNextInventoryDepositRequest(
          inventoryOnRF.where((inventory) => inventory.lpn == lpn).toList(), true, true);
    }
    inventoryDepositRequest = InventoryService.getNextInventoryDepositRequest(inventoryOnRF, true, true);
    // see if we will need to split the inventory
    if (inventoryDepositRequest == null) {
      return null;
    }
    List<Inventory> inventorySameLPNDifferentDestinationLocation =
        inventoryOnRF.where((inventory) {
          if (inventory.lpn != inventoryDepositRequest.lpn) {
            // inventory has a different LPN return false;
            return false;
          }
          // make sure the inventory goes to the same destination
          if (inventoryDepositRequest.nextLocationId == null &&
              inventory.getNextDepositLocaiton() != null) {
            return true;
          }
          else if (inventoryDepositRequest.nextLocationId != null &&
              inventory.getNextDepositLocaiton() == null) {
            return true;
          }
          else if (inventoryDepositRequest.nextLocationId != null &&
              inventory.getNextDepositLocaiton() != null &&
              inventoryDepositRequest.nextLocationId !=
                  inventory.getNextDepositLocaiton().id) {
            return true;
          }
          // inventory has the same LPN and same destination
          return false;
        });
    if (inventorySameLPNDifferentDestinationLocation.isEmpty) {
      // all inventory in the LPN has the same destination
      printLongLogMessage("all ${inventoryDepositRequest.inventoryIdList.length} inventory in LPN ${inventoryDepositRequest.lpn} has the same destination");
      return inventoryDepositRequest;
    }
    printLongLogMessage("we found ${inventorySameLPNDifferentDestinationLocation.length} inventory out of " +
        " ${inventoryDepositRequest.inventoryIdList.length} inventory in LPN ${inventoryDepositRequest.lpn} has different destination");
    // we will ask the user to relabel the inventory that already in the inventory deposit request and then
    // deposit the relabeled one.
    return inventoryDepositRequest;




  }

  void _startLPNBarcodeScanner() async  {
    String lpnScanned = await _startBarcodeScanner();
    if (lpnScanned != "-1") {

      _lpnController.text = lpnScanned;

      _locationController.text = "";
    }


  }
  void _startLocationBarcodeScanner() async  {
    String locationScanned = await _startBarcodeScanner();
    if (locationScanned != "-1") {

      _locationController.text = locationScanned;
    }

  }
  Future<String> _startBarcodeScanner() async {
    /**
     *
        String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
        print("barcode scanned: $barcodeScanRes");
        return barcodeScanRes;
     * */

  }

  // return true if we only have one LPN to be deposit
  // then we will not allow the user to choose or scan in
  // another LPN
  bool _singleLPNDeposit() {
    if (inventoryOnRF.length <= 1) {
      return true;
    }
    String firstLPN = inventoryOnRF[0].lpn;
    return inventoryOnRF.indexWhere((inventory) => inventory.lpn != firstLPN) < 0;

  }


  // prompt a dialog for user to choose valid orders
  Future<void> _showLPNDialog() async {

    print("start to show LPN choose dialog");
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        var child = Column(
          children: <Widget>[
            ListTile(title: Text(CWMSLocalizations
                .of(context)
                .chooseLPN)),
            _buildDepositRequestList(context)
          ],
        );
        //使用AlertDialog会报错
        //return AlertDialog(content: child);
        return Dialog(child: child);
      },
    );
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
                  onToggleHightlighted:  (selected) {
                    // reset the selected inventory
                    _onSelecteInventoryDepositRequest(selected, inventoryDepositRequests[index]);
                    // hide the dialog
                    Navigator.of(context).pop();
                  }
              );
            }),
      );
  }

  void _onSelecteInventoryDepositRequest(bool selected, InventoryDepositRequest selectedInventoryDepositRequest) {

    setState(() {
      if (selected) {
        inventoryDepositRequest = selectedInventoryDepositRequest;
        print("inventory to be deposit: $inventoryDepositRequest");
        _lpnController.text = inventoryDepositRequest.lpn;
        _locationController.text = "";
        _locationFocusNode.requestFocus();
      }
      else {
        inventoryDepositRequest = _getNextInventoryToDeposit();
        _lpnController.text = inventoryDepositRequest.lpn;
        _locationController.text = "";
        _locationFocusNode.requestFocus();
      }
    });

  }

/**
  void _onDepositConfirm(InventoryDepositRequest inventoryDepositRequest) async {


    printLongLogMessage("start to deposit invenotry ${inventoryDepositRequest.lpn}");

    showLoading(context);
    // Let's get the location first

    WarehouseLocation destinationLocation;
    try {
      destinationLocation =
          await WarehouseLocationService.getWarehouseLocationByName(
              _locationController.text
          );


      // make sure the location is a valid location for deposit
      // it should be either the same location as indicated,
      // or a pickup and deposit location
      printLongLogMessage("inventoryDepositRequest.nextLocation: ${inventoryDepositRequest.nextLocation == null ? "" : inventoryDepositRequest.nextLocation.id} " +
          "/ ${inventoryDepositRequest.nextLocation == null ? "" : inventoryDepositRequest.nextLocation.name}");
      printLongLogMessage("destinationLocation: ${destinationLocation.id} / ${destinationLocation.name}, P&D? ${destinationLocation.locationGroup.locationGroupType.pickupAndDeposit}");
      if (inventoryDepositRequest.nextLocation != null &&
          destinationLocation.id != inventoryDepositRequest.nextLocation.id &&
          destinationLocation.locationGroup.locationGroupType.pickupAndDeposit == false) {

          throw new WebAPICallException("should only deposit to  ${inventoryDepositRequest.nextLocation.name} or a Pickup and Deposit location");
      }

    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      _locationController.selection = TextSelection(baseOffset: 0,
          extentOffset: _locationController.text.length);
      return;

    }



    printLongLogMessage("location ${destinationLocation.name} verified!");

    for (int i = 0; i < inventoryDepositRequest.inventoryIdList.length; i++) {
      int inventoryId = inventoryDepositRequest.inventoryIdList[i];

      try {

        await InventoryService.moveInventory(
            inventoryId: inventoryId,
            destinationLocation: destinationLocation
        );
      }
      on WebAPICallException catch(ex) {

        Navigator.of(context).pop();
        showErrorDialog(context, ex.errMsg());
        _locationController.selection = TextSelection(baseOffset: 0,
          extentOffset: _locationController.text.length);
        return;
      }
    }

    printLongLogMessage("all inventory is deposit");
    Navigator.of(context).pop();

    showToast("inventory deposit");
    _locationController.clear();
    _locationFocusNode.requestFocus();

    // let's get next inventory to be deposit
    _refreshInventoryOnRF();


  }
**/

  Future<void> _onDepositConfirmAsync(InventoryDepositRequest inventoryDepositRequest,
    {int retryTime = 0}) async {


    printLongLogMessage("start to deposit invenotry ${inventoryDepositRequest.lpn}");

    WarehouseLocationService.getWarehouseLocationByName(
        _locationController.text
    ).then((destinationLocation) async {
      if (inventoryDepositRequest.nextLocation != null &&
          destinationLocation.id != inventoryDepositRequest.nextLocation.id &&
          destinationLocation.locationGroup.locationGroupType.pickupAndDeposit == false) {

        throw new WebAPICallException("should only deposit to  ${inventoryDepositRequest.nextLocation.name} or a Pickup and Deposit location");

      }

      for (int i = 0; i < inventoryDepositRequest.inventoryIdList.length; i++) {
        int inventoryId = inventoryDepositRequest.inventoryIdList[i];
          await InventoryService.moveInventory(
              inventoryId: inventoryId,
              destinationLocation: destinationLocation
          );
      }

      showToast("inventory deposit");

      // let's get next inventory to be deposit

    }).catchError((err) {
      printLongLogMessage("Get error, let's prepare for retry, we have retried $retryTime, capped at ${CWMSHttpClient.timeoutRetryTime}");
      if (err is DioError) {
          // err.type == DioErrorType.connectTimeout &&) {
        // for timeout error and we are still in the retry threshold, let's try again

        if (retryTime <= CWMSHttpClient.timeoutRetryTime) {

          Future.delayed(const Duration(milliseconds: 2000),
                  () => _onDepositConfirmAsync(inventoryDepositRequest, retryTime: retryTime + 1));
        }
        else {
          // do nothing as we already running out of retry time
          showErrorDialog(context, "Fail to deposit LPN: " + inventoryDepositRequest.lpn + " after trying ${CWMSHttpClient.timeoutRetryTime} times");
        }

      }
      else if (err is WebAPICallException){
        // for any other error display it
        final webAPICallException = err as WebAPICallException;
        showErrorDialog(context, webAPICallException.errMsg() + ", LPN: " + inventoryDepositRequest.lpn);
      }
      else {

        showErrorDialog(context, err.toString() + ", LPN: " + inventoryDepositRequest.lpn);
      }
      // ignore any other error

    });
    _locationController.clear();
    _locationFocusNode.requestFocus();

    await _removeInventoryOnRf(inventoryDepositRequest);

  }
}