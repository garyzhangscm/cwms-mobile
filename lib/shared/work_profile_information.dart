

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/states/profile_change_notifier.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:provider/provider.dart';

import 'global.dart';


class WorkProfileInfoPage extends StatefulWidget{

  WorkProfileInfoPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _WorkProfileInfoPageState();

}


class _WorkProfileInfoPageState extends State<WorkProfileInfoPage> {

  final  _formKey = GlobalKey<FormState>();

  TextEditingController _locationController = new TextEditingController();

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context)!.workProfile)),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.always, //开启自动校验
          child: Column(
            children: <Widget>[
              _buildLocationScanner(context),
              Padding(
                padding: const EdgeInsets.only(top: 25),
                child: ConstrainedBox(
                  constraints: BoxConstraints.expand(height: 55.0),
                  child:
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          print("form validation passed");
                          _changeWorkProfile();
                        }

                      },
                      child: Text(CWMSLocalizations.of(context)!.confirm),
                    ),
                ),
              ),
            ],
          ),
        ),
      ),
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


  void _startLocationBarcodeScanner() async  {
    String locationScanned = await _startBarcodeScanner();
    if (locationScanned != "-1") {

      _locationController.text = locationScanned;
    }

  }

  Future<String> _startBarcodeScanner() async {
    /***
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
    print("barcode scanned: $barcodeScanRes");
    return barcodeScanRes;
**/
  }

  _changeWorkProfile() {
    if (_locationController.text.isNotEmpty) {
      _changeCurrentLocation();
    }
    // return
    Navigator.pop(context);

  }
  _changeCurrentLocation() {
    WarehouseLocationService
        .getWarehouseLocationByName(_locationController.text)
        .then((location) => Global.setLastActivityLocation(location));

  }
}
