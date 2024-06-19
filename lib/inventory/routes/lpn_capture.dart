
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/lpn_capture_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/models/cwms_http_exception.dart';
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../shared/services/barcode_service.dart';
import '../../shared/models/barcode.dart';


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
        // allow the user to input barcode

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

        _enterOnLPNController();
      }
    });

  }

  @override
  Widget build(BuildContext context) {


    _lpnCaptureRequest = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).captureLPN)),
      resizeToAvoidBottomInset: true,
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



    // if we only allow new LPN, then make sure the LPN entered in is
    // a new LPN
    if (_lpnCaptureRequest.newLPNOnly) {
      showLoading(context);
      try {
        String errorMessage = await InventoryService.validateNewLpn(_lpnController.text);
        if (errorMessage.isNotEmpty) {
          Navigator.of(context).pop();
          showErrorDialog(context, errorMessage);
          return;
        }
      }
      on CWMSHttpException catch(ex) {

        Navigator.of(context).pop();
        showErrorDialog(context, ex.message);
        return;
      }
      Navigator.of(context).pop();
    }

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