import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../shared/models/barcode.dart';
import '../../shared/services/barcode_service.dart';


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
  FocusNode _lpnFocusNode = FocusNode();
  TextEditingController _itemController = new TextEditingController();


  final  _formKey = GlobalKey<FormState>();


  @override
  void initState() {
    super.initState();


    _lpnFocusNode.addListener(() {
      print("_lpnFocusNode.hasFocus: ${_lpnFocusNode.hasFocus}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        Barcode barcode = BarcodeService.parseBarcode(_lpnController.text);
        if (barcode.is_2d) {
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

      }
    });

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("CWMS - Inventory")),
      resizeToAvoidBottomInset: true,
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
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                       if (_formKey.currentState.validate()) {
                         print("form validation passed");
                         _onInventoryQuery();
                       }
                    },
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
                    focusNode: _lpnFocusNode,
                    decoration: InputDecoration(
                      labelText: CWMSLocalizations
                          .of(context)
                          .lpn,
                      hintText: CWMSLocalizations
                          .of(context)
                          .inputLPNHint,
                      suffixIcon:
                        IconButton(
                          onPressed: () => _clearLpnField(),
                          icon: Icon(Icons.close),
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
                        onPressed: () => _clearLocationField(),
                        icon: Icon(Icons.close),
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
                        onPressed: () => _clearItemField(),
                        icon: Icon(Icons.close),
                      ),

                  ),
                ),

              ]
          )
      );
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

  _clearLpnField() {
    _lpnController.clear();
  }
  _clearItemField() {
    _itemController.clear();
  }
  _clearLocationField() {
    _locationController.clear();
  }




}