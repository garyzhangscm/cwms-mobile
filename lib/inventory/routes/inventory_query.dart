import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/widgets/inventory_deposit_request_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


class InventoryQueryPage extends StatefulWidget{

  InventoryQueryPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _InventoryQueryPageState();

}

class _InventoryQueryPageState extends State<InventoryQueryPage> {

  // show LPN and Item
  // allow the user to choose LPN or Item if there're
  // multiple LPN to deposit, or multiple Item on the same LPN to deposit
  TextEditingController _locationController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();
  TextEditingController _itemController = new TextEditingController();


  final  _formKey = GlobalKey<FormState>();



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("CWMS - Deposit")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.always, //开启自动校验
          child: Column(
            children: <Widget>[
              _buildLocationScanner(context),
              _buildLPNScanner(context),
              _buildItemScanner(context),

              Padding(
                padding: const EdgeInsets.only(top: 25),
                child: ConstrainedBox(
                  constraints: BoxConstraints.expand(height: 55.0),
                  child: RaisedButton(
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                       if (_formKey.currentState.validate()) {
                         print("form validation passed");
                         _onInventoryQuery();
                       }
                    },
                    textColor: Colors.white,
                    child: Text(CWMSLocalizations.of(context).query),
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


  // scan in barcode to add a order into current batch
  Widget _buildLPNScanner(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
             children: <Widget>[
                 TextFormField(
                    controller: _lpnController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: CWMSLocalizations
                          .of(context)
                          .lpn,
                      hintText: CWMSLocalizations
                          .of(context)
                          .inputLPNHint,
                      suffixIcon:
                        IconButton(
                          onPressed:  _startLPNBarcodeScanner,
                          icon: Icon(Icons.scanner),
                        ),
                    ),
                 ),

             ]
          )
      );
  }

  // scan in location barcode to confirm
  Widget _buildLocationScanner(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _locationController,
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


  // scan in location barcode to confirm
  Widget _buildItemScanner(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _itemController,
                  decoration: InputDecoration(
                    labelText: CWMSLocalizations
                        .of(context)
                        .item,
                    hintText: CWMSLocalizations
                        .of(context)
                        .inputItemHint,
                    suffixIcon:
                    IconButton(
                      onPressed: _startItemBarcodeScanner,
                      icon: Icon(Icons.scanner),
                    ),

                  ),
                ),

              ]
          )
      );
  }


  void _startLPNBarcodeScanner() async  {
    String lpnScanned = await _startBarcodeScanner();
    if (lpnScanned != "-1") {

      _lpnController.text = lpnScanned;

    }


  }
  void _startLocationBarcodeScanner() async  {
    String locationScanned = await _startBarcodeScanner();
    if (locationScanned != "-1") {

      _locationController.text = locationScanned;
    }

  }
  void _startItemBarcodeScanner() async  {
    String locationScanned = await _startBarcodeScanner();
    if (locationScanned != "-1") {

      _itemController.text = locationScanned;
    }

  }
  Future<String> _startBarcodeScanner() async {
    /*
    *
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print("barcode scanned: $barcodeScanRes");
    return barcodeScanRes;
    * */

  }
  _onInventoryQuery() async {

    showLoading(context);
    List<Inventory> inventories =
        await InventoryService.findInventory(
          locationName: _locationController.text,
          itemName: _itemController.text,
          lpn: _lpnController.text,
        );


    Navigator.of(context).pop();

    if (inventories.length == 0) {

      showToast(CWMSLocalizations.of(context).noInventoryFound);
    }
    else {
      printLongLogMessage("will flow to invenory with ${inventories.length} inventory records");
      Navigator.of(context)
          .pushNamed("inventory_display", arguments: inventories);


    }
  }




}