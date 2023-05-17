import 'package:badges/badges.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/widgets/inventory_deposit_request_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
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
  }

  Widget _buildButtons(BuildContext context) {

    return buildTwoButtonRow(context,
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
        )
    );
    /**
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
                onPressed: _onAddingLPN,
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
    _moveInventoryAsync(_lpnController.text, retryTime: 0);

    showToast("LPN putaway request sent");
    _lpnController.clear();
    lpnFocusNode.requestFocus();
  }
  /// move inventory async
  void _moveInventoryAsync(String lpn, {int retryTime = 0}) {
    // showLoading(context);
    // move the inventory being scanned onto RF
    printLongLogMessage("==>> Start to adding LPN for deposit");
    InventoryService.findInventory(lpn : lpn, includeDetails: false)
        .then((inventories) async {

            if(inventories.isNotEmpty) {

              WarehouseLocation rfLocation =
                  await WarehouseLocationService.getWarehouseLocationByName(
                  Global.lastLoginRFCode
              );
              printLongLogMessage("==>> GOT RF location ");

              for(Inventory inventory in inventories) {
                printLongLogMessage("==>> start to move invenotry with id ${inventory.id} lpn ${inventory.lpn}");

                await InventoryService.moveInventory(
                      inventoryId: inventory.id,
                      destinationLocation: rfLocation
                  );

                printLongLogMessage("==>> finish moving invenotry with id ${inventory.id} lpn ${inventory.lpn}");
              }

              // Navigator.of(context).pop();

              // showToast(CWMSLocalizations.of(context).actionComplete);
              printLongLogMessage("==>> start to reload inventory after adding the lpn ${_lpnController.text}");
              _reloadInventoryOnRF();
              printLongLogMessage("==>> inventory loaded");

            }
            else {
              // show error message

              showErrorDialog(context, CWMSLocalizations.of(context).noInventoryFound + ", LPN: " + lpn);

              // Navigator.of(context).pop();
              // showToast(CWMSLocalizations.of(context).noInventoryFound);
            }
        })
        .catchError((err) {
            if (err is DioError &&
                err.type == DioErrorType.connectTimeout &&
                retryTime <= CWMSHttpClient.timeoutRetryTime) {
              // for timeout error and we are still in the retry threshold, let's try again
              _moveInventoryAsync(lpn, retryTime: retryTime + 1);
            }
            else if (err is WebAPICallException) {
                // for business error, show the result
              showErrorDialog(context, err.errMsg() + ", LPN: " + lpn);
              return;
            }
            // ignore any other error

    });

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