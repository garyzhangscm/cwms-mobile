import 'dart:async';
import 'dart:math';

import 'package:badges/badges.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../exception/WebAPICallException.dart';
import '../../shared/http_client.dart';

// Page to allow the user scan in an LPN and start the put away process
// The LPN can be in receiving stage / storage location / etc
// with or without any pre-assigned destination
class InventoryPutawayPage extends StatefulWidget{

  InventoryPutawayPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _InventoryPutawayPageState();

}

class _InventoryPutawayPageState extends State<InventoryPutawayPage> {

  // allow user to scan in LPN
  TextEditingController _lpnController = new TextEditingController();
  GlobalKey _formKey = new GlobalKey<FormState>();


  List<Inventory>  inventoryOnRF;

  FocusNode lpnFocusNode = FocusNode();

  List<InventoryDepositRequest> _inventoryDepositRequests = [];


  Timer _timer;  // timer to refresh inventory on RF every 2 second

  @override
  void initState() {
    super.initState();

    inventoryOnRF = [];



    lpnFocusNode.addListener(() {
      print("lpnFocusNode.hasFocus: ${lpnFocusNode.hasFocus}");
      if (!lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _onAddingLPN();

      }
    });

    _reloadInventoryOnRF();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("CWMS - Inventory Putaway")),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[

              _buildLPNScanner(context),
              _buildButtons(context),
              _buildDepositRequestList(context)
            ],
          ),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildLPNScanner(BuildContext context) {
    return TextFormField(
        controller: _lpnController,
        focusNode: lpnFocusNode,
        autofocus: true,
        decoration: InputDecoration(
          labelText: CWMSLocalizations.of(context).lpn,
          hintText: "please input LPN",
          suffixIcon:
            IconButton(
              onPressed: () => _clearLPN(),
              icon: Icon(Icons.close),
            ),
        ),
        // 校验用户名（不能为空）
        validator: (v) {
          return v.trim().isNotEmpty ?
              null :
              CWMSLocalizations.of(context).missingField(
                  CWMSLocalizations.of(context).lpn);
        });
  }


  void _clearLPN() {

    _lpnController.text = "";
    lpnFocusNode.requestFocus();
    setState(() {

      _inventoryDepositRequests = [];
    });
  }

  Widget _buildButtons(BuildContext context) {

    return buildThreeButtonRow(context,
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Theme.of(context).primaryColor,
          ),
          onPressed: _onAddingLPN,
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
              onPressed: inventoryOnRF.length == 0 ? null : _startBatchDeposit,
              child: Text(CWMSLocalizations.of(context).batchDepositInventory),
            ),
          ),
        )
    );

  }

  void _startLPNBarcodeScanner() async  {
    String lpnScanned = await _startBarcodeScanner();
    if (lpnScanned != "-1") {

      _lpnController.text = lpnScanned;


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

  void _onAddingLPN() async {

    if (_lpnController.text.isEmpty) {

      showErrorDialog(context, "please input the LPN number");
      return;
    }


    // skip the LPN if it is already added
    if (!_inventoryDepositRequests.any((inventoryDepositRequest) => inventoryDepositRequest.lpn == _lpnController.text)) {

      InventoryDepositRequest inventoryDepositRequest =
          new InventoryDepositRequest();
      inventoryDepositRequest.lpn = _lpnController.text;
      inventoryDepositRequest.requestInProcess = true;
      inventoryDepositRequest.requestResult = false;
      inventoryDepositRequest.result = "";

      _inventoryDepositRequests.insert(0, inventoryDepositRequest);
      setState(() {
        _inventoryDepositRequests;
      });

      _moveInventoryAsync(inventoryDepositRequest, retryTime: 0);

    }
    showToast("LPN putaway request sent");
    _lpnController.clear();
    lpnFocusNode.requestFocus();
  }
  /// move inventory async
  void _moveInventoryAsync(InventoryDepositRequest inventoryDepositRequest, {int retryTime = 0}) {
    // showLoading(context);
    // move the inventory being scanned onto RF
    printLongLogMessage("==>> Start to adding LPN for deposit");
    InventoryService.findInventory(lpn : inventoryDepositRequest.lpn, includeDetails: false)
        .then((inventories) async {

            if(inventories.isNotEmpty) {

              WarehouseLocation rfLocation =
                  await WarehouseLocationService.getWarehouseLocationByName(
                  Global.lastLoginRFCode
              );
              printLongLogMessage("==>> GOT RF location ");

              int totalInventoryQuantity = 0;
              for(Inventory inventory in inventories) {
                printLongLogMessage("==>> start to move invenotry with id ${inventory.id} lpn ${inventory.lpn}");

                await InventoryService.moveInventory(
                      inventoryId: inventory.id,
                      destinationLocation: rfLocation
                  );
                totalInventoryQuantity += inventory.quantity;

                printLongLogMessage("==>> finish moving invenotry with id ${inventory.id} lpn ${inventory.lpn}");
              }

              // Navigator.of(context).pop();

              // showToast(CWMSLocalizations.of(context).actionComplete);
              printLongLogMessage("==>> start to reload inventory after adding the lpn ${_lpnController.text}");
              _reloadInventoryOnRF();
              printLongLogMessage("==>> inventory loaded");
              inventoryDepositRequest.quantity = totalInventoryQuantity;

              inventoryDepositRequest.requestInProcess = false;
              inventoryDepositRequest.requestResult = true;
              inventoryDepositRequest.result = "";

              setState(() {
                _inventoryDepositRequests;
              });

            }
            else {
                // show error message
                inventoryDepositRequest.requestInProcess = false;
                inventoryDepositRequest.requestResult = false;
                inventoryDepositRequest.result = CWMSLocalizations.of(context).noInventoryFound;

                setState(() {
                  _inventoryDepositRequests;
                });
                return;
            }
        })
        .catchError((err) {
            printLongLogMessage("Get error, let's prepare for retry, we have retried $retryTime, capped at ${CWMSHttpClient.timeoutRetryTime}");
            if (err is DioError ) {
              // for timeout error and we are still in the retry threshold, let's try again
              printLongLogMessage("time out while get inventory by LPN ${inventoryDepositRequest.lpn}, let's try again.");
              // retry after 2 second

              if (retryTime <= CWMSHttpClient.timeoutRetryTime) {

                Future.delayed(const Duration(milliseconds: 2000),
                        () => _moveInventoryAsync(inventoryDepositRequest, retryTime: retryTime + 1));
              }
              else {
                // do nothing as we already running out of retry time
                inventoryDepositRequest.requestInProcess = false;
                inventoryDepositRequest.requestResult = false;
                inventoryDepositRequest.result = "Fail to move LPN: ${inventoryDepositRequest.lpn} after trying ${CWMSHttpClient.timeoutRetryTime}  times";

                setState(() {
                  _inventoryDepositRequests;
                });
              }


            }
            else if (err is WebAPICallException){
              // for any other error display it
              final webAPICallException = err as WebAPICallException;

              // do nothing as we already running out of retry time
              inventoryDepositRequest.requestInProcess = false;
              inventoryDepositRequest.requestResult = false;
              inventoryDepositRequest.result = webAPICallException.errMsg() + ", LPN: " + inventoryDepositRequest.lpn;

              setState(() {
                _inventoryDepositRequests;
              });
            }
            else {

              inventoryDepositRequest.requestInProcess = false;
              inventoryDepositRequest.requestResult = false;
              inventoryDepositRequest.result =err.toString() + ", LPN: " + inventoryDepositRequest.lpn;

              setState(() {
                _inventoryDepositRequests;
              });
            }
            // ignore any other error

    });

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

  // call the batch deposit form to batch deposit the inventory on the RF
  Future<void> _startBatchDeposit() async {
    _timer?.cancel();
    await Navigator.of(context).pushNamed("inventory_batch_deposit");

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
                title: Text(CWMSLocalizations.of(context).lpn + ": " + _inventoryDepositRequests[index].lpn),
                subtitle:
                Column(
                    children: <Widget>[
                      Row(
                          children: <Widget>[
                            Text(
                                CWMSLocalizations.of(context).item + ": ",
                                textScaleFactor: .9,
                                style: TextStyle(
                                  height: 1.15,
                                  color: Colors.blueGrey[700],
                                  fontSize: 17,
                                )
                            ),
                            Text(
                                _inventoryDepositRequests[index].itemName,
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
                                CWMSLocalizations.of(context).quantity + ": ",
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
            height: 75,
            child:
            ListTile(
              title: Text(CWMSLocalizations.of(context).lpn + ": " + _inventoryDepositRequests[index].lpn),
              subtitle:
              Column(
                  children: <Widget>[
                    Row(
                        children: <Widget>[
                          Text(
                              CWMSLocalizations.of(context).item + ": ",
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                          Text(
                              _inventoryDepositRequests[index].itemName,
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
                              CWMSLocalizations.of(context).quantity + ": ",
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
            )
        );
    }
    else {
      double height = min(75 + (_inventoryDepositRequests[index].result.length / 50) * 15, 120);
      return
        SizedBox(
            height: height,
            child:
            ListTile(
              title: Text(CWMSLocalizations.of(context).lpn + ": " + _inventoryDepositRequests[index].lpn),
              subtitle:
              Column(
                  children: <Widget>[
                    Row(
                        children: <Widget>[
                          Text(
                              CWMSLocalizations.of(context).item + ": ",
                              textScaleFactor: .9,
                              style: TextStyle(
                                height: 1.15,
                                color: Colors.blueGrey[700],
                                fontSize: 17,
                              )
                          ),
                          Text(
                              _inventoryDepositRequests[index].itemName,
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
                              CWMSLocalizations.of(context).quantity + ": ",
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
                            child: Text(CWMSLocalizations.of(context).result + ": " + _inventoryDepositRequests[index].result.toString(),
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

  @override
  void dispose() {
    super.dispose();
    // remove any timer so we won't need to load the next work again after
    // the user return from this page
    _timer?.cancel();


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