import 'dart:math';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/reversed_inventory_information.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/services/barcode_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../shared/services/barcode_service.dart';
import '../../shared/models/barcode.dart';

import '../../shared/http_client.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


class ReverseReceivingPage extends StatefulWidget{

  ReverseReceivingPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _ReverseReceivingPageState();

}

class _ReverseReceivingPageState extends State<ReverseReceivingPage> {


  final  _formKey = GlobalKey<FormState>();
  // information for display. When there's multiple inventory attribute
  // match with the LPN input, then we will show MULTIPLE-VALUES instead of
  // the actual value and won't allow reverse
  List<ReversedInventoryInformation> _reversedInventories = [];


  TextEditingController _lpnController = new TextEditingController();
  FocusNode _lpnFocusNode = FocusNode();

  @override
  void initState() {

    super.initState();


    _lpnFocusNode.addListener(() {
      print("lpnFocusNode.hasFocus: ${_lpnFocusNode.hasFocus}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
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
        _addReversedInventory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).reverseReceiving)),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Form(
          key: _formKey,
          // autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[
              _buildLPNController(context),
              _buildButtons(context),
              _buildReverseInventoryInformationDisplay(context),
              // _buildEmptyReverseInventoryInformationDisplay(context),
            ],
          ),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }


  void _clear() {

    setState(() {

      _reversedInventories = [];
    });
    _lpnController.clear();

  }
  void _addReversedInventory() async {
    if (_lpnController.text.isEmpty) {
      showErrorDialog(context, "please input the LPN number");
      return;
    }
    // add the LPN to the request

    ReversedInventoryInformation reversedInventoryInformation =
      ReversedInventoryInformation.fromReceivedInventory(
          _lpnController.text, "", "", "",
          0, "", "");

    // add it to the list so we can display the result
    reversedInventoryInformation.reverseInProgress = true;
    reversedInventoryInformation.reverseResult = false;
    _reversedInventories.insert(0, reversedInventoryInformation);
    setState(() {
      _reversedInventories;
    });
    _addReversedInventorySync(reversedInventoryInformation, retryTime: 0);

    _lpnController.clear();

    _lpnFocusNode.requestFocus();

  }

  void _addReversedInventorySync(ReversedInventoryInformation reversedInventoryInformation, {int retryTime = 0}) {

    InventoryService.findInventory(lpn :_lpnController.text, includeDetails: true).then((inventories) async {
      printLongLogMessage("find ${inventories.length} inventories");

      if (inventories.isEmpty) {
        reversedInventoryInformation.reverseInProgress = false;
        reversedInventoryInformation.reverseResult = false;
        reversedInventoryInformation.result = CWMSLocalizations
            .of(context)
            .noInventoryFound;

        setState(() {
          _reversedInventories;
        });
        return;
      }

      Set<String> clientNames = new Set();
      Set<String> itemNames = new Set();
      Set<String> itemPackageTypeNames = new Set();
      Set<String> receiptNumbers = new Set();
      int totalQuantity = 0;
      bool includeNonReceiptInventory = false;
      String locationName = "";

      inventories.forEach((inventory) {
        clientNames.add(inventory.client == null ? "" : inventory.client.name);
        itemNames.add(inventory.item.name);
        itemPackageTypeNames.add(inventory.itemPackageType.name);
        totalQuantity += inventory.quantity;
        locationName = inventory.locationName;
        if (inventory.receiptNumber == "" && inventory.receipt == null) {
          includeNonReceiptInventory = true;
        }
        else {
          receiptNumbers.add(inventory.receiptNumber);
        }
      });

      // make sure the LPN is not mixed with client, item
      // or work orders
      if (includeNonReceiptInventory) {
        reversedInventoryInformation.reverseInProgress = false;
        reversedInventoryInformation.reverseResult = false;
        reversedInventoryInformation.result = CWMSLocalizations
            .of(context)
            .reverseErrorNoReceipt;

        setState(() {
          _reversedInventories;
        });
        return;
      }
      if (receiptNumbers.length > 1) {
        reversedInventoryInformation.reverseInProgress = false;
        reversedInventoryInformation.reverseResult = false;
        reversedInventoryInformation.result = CWMSLocalizations
            .of(context)
            .reverseErrorMixedReceipt;

        setState(() {
          _reversedInventories;
        });
        return;
      }
      if (clientNames.length > 1) {
        reversedInventoryInformation.reverseInProgress = false;
        reversedInventoryInformation.reverseResult = false;
        reversedInventoryInformation.result = CWMSLocalizations
            .of(context)
            .reverseErrorMixedWithClient;

        setState(() {
          _reversedInventories;
        });
        return;
      }
      if (itemNames.length > 1) {
        reversedInventoryInformation.reverseInProgress = false;
        reversedInventoryInformation.reverseResult = false;
        reversedInventoryInformation.result = CWMSLocalizations
            .of(context)
            .reverseErrorMixedWithItem;

        setState(() {
          _reversedInventories;
        });
        return;
      }

      printLongLogMessage(
          "start to add the inventory ${reversedInventoryInformation
              .lpn} to display");


      reversedInventoryInformation.clientName = clientNames.first;
      reversedInventoryInformation.itemName = itemNames.first;
      reversedInventoryInformation.itemPackageTypeName =
      itemPackageTypeNames.length > 1 ? "MULTIPLE-VALUES" : itemPackageTypeNames
          .first;
      reversedInventoryInformation.receiptNumber = receiptNumbers.first;
      reversedInventoryInformation.locationName = locationName;
      reversedInventoryInformation.quantity = totalQuantity;
      reversedInventoryInformation.reverseResult = false;
      reversedInventoryInformation.reverseInProgress = true;
      reversedInventoryInformation.result = "";

      setState(() {
        _reversedInventories;
      });

        for (var inventory in inventories) {
          await InventoryService.reverseReceivedInventory(inventory.id);
        }
        setState(() {
          reversedInventoryInformation.reverseResult = true;
          reversedInventoryInformation.reverseInProgress = false;
          _reversedInventories;
        });
    })
    .catchError((err) {

      if (err is DioError ) {
        // for timeout error and we are still in the retry threshold, let's try again
        // retry after 2 second

        if (retryTime <= CWMSHttpClient.timeoutRetryTime) {
          Future.delayed(const Duration(milliseconds: 2000),
                  () => _addReversedInventorySync(reversedInventoryInformation, retryTime: retryTime + 1));
        }
        else {
          setState(() {
            reversedInventoryInformation.reverseResult = false;
            reversedInventoryInformation.reverseInProgress = false;
            reversedInventoryInformation.result = "Fail to reverse LPN: " + reversedInventoryInformation.lpn + " after trying ${CWMSHttpClient.timeoutRetryTime}  times";
            _reversedInventories;
          });
        }
      }
      else if (err is WebAPICallException){
        // for any other error display it
        final webAPICallException = err as WebAPICallException;
        setState(() {
          reversedInventoryInformation.reverseResult = false;
          reversedInventoryInformation.reverseInProgress = false;
          reversedInventoryInformation.result = webAPICallException.errMsg() ;
          _reversedInventories;
        });
      }
      else {

        setState(() {
          reversedInventoryInformation.reverseResult = false;
          reversedInventoryInformation.reverseInProgress = false;
          reversedInventoryInformation.result = err.toString();
          _reversedInventories;
        });
      }
    });
  }

  Widget _buildLPNController(BuildContext context) {
    return buildTwoSectionInputRow(CWMSLocalizations.of(context).lpn,
        TextFormField(
            controller: _lpnController,
            autofocus: true,
            // 校验用户名（不能为空）
            focusNode: _lpnFocusNode,
            decoration: InputDecoration(
              suffixIcon:
              IconButton(
                onPressed: () => _clear(),
                icon: Icon(Icons.close),
              ),
            ),
            validator: (v) {
              return v.trim().isNotEmpty ?
              null :
              CWMSLocalizations.of(context).missingField(
                  CWMSLocalizations.of(context).lpn);
            })
    );
  }

  Widget _buildReverseInventoryInformationDisplay(BuildContext context) {

    return
      Expanded(
        child: ListView.separated(
              itemCount: _reversedInventories.length,
              itemBuilder: (BuildContext context, int index) {

                return _buildReverseInventoryInformationListTile(context, index);
              },
              separatorBuilder: (context, index) => Divider(
                color: Colors.black,
              ),
        )
      );
  }

  Widget _buildReverseInventoryInformationListTile(BuildContext context, int index) {

    printLongLogMessage("index ${index}");
    printLongLogMessage("_reversedInventories[index].reverseInProgress: ${_reversedInventories[index].reverseInProgress}");
    printLongLogMessage("_reversedInventories[index].reverseInProgress: ${_reversedInventories[index].reverseResult}");

    if (_reversedInventories[index].reverseInProgress == true) {
      // show loading indicator if the inventory still reverse in progress
      printLongLogMessage("show loading for index $index / ${_reversedInventories[index].lpn}");
      return SizedBox(
          height: 75,
          child:  Stack(
            alignment:Alignment.center ,
            fit: StackFit.expand, //未定位widget占满Stack整个空间
            children: <Widget>[
              ListTile(
                title: Text(CWMSLocalizations.of(context).lpn + ": " + _reversedInventories[index].lpn),
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
                                _reversedInventories[index].itemName,
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
                                _reversedInventories[index].quantity.toString(),
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
    else if(_reversedInventories[index].reverseResult == true) {
      return
        SizedBox(
          height: 75,
          child:
            ListTile(
              title: Text(CWMSLocalizations.of(context).lpn + ": " + _reversedInventories[index].lpn),
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
                          _reversedInventories[index].itemName,
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
                          _reversedInventories[index].quantity.toString(),
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
      double height = min(75 + (_reversedInventories[index].result.length / 50) * 15, 120);
      return
        SizedBox(
            height: height,
            child:
            ListTile(
              title: Text(CWMSLocalizations.of(context).lpn + ": " + _reversedInventories[index].lpn),
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
                              _reversedInventories[index].itemName,
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
                              _reversedInventories[index].quantity.toString(),
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
                            child: Text(CWMSLocalizations.of(context).result + ": " + _reversedInventories[index].result.toString(),
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


  Widget _buildButtons(BuildContext context) {
    return buildSingleButtonRow(context,
      ElevatedButton(
        onPressed: _clear,
        child: Text(CWMSLocalizations
            .of(context).clear),
      ),
    );

  }
}