import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/models/lpn_capture_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/widgets/inventory_deposit_request_item.dart';
import 'package:cwms_mobile/inventory/widgets/inventory_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


class LpnCapturePage extends StatefulWidget{

  LpnCapturePage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _LpnCapturePageState();

}

class _LpnCapturePageState extends State<LpnCapturePage> {

  LpnCaptureRequest _lpnCaptureRequest;
  TextEditingController _lpnController = new TextEditingController();
  FocusNode _lpnFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();


    _lpnFocusNode.addListener(() {
      print("_lpnFocusNode.hasFocus: ${_lpnFocusNode.hasFocus}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _enterOnLPNController();
      }
    });

  }

  @override
  Widget build(BuildContext context) {


    _lpnCaptureRequest = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).captureLPN)),
      body:  Padding(
               padding: const EdgeInsets.all(16.0),
               child:
                 Column(
                    children: <Widget>[
                      buildTwoSectionInformationRow(
                        CWMSLocalizations.of(context).item,
                        _lpnCaptureRequest.item.name,
                      ),
                      buildTwoSectionInformationRow(
                        CWMSLocalizations.of(context).item,
                        _lpnCaptureRequest.item.description,
                      ),
                      buildTwoSectionInformationRow(
                        CWMSLocalizations.of(context).itemPackageType,
                        _lpnCaptureRequest.itemPackageType.description,
                      ),
                      buildFourSectionInformationRow(
                        CWMSLocalizations.of(context).lpnUnitOfMeasure,
                        _lpnCaptureRequest.lpnUnitOfMeasure.unitOfMeasure.name,
                        CWMSLocalizations.of(context).quantity,
                        _lpnCaptureRequest.lpnUnitOfMeasure.quantity.toString()
                      ),
                      buildTwoSectionInformationRow(
                        CWMSLocalizations.of(context).requestedLPNQuantity,
                        _lpnCaptureRequest.requestedLPNQuantity.toString(),
                      ),
                      buildTwoSectionInformationRow(
                        CWMSLocalizations.of(context).capturedLPNQuantity,
                        _lpnCaptureRequest.capturedLpn.length.toString()
                      ),
                      buildTwoSectionInputRow(
                        CWMSLocalizations.of(context).lpn,
                        Focus(
                          child:
                            SystemControllerNumberTextBox(
                                type: "lpn",
                                controller: _lpnController,
                                readOnly: false,
                                showKeyboard: false,
                                focusNode: _lpnFocusNode,
                                autofocus: true,
                          ),
                        )
                      ),
                      _buildLpnDisplay(context),
                      _buildButtons(context),

                 ]))

    );
  }

  Widget _buildLpnDisplay(BuildContext context) {

    return
      SizedBox(
        height: MediaQuery.of(context).size.height - 400 > _lpnCaptureRequest.capturedLpn.length * 50.0 ?
        _lpnCaptureRequest.capturedLpn.length * 50.0 : MediaQuery.of(context).size.height - 400,
        child:
        new ListView(
          children: _lpnCaptureRequest.capturedLpn.map((String lpn) {
            return new CheckboxListTile(
              title: new Text(lpn),
              value: true,
              onChanged: (bool value) {
                if (value == false) {
                  setState(() {
                    _lpnCaptureRequest.capturedLpn.remove(lpn);
                  });
                }
              },
            );
          }).toList(),
        ),
      );
  }

  Widget _buildButtons(BuildContext context) {

    return buildTwoButtonRow(context,

        ElevatedButton(
            onPressed: _onCancel,
            child: Text(CWMSLocalizations.of(context).cancel)
        ),
        ElevatedButton(
            onPressed: _lpnCaptureRequest.capturedLpn.length == _lpnCaptureRequest.requestedLPNQuantity ? _onConfirm : null,
            child: Text(CWMSLocalizations.of(context).confirm)
        ),
    );
  }


  void _enterOnLPNController( ) async {

    if (_lpnController.text.isEmpty) {
      return;
    }
    if (_lpnCaptureRequest.capturedLpn.length == _lpnCaptureRequest.requestedLPNQuantity) {
      showToast(CWMSLocalizations.of(context).enoughLPNCaptured);
      return;
    }
    printLongLogMessage("_lpnController.text: ${_lpnController.text}");
    printLongLogMessage("_lpnCaptureRequest.capturedLpn.contains(_lpnController.text): ${_lpnCaptureRequest.capturedLpn.contains(_lpnController.text)}");

    setState(() {
      _lpnCaptureRequest.capturedLpn.add(_lpnController.text);
    });
    _lpnController.clear();
    _lpnFocusNode.requestFocus();

  }

  void _onConfirm() {

    _lpnCaptureRequest.result = true;
    Navigator.pop(context, _lpnCaptureRequest);
  }


  void _onCancel() {

    _lpnCaptureRequest.result = false;
    Navigator.pop(context, _lpnCaptureRequest);
  }



}