import 'package:badges/badges.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_batch.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_request_action.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/services/cycle_count_batch.dart';
import 'package:cwms_mobile/inventory/services/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/widgets/count_batch_list_item.dart';
import 'package:cwms_mobile/inventory/widgets/inventory_deposit_request_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

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

    inventoryOnRF = new List<Inventory>();



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
          hintText: "please input batch id",
          suffixIcon:
            IconButton(
              onPressed: _startLPNBarcodeScanner,
              icon: Icon(Icons.scanner),
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
            RaisedButton(
              color: Theme.of(context).primaryColor,
              onPressed: _onAddingLPN,
              textColor: Colors.white,
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
                child: RaisedButton(
                  onPressed: inventoryOnRF.length == 0 ? null : _startDeposit,
                  child: Text(CWMSLocalizations.of(context).depositInventory),
                ),
              )
          ),
        ],
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
    showLoading(context);
    // move the inventory being scanned onto RF
    printLongLogMessage("==>> Start to adding LPN for deposit");

    List<Inventory> inventories = await InventoryService.findInventory(lpn :_lpnController.text, includeDetails: false);
    printLongLogMessage("==>> LPN ${_lpnController.text} is found");
    if(inventories.isNotEmpty) {

      // move each inventory on to the RF
      printLongLogMessage("==>> Start to get the RF's location");
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

      Navigator.of(context).pop();
      _lpnController.clear();

      showToast(CWMSLocalizations.of(context).actionComplete);
      printLongLogMessage("==>> start to reload inventory after adding the lpn ${_lpnController.text}");
      _reloadInventoryOnRF();
      printLongLogMessage("==>> inventory loaded");
    }
    else {
      // show error message

      Navigator.of(context).pop();
      showToast(CWMSLocalizations.of(context).noInventoryFound);
    }
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