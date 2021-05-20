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
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


class InventoryDepositPage extends StatefulWidget{

  InventoryDepositPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _InventoryDepositPageState();

}

class _InventoryDepositPageState extends State<InventoryDepositPage> {

  // show LPN and Item
  // allow the user to choose LPN or Item if there're
  // multiple LPN to deposit, or multiple Item on the same LPN to deposit
  TextEditingController _lpnController = new TextEditingController();
  TextEditingController _locationController = new TextEditingController();
  List<Inventory> inventoryOnRF;
  InventoryDepositRequest inventoryDepositRequest;

  final  _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    print("Start to get inventory on RF");
    inventoryDepositRequest = new InventoryDepositRequest();
    inventoryOnRF = new List<Inventory>();
    _refreshInventoryOnRF();
  }

  void _refreshInventoryOnRF() {
    InventoryService.getInventoryOnCurrentRF().then((value)  async {
      inventoryOnRF = value;

      if (inventoryOnRF.isEmpty) {
        // no inventory on the RF yet
        // return to the previous page
        printLongLogMessage("start to show dialog");
        await showDialog(
            context: context,
            builder: (context) {
              return
                AlertDialog(
                  title: Text("提示"),
                  content: Text("No more inventory on the RF"),
                  actions: <Widget>[

                    FlatButton(
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
          _locationController.text = "";
        });
      }
    });

  }

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
              _buildLPNScanner(context),
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
                Row(
                    children: <Widget>[
                      Text("Item:",
                        textAlign: TextAlign.left,
                      ),
                      Text(inventoryDepositRequest.itemName,
                        textAlign: TextAlign.left,
                      ),
                    ]
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
                Row(
                    children: <Widget>[
                      Text("Item:",
                        textAlign: TextAlign.left,
                      ),
                      Text(inventoryDepositRequest.itemDescription,
                        textAlign: TextAlign.left,
                      ),
                    ]
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
                Row(
                    children: <Widget>[
                      Text("Inventory Status:",
                        textAlign: TextAlign.left,
                      ),
                      Text(inventoryDepositRequest.inventoryStatusName,
                        textAlign: TextAlign.left,
                      ),
                    ]
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
                Row(
                    children: <Widget>[
                      Text("Inventory Status:",
                        textAlign: TextAlign.left,
                      ),
                      Text(inventoryDepositRequest.inventoryStatusDescription,
                        textAlign: TextAlign.left,
                      ),
                    ]
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
                Row(
                    children: <Widget>[
                      Text("Quantity:",
                        textAlign: TextAlign.left,
                      ),
                      Text(inventoryDepositRequest.quantity.toString(),
                        textAlign: TextAlign.left,
                      ),
                    ]
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10, bottom: 10),
                child:
                Row(
                    children: <Widget>[
                      Text("Location:",
                        textAlign: TextAlign.left,
                      ),
                      Text(inventoryDepositRequest.nextLocation == null? "" : inventoryDepositRequest.nextLocation.name,
                        textAlign: TextAlign.left,
                      ),
                    ]
                ),
              ),
              _buildLocationScanner(context),
              Padding(
                padding: const EdgeInsets.only(top: 25),
                child: ConstrainedBox(
                  constraints: BoxConstraints.expand(height: 55.0),
                  child: RaisedButton(
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                       if (_formKey.currentState.validate()) {
                         print("form validation passed");
                         _onDepositConfirm(inventoryDepositRequest);
                       }

                    },
                    textColor: Colors.white,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                          mainAxisSize: MainAxisSize.min, // added line
                          children: <Widget>[
                            IconButton(
                              onPressed: _singleLPNDeposit() ? null :  _startLPNBarcodeScanner,
                              icon: Icon(Icons.scanner),
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

  InventoryDepositRequest _getNextInventoryToDeposit() {

    return InventoryService.getNextInventoryDepositRequest(inventoryOnRF, true, true);

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
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print("barcode scanned: $barcodeScanRes");
    return barcodeScanRes;

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
      }
      else {
        inventoryDepositRequest = _getNextInventoryToDeposit();
        _lpnController.text = inventoryDepositRequest.lpn;
        _locationController.text = "";
      }
    });

  }


  void _onDepositConfirm(InventoryDepositRequest inventoryDepositRequest) async {


    printLongLogMessage("start to deposit invenotry ${inventoryDepositRequest.lpn}");

    showLoading(context);
    // Let's get the location first
    WarehouseLocation destinationLocation =
        await WarehouseLocationService.getWarehouseLocationByName(
            _locationController.text
        );


    printLongLogMessage("location ${destinationLocation.name} verified!");

    for (int i = 0; i < inventoryDepositRequest.inventoryIdList.length; i++) {
      int inventoryId = inventoryDepositRequest.inventoryIdList[i];

      await InventoryService.moveInventory(
          inventoryId: inventoryId,
          destinationLocation: destinationLocation
      );
    }

    printLongLogMessage("all inventory is deposit");
    Navigator.of(context).pop();

    showToast("inventory deposit");

    // let's get next inventory to be deposit
    _refreshInventoryOnRF();


  }

}