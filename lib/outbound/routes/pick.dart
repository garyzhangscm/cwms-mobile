import 'dart:math';

import 'package:badges/badges.dart' as badge;
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/models/pick_result.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../../common/services/rf.dart';
import '../../inventory/models/item_unit_of_measure.dart';
import '../../shared/global.dart';
import '../../shared/models/barcode.dart';
import '../../shared/services/barcode_service.dart';


class PickPage extends StatefulWidget{

  PickPage({Key? key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _PickPageState();

}

class _PickPageState extends State<PickPage> {

  // input batch id
  TextEditingController _itemController = new TextEditingController();
  TextEditingController _sourceLocationController = new TextEditingController();
  TextEditingController _quantityController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();
  Pick? _currentPick;
  FocusNode _lpnFocusNode = FocusNode();
  FocusNode _lpnControllerFocusNode = FocusNode();
  FocusNode _sourceLocationFocusNode = FocusNode();
  FocusNode _sourceLocationControllerFocusNode = FocusNode();
  FocusNode _quantityFocusNode = FocusNode();
  FocusNode _quantityControllerFocusNode = FocusNode();


  String? _workNumber;
  int _lpnQuantity = 0;

  // pickable inveotory's item package type. Used to show how to pick
  // if the source location is mixed of item package types, then
  // show (Mixed Item Package Type)
  // if the source location is not mixed of item package type,
  // then show (X case, Y package, Z Each)
  ItemPackageType? _pickableInventoryItemPackageType;


  final  _formKey = GlobalKey<FormState>();

  List<Inventory>  inventoryOnRF = [];

  // if pick to a specific destination LPN
  String? _destinationLPN;
  bool? _retainLPNForLPNPick;

  List<String> _pickErrorOptions = [];
  String _selectedPickErrorOption = "";

  @override
  void initState() {
    super.initState();

    _selectedPickErrorOption = "";

    _itemController.clear();
    _sourceLocationController.clear();
    _quantityController.clear();
    _lpnController.clear();
    _destinationLPN = "";
    _workNumber = "";
    _lpnQuantity = 0;
    _pickableInventoryItemPackageType = null;

    inventoryOnRF = [];

    _reloadInventoryOnRF();

    _sourceLocationFocusNode.addListener(() async {
      printLongLogMessage("_sourceLocationFocusNode hasFocus?: ${_sourceLocationFocusNode.hasFocus}");
      printLongLogMessage("_sourceLocationController text?: ${_sourceLocationController.text}");
      if (!_sourceLocationFocusNode.hasFocus && _sourceLocationController.text.isNotEmpty) {
        _enterOnLocationController(10);

      }});

    _lpnFocusNode.addListener(() async {
      printLongLogMessage("_lpnFocusNode hasFocus?: ${_lpnFocusNode.hasFocus}");
      printLongLogMessage("_sourceLocationController text?: ${_lpnController.text}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
        Barcode barcode = BarcodeService.parseBarcode(_lpnController.text);
        printLongLogMessage("barcode.is_2d?: ${barcode.is_2d}");
        if (barcode.is_2d == true) {
          // for 2d barcode, let's get the result and set the LPN back to the text
          String lpn = _getLPNFrom2DBarcode(barcode);
          printLongLogMessage("get lpn from lpn?: ${lpn}");
          if (lpn == "") {

            showErrorDialog(context, "can't get LPN from the barcode");
            return;
          }
          else {
            _lpnController.text = lpn;
          }
        }
        _enterOnLPNController(10);

      }});

    /**
    _quantityFocusNode.addListener(() async {
      printLongLogMessage("_quantityFocusNode hasFocus?: ${_quantityFocusNode.hasFocus}");
      printLongLogMessage("_quantityController text?: ${_quantityController.text}");
      if (!_quantityFocusNode.hasFocus && _quantityController.text.isNotEmpty) {
        _enterOnQuantityController(10);

      }});
**/

  }

  @override
  Future<void> didChangeDependencies() async {

    // extract the argument
    printLongLogMessage("start to get picks and related mode");
    Map arguments  = ModalRoute.of(context)?.settings.arguments as Map ;


    _currentPick = arguments['pick'];
    _setupPickableInventoryItemPackageType(_currentPick!);
    printLongLogMessage("_currentPick: ${_currentPick?.toJson()}");
    _destinationLPN  = arguments['destinationLPN'] == null ? "" : arguments['destinationLPN'];
    printLongLogMessage("_destinationLPN: $_destinationLPN");
    // when pick a LPN in a batch, whether we want to keep the original LPN
    // or pick into the destination(only if _destinationLPN is passed in)
    _retainLPNForLPNPick  = arguments['retainLPNForLPNPick'] == null ? true : arguments['retainLPNForLPNPick'] as bool;
    _workNumber = arguments['workNumber'] == null || arguments['workNumber'].toString().isEmpty ? _currentPick?.number : arguments['workNumber'];
    printLongLogMessage("_workNumber: $_workNumber");

  }

  String _getLPNFrom2DBarcode(Barcode barcode) {
    String lpn = "";
    barcode.result!.forEach((k, v) {
      if (k.toLowerCase() == "lpn" && v != "") {
        lpn = v;
      }
    });
    return lpn;
  }

  @override
  Widget build(BuildContext context) {
    // _currentPick  = ModalRoute.of(context).settings.arguments;

    return Scaffold(

      appBar: AppBar(title: Text("CWMS - Pick")),
      resizeToAvoidBottomInset: true,
      body:
          Column(
            children: <Widget>[
              buildTwoSectionInformationRow("Work Number:", _workNumber ?? ""),
              buildTwoSectionInformationRow("Location:", _currentPick?.sourceLocation?.name ?? ""),
              _buildLocationInput(context),
              _buildLPNInput(context),
              buildTwoSectionInformationRowWithWidget(
                  CWMSLocalizations.of(context)!.item,
                  _buildItemDisplayWidget(context, _currentPick!)),
              // buildTwoSectionInformationRow("Item Number:", _currentPick.item.name),
              // add the batch pick quantity only if the quantity to be picked is more than the single pick
              // _currentPick.batchPickQuantity > _currentPick.quantity - _currentPick.pickedQuantity ?
              _currentPick!.batchPickQuantity! > 0 ?
                  buildTwoSectionInformationRow("Batch Pick Quantity:",
                      _currentPick!.batchPickQuantity.toString() +
                          (_pickableInventoryItemPackageType == null ? "" :
                              _getPickQuantityIndicator(_currentPick!.batchPickQuantity!)))
                  :
                  buildTwoSectionInformationRow("Pick Quantity:",
                      _currentPick!.quantity.toString() +
                      (_pickableInventoryItemPackageType == null ? "" :
                      _getPickQuantityIndicator(_currentPick!.quantity!))) ,
              buildTwoSectionInformationRow("Picked Quantity:",
                  _currentPick!.pickedQuantity.toString() +
                      (_pickableInventoryItemPackageType == null ? "" :
                      _getPickQuantityIndicator(_currentPick!.pickedQuantity!))),

              (_currentPick!.batchPickQuantity ?? 0) > 0 ?
                  buildTwoSectionInformationRow("Remaining Quantity:",
                      _currentPick!.batchPickQuantity!.toString() +
                          (_pickableInventoryItemPackageType == null ? "" :
                          _getPickQuantityIndicator(_currentPick!.batchPickQuantity!)))
                  :
                  buildTwoSectionInformationRow("Remaining Quantity:",
                      (_currentPick!.quantity! - _currentPick!.pickedQuantity!).toString() +
                          (_pickableInventoryItemPackageType == null ? "" :
                          _getPickQuantityIndicator(_currentPick!.quantity! - _currentPick!.pickedQuantity!))),
              buildTwoSectionInformationRow("Inventory Quantity:",
                      _lpnQuantity.toString() +
                      (_pickableInventoryItemPackageType == null ? "" :
                      _getPickQuantityIndicator(_lpnQuantity))),
              _destinationLPN!.isEmpty? Container() : buildTwoSectionInformationRow("Destination LPN:", _destinationLPN!),
              _buildQuantityInput(context),
              _buildButtons(context),
            ],
          ),
      endDrawer: MyDrawer(),
    );
  }

  // allow the user to tap on the item name to see the inventory attribute
  Widget _buildItemDisplayWidget(BuildContext context, Pick pick) {
    return new RichText(
        text: new TextSpan(
          text: pick.item?.name,
          style: new TextStyle(color: Colors.blue),
          recognizer: new TapGestureRecognizer()
            ..onTap = () {
              showInformationDialog(
                  context, pick.item?.name ?? "",
                  Column(
                      children: <Widget>[
                        buildTwoSectionInformationRow(
                            CWMSLocalizations.of(context)!.item + ":",
                            pick.item?.name ?? ""),
                        buildTwoSectionInformationRow(
                            CWMSLocalizations.of(context)!.item + ":",
                            pick.item?.description ?? ""),
                        buildTwoSectionInformationRow(
                            CWMSLocalizations.of(context)!.color + ":",
                            pick.color ?? ""),
                        buildTwoSectionInformationRow(
                            CWMSLocalizations.of(context)!.style + ":",
                            pick.style ?? ""),
                        buildTwoSectionInformationRow(
                            CWMSLocalizations.of(context)!.productSize + ":",
                            pick.productSize ?? ""),
                        Global.currentInventoryConfiguration?.inventoryAttribute1Enabled == true?
                            buildTwoSectionInformationRow(
                                Global.currentInventoryConfiguration?.getInventoryAttributeDisplayName("attribute1") + ":",
                                pick.inventoryAttribute1 ?? "") : Container(),
                        Global.currentInventoryConfiguration?.inventoryAttribute2Enabled  == true?
                        buildTwoSectionInformationRow(
                            Global.currentInventoryConfiguration?.getInventoryAttributeDisplayName("attribute2") + ":",
                            pick.inventoryAttribute2 ?? "") : Container(),
                        Global.currentInventoryConfiguration?.inventoryAttribute3Enabled  == true?
                            buildTwoSectionInformationRow(
                                Global.currentInventoryConfiguration?.getInventoryAttributeDisplayName("attribute3") + ":",
                                pick.inventoryAttribute3 ?? "") : Container(),
                        Global.currentInventoryConfiguration?.inventoryAttribute4Enabled  == true?
                            buildTwoSectionInformationRow(
                                Global.currentInventoryConfiguration?.getInventoryAttributeDisplayName("attribute4") + ":",
                                pick.inventoryAttribute4 ?? "") : Container(),
                        Global.currentInventoryConfiguration?.inventoryAttribute5Enabled  == true?
                            buildTwoSectionInformationRow(
                                Global.currentInventoryConfiguration?.getInventoryAttributeDisplayName("attribute5") + ":",
                                pick.inventoryAttribute5 ?? "") : Container(),
                      ]
                  ),
                  verticalPadding: 25.0,
                  horizontalPadding: 25.0

              );
            },
        ));

  }

  Widget _buildLocationInput(BuildContext context) {
    return buildTwoSectionInputRow(
        CWMSLocalizations.of(context)!.location,
        _currentPick?.confirmLocationFlag == true || _currentPick?.confirmLocationCodeFlag == true ?
          Focus(
              focusNode: _sourceLocationFocusNode,
              child:
              TextFormField(
                  controller: _sourceLocationController,
                  showCursor: true,
                  autofocus: true,
                  focusNode: _sourceLocationControllerFocusNode,
                  decoration: InputDecoration(
                    suffixIcon:
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                      mainAxisSize: MainAxisSize.min, // added line
                      children: <Widget>[
                        IconButton(
                          onPressed: () {
                            _sourceLocationController.text = "";
                            _sourceLocationControllerFocusNode.requestFocus();
                          },
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                  )

              )
          )
          :
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: Text(_currentPick?.sourceLocation?.name ?? "", textAlign: TextAlign.left ),
          ),
    );
  }


  Widget _buildLPNInput(BuildContext context) {
    return buildTwoSectionInputRow(
      CWMSLocalizations.of(context)!.lpn,
      _currentPick?.confirmLpnFlag == true ?
      Focus(
          focusNode: _lpnFocusNode,
          child:
          TextFormField(
              controller: _lpnController,
              showCursor: true,
              autofocus: true,
              focusNode: _lpnControllerFocusNode,
              decoration: InputDecoration(
                suffixIcon:
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                  mainAxisSize: MainAxisSize.min, // added line
                  children: <Widget>[
                    IconButton(
                      onPressed: () {
                        _lpnController.clear();
                        setState(() {

                          _lpnQuantity = 0;
                        });
                        _quantityController.clear();
                        _lpnControllerFocusNode.requestFocus();
                      },
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
              )

          )
      )
          :
      Container()
    );
  }

  Widget _buildQuantityInput(BuildContext context) {
    return buildTwoSectionInputRow(
        CWMSLocalizations.of(context)!.quantity,
        Focus(
            focusNode: _quantityFocusNode,
            child:
            TextFormField(
                controller: _quantityController,
                showCursor: true,
                autofocus: true,
                focusNode: _quantityControllerFocusNode,
                decoration: InputDecoration(
                  suffixIcon:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                    mainAxisSize: MainAxisSize.min, // added line
                    children: <Widget>[
                      IconButton(
                        onPressed: () => _quantityController.text = "",
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                )

            )
        )
    );
  }

  Widget _buildPickErrorButtons(BuildContext context) {

    _pickErrorOptions = [

      CWMSLocalizations.of(context)!.skip,
      CWMSLocalizations.of(context)!.cancelPickAndReallocate,
    ];
    _selectedPickErrorOption = "";

    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Row(
          children: [
            Icon(
              Icons.list,
              size: 12,
              color: Colors.yellow,
            ),
            SizedBox(
              width: 4,
            ),
            Expanded(
              child: Text(
                'Pick Error',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        items: _pickErrorOptions
            .map((String pickErrorOption) => DropdownMenuItem<String>(
          value: pickErrorOption,
          child: Text(
            pickErrorOption,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ))
            .toList(),
        value: _selectedPickErrorOption,
        onChanged: (value) {
          setState(() {
            _selectedPickErrorOption = value!;
            _processPickError(value);
          });
        },
        buttonStyleData: ButtonStyleData(
          height: 35,
          width: 300,
          padding: const EdgeInsets.only(left: 5, right: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: Colors.black26,
            ),
            color: Colors.redAccent,
          ),
          elevation: 2,
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(
            Icons.arrow_forward_ios_outlined,
          ),
          iconSize: 14,
          iconEnabledColor: Colors.yellow,
          iconDisabledColor: Colors.grey,
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 200,
          width: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.redAccent,
          ),
          offset: const Offset(-20, 0),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(40),
            thickness: MaterialStateProperty.all(6),
            thumbVisibility: MaterialStateProperty.all(true),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 40,
          padding: EdgeInsets.only(left: 14, right: 14),
        ),
      ),
    );
    /**
    ElevatedButton(
        onPressed: _skipCurrentPick,
        child: Text(CWMSLocalizations.of(context)!.skip)
    ),
        */
  }
  Widget _buildButtons(BuildContext context) {

    return buildThreeButtonRow(context,
        ElevatedButton(
            onPressed: () async {

              _onPickConfirm(_currentPick!, int.parse(_quantityController.text));
            },
            child: Text(CWMSLocalizations.of(context)!.confirm)
        ),
        _buildPickErrorButtons(context),
        badge.Badge(
            showBadge: true,
            badgeStyle: badge.BadgeStyle(
              padding: EdgeInsets.all(8),
              badgeColor: Colors.deepPurple,
            ),
            badgeContent: Text(
              inventoryOnRF.length.toString(),
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            child:
            SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: inventoryOnRF.length == 0 ? null : _startDeposit,
                  child: Text(CWMSLocalizations.of(context)!.depositInventory),
                )
            ),

        )
      );


  }

  void _processPickError(String pickErrorOption) {
    printLongLogMessage("start to process pick error ${pickErrorOption}");

    if (pickErrorOption == CWMSLocalizations.of(context)!.skip) {
      _skipCurrentPick();
    }
    else if (pickErrorOption == CWMSLocalizations.of(context)!.cancelPickAndReallocate) {
      cancelPickAndReallocate();
    }

  }

  void _enterOnLocationController(int tryTime) async {

    // if the location is empty, then ask the user to input the
    // right location
    if (_sourceLocationController.text.isEmpty) {
      await showBlockedErrorDialog(context,
          CWMSLocalizations.of(context)!.missingField(CWMSLocalizations.of(context)!.location));
      _sourceLocationControllerFocusNode.requestFocus();
      return;
    }
    printLongLogMessage("_enterOnLocationController: Start to validate source location, tryTime = $tryTime");
    if (tryTime <= 0) {
      // do nothing as we run out of try time
      return;
    }
    printLongLogMessage("_enterOnLocationController / _sourceLocationControllerFocusNode.hasFocus:   ${_sourceLocationControllerFocusNode.hasFocus}");
    if (_sourceLocationControllerFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnLocationController(tryTime - 1));

      return;

    }

    bool locationValid = await _validateSourceLocation();
    if (!locationValid) {
      // validation fail, leave the user in the location control
      // erorr message will be displayed in the _validateSourceLocation function
      // await showBlockedErrorDialog(context, "location " + _sourceLocationController.text + " is invalid");
      _sourceLocationFocusNode.requestFocus();
      return;
    }

    // when the user confirmed the location , we know that the user arrives at the location
    RFService.changeCurrentRFLocation(_currentPick!.sourceLocationId!).then((value) => printLongLogMessage("RF location changed"));
    printLongLogMessage("Move to the next focus node");
    if (_currentPick?.confirmLpnFlag == true) {
      _lpnControllerFocusNode.requestFocus();
    }
    else {
      _quantityFocusNode.requestFocus();
    }

  }

  void _enterOnLPNController(int tryTime) async {

    // if the location is empty, then ask the user to input the
    // right location
    if (_lpnController.text.isEmpty) {
      showErrorDialog(context,
          CWMSLocalizations.of(context)!.missingField(CWMSLocalizations.of(context)!.lpn));
      _lpnControllerFocusNode.requestFocus();
      return;
    }
    printLongLogMessage("_enterOnLPNController: Start to validate source location, tryTime = $tryTime");
    if (tryTime <= 0) {
      // do nothing as we run out of try time
      return;
    }
    printLongLogMessage("_enterOnLPNController / _lpnControllerFocusNode.hasFocus:   ${_lpnControllerFocusNode.hasFocus}");
    if (_lpnControllerFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnLPNController(tryTime - 1));

      return;

    }

    showLoading(context);
    int pickableQuantity = await validateLPNByQuantity(_lpnController.text);

    Navigator.of(context).pop();
    if (pickableQuantity > 0) {
      // lpn is valid, go to next control
      _quantityController.text = pickableQuantity.toString();
      _quantityFocusNode.requestFocus();

    }
    else {
      await showBlockedErrorDialog(context, "lpn " + _lpnController.text + " is not pickable");
      _lpnControllerFocusNode.requestFocus();
      return;
    }

  }

  void _enterOnQuantityController(int tryTime) async {

    // if the location is empty, then ask the user to input the
    // right location
    if (_quantityController.text.isEmpty) {
      showErrorDialog(context,
          CWMSLocalizations.of(context)!.missingField(CWMSLocalizations.of(context)!.quantity));
      _quantityControllerFocusNode.requestFocus();
      return;
    }
    printLongLogMessage("_enterOnQuantityController: Start to validate quantity, tryTime = $tryTime");
    if (tryTime <= 0) {
      // do nothing as we run out of try time
      return;
    }
    printLongLogMessage("_enterOnQuantityController / _quantityControllerFocusNode.hasFocus:   ${_quantityControllerFocusNode.hasFocus}");
    if (_quantityControllerFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnQuantityController(tryTime - 1));

      return;

    }


    _onPickConfirm(_currentPick!, int.parse(_quantityController.text));

  }

  Future<int> validateLPNByQuantity(String lpn) async{
    List<Inventory> inventories = [];
    try {
      inventories = await InventoryService.findInventory(
          lpn: lpn,
          locationName: _currentPick?.sourceLocation?.name ?? ""
      );
    }
    on WebAPICallException catch(ex) {
      return 0;

    }

    printLongLogMessage("validateLPNByQuantity, lpn: ${lpn}\n found ${inventories.length} inventory record");
    if (inventories.isEmpty) {
      return 0;
    }
    // over pick is not allowed so only return the pickable quantity
    setState(() {
      _lpnQuantity = inventories.map((inventory) => inventory.quantity).reduce((a, b) => a! + b!) ?? 0;
    });
    int openPickQuanity = _currentPick!.batchPickQuantity! > _currentPick!.quantity! - _currentPick!.pickedQuantity! ?
        _currentPick!.batchPickQuantity! : _currentPick!.quantity! - _currentPick!.pickedQuantity!;

    printLongLogMessage("validateLPNByQuantity: _currentPick.batchPickQuantity = ${_currentPick!.batchPickQuantity}");
    printLongLogMessage("validateLPNByQuantity: _currentPick.quantity = ${_currentPick!.quantity}");
    printLongLogMessage("validateLPNByQuantity: _currentPick.pickedQuantity = ${_currentPick!.pickedQuantity}");
    printLongLogMessage("validateLPNByQuantity: openPickQuanity = ${openPickQuanity}");
    printLongLogMessage("validateLPNByQuantity: _lpnQuantity = ${_lpnQuantity}");

    return _lpnQuantity > openPickQuanity ? openPickQuanity : _lpnQuantity;
  }

  void _onPickConfirm(Pick pick, int confirmedQuantity) async {

    // save the result into a local variable as the confirmed quantity
    // will need to be returned.
    // the confirmedQuantity will be split into multiple picks in case of
    // batch pick
    int totalConfirmedQuantity = confirmedQuantity;
    // add the current pick to the top of the batched pick and
    // then loop through each batched pick and process accordingly
    if (pick.batchedPicks == null || pick.batchedPicks.length == 0) {
      pick.batchedPicks = [pick];
    }

    print("pick.batchedPicks.size: ${pick.batchedPicks.length}");
    int totalOpenQuantity =
        pick.batchedPicks.map((e) => (e.quantity! - e!.pickedQuantity!) > 0 ? e.quantity! - e!.pickedQuantity! : 0)
            .reduce((a, b) => a + b);

    if (confirmedQuantity > totalOpenQuantity) {
      showErrorDialog(context,
        CWMSLocalizations.of(context)!.overPickNotAllowed);
      return;
    }

    // sort the picks so that in case of batch pick,
    // if we can find a perfect match between the quantity and one pick, we will
    // complete the pick first
    pick.batchedPicks.sort((pickA, pickB)   {
      // if the second pick's quantity is perfect match, then sort the second
      // pick first, otherwise we will keep the same sequence
      if (pickB.quantity! - pickB!.pickedQuantity! == confirmedQuantity) {
        return 1;
      }
      return -1;
    });

    // save the confirmed pick id and its confirmed quantity
    // as a list and returned to the previous page so the previous page
    // (can be wave pick / order pick / list pick / etc) can handle the
    // result in the local cache
    Map<int, int> confirmedPickResultMap = new Map();

    showLoading(context);
    Iterator<Pick> pickIterator = pick.batchedPicks.iterator;
    Pick currentConfirmedPick;
    int currentConfirmedPickConfirmedQuantity;
    while (confirmedQuantity > 0 && pickIterator.moveNext()) {
      // confirm each pick in the batch until we consume the whole quantity
      currentConfirmedPick = pickIterator.current;

      if (currentConfirmedPick.pickedQuantity! >= currentConfirmedPick!.quantity!) {
        // skip the pick if it is already confirmed
        continue;
      }
      currentConfirmedPickConfirmedQuantity = confirmedQuantity > (currentConfirmedPick.quantity! - currentConfirmedPick!.pickedQuantity!) ?
          currentConfirmedPick.quantity! - currentConfirmedPick!.pickedQuantity! : confirmedQuantity;
      printLongLogMessage("start to confirm pick ${currentConfirmedPick.number} with quantity ${currentConfirmedPickConfirmedQuantity}");

      try {
        if (currentConfirmedPick.confirmLpnFlag == true && _lpnController.text.isNotEmpty) {
          printLongLogMessage(
              "We will confirm the pick with LPN ${_lpnController.text}");
          await PickService.confirmPick(
              currentConfirmedPick, currentConfirmedPickConfirmedQuantity, lpn: _lpnController.text,
              destinationLpn: _destinationLPN!);
        }
        else {
          printLongLogMessage("We will NOT confirm the pick with specify the LPN");
          await PickService.confirmPick(
              currentConfirmedPick, currentConfirmedPickConfirmedQuantity,
              destinationLpn: _destinationLPN!);
        }
        confirmedQuantity = confirmedQuantity - currentConfirmedPickConfirmedQuantity;

        confirmedPickResultMap[currentConfirmedPick.id!] =  currentConfirmedPickConfirmedQuantity;
      }
      on WebAPICallException catch(ex) {
        Navigator.of(context).pop();
        showErrorDialog(context, ex.errMsg());
        return;
      }

    }

    print("pick confirmed with total quantity $totalConfirmedQuantity");

    Navigator.of(context).pop();
    showToast("pick confirmed");

    // change the RF's current location to the current location as we know the user is already
    // in the location
    RFService.changeCurrentRFLocation(pick.sourceLocationId!).then((value) => printLongLogMessage("current RF's location is changed to ${pick.sourceLocationId}"));

    var pickResult = PickResult.fromJson(
        {'result': true, 'confirmedQuantity': totalConfirmedQuantity});
    pickResult.confirmedPickResult = confirmedPickResultMap;
    // refresh the pick on the RF
    // _reloadInventoryOnRF();


    Navigator.pop(context, pickResult);
  }

  void _reloadInventoryOnRF() {

    InventoryService.getInventoryOnCurrentRF()
        .then((value) {
      setState(() {
        inventoryOnRF = value;
      });
    });

  }


  Future<void> cancelPickAndReallocate() async {
    printLongLogMessage("start to cancel and reallocate current pick");
    showLoading(context);

    Set<int> pickIds = new Set();
    if (_currentPick!.batchedPicks != null && _currentPick!.batchedPicks.length > 0) {
      pickIds = {..._currentPick!.batchedPicks.map((pick) => pick.id!)};
    }
    else {
      pickIds.add(_currentPick!.id!);
    }
    // we will save the newly generated picks
    // so that we can add it back to the list
    // in case the user is picking by order /wave / list
    List<Pick> newPicks = [];
    try {

      newPicks = await PickService.cancelPicks(pickIds.join(","));
    }
    on WebAPICallException catch(ex) {
        Navigator.of(context).pop();
        await showBlockedErrorDialog(context, ex.errMsg());
        return;
    }

    printLongLogMessage("after cancelled the original pick ${pickIds}, we get ${newPicks.length} new picks");
    newPicks.forEach((newPick) {
      printLongLogMessage("# new pick: ${newPick.number}, source location : ${newPick.sourceLocation?.name}, quantity: ${newPick.quantity}");
    });

    Navigator.of(context).pop();

    // once cancelled, we will return to the previous page
    // with result = true but confirmed quantity 0
    var pickResult = PickResult.fromJson(
        {'result': true, 'confirmedQuantity': 0});

    pickResult.cancelledPicks = pickIds;
    pickResult.reallocatedPicks = newPicks;

    Navigator.pop(context, pickResult);

  }

  void _skipCurrentPick() {
    _currentPick?.skipCount = _currentPick!.skipCount! + 1;
    var pickResult = PickResult.fromJson(
        {'result': true, 'confirmedQuantity': 0});

    Navigator.pop(context, pickResult);

  }

  void _setupPickableInventoryItemPackageType(Pick pick) {
    // get all the inventory from the pick's source location
    int pickableQuantity = max(0, pick.quantity! - pick.pickedQuantity!);
    printLongLogMessage("start to get pickable inventory item package type for pick ${pick.number} with pickable quantity: ${pickableQuantity}");
    if (pickableQuantity > 0) {
      InventoryService.findPickableInventory(
          pick!.item!.id!,
          pick!.inventoryStatus!.id!,
          color: pick.color ?? "",
          productSize: pick.productSize ?? "",
          style:  pick.style ?? "",
          locationId: pick.sourceLocationId).then((inventoryInLocation){
         // for the pickable inventory , let's get the biggest possible
        // item unit of measure for each item package type(if mixed)
        // if the biggest item unit of measures from different item package types
        // matches with name and quantity, then we will show it.
            Map<int, ItemPackageType> itemPackageTypeMap = new Map();
            inventoryInLocation.forEach((inventory) => itemPackageTypeMap.putIfAbsent(
                inventory!.itemPackageType!.id!, () => inventory!.itemPackageType!));
            printLongLogMessage(">> itemPackageTypeMap.isEmpty : ${itemPackageTypeMap.isEmpty} , itemPackageTypeMap.length  : ${itemPackageTypeMap.length}");
            if (itemPackageTypeMap.isEmpty || itemPackageTypeMap.length > 1) {
              _pickableInventoryItemPackageType = null;
            }
            else {
              // there's only one item package type in the map
              _pickableInventoryItemPackageType = itemPackageTypeMap.values.toList().first;
              printLongLogMessage("_pickableInventoryItemPackageType is setup to ${_pickableInventoryItemPackageType?.name}");


            }
            setState(() {
              _pickableInventoryItemPackageType;
            });
      });
    }

  }

  String _getPickQuantityIndicator(int quantity) {
    if (_pickableInventoryItemPackageType == null || quantity == 0) {
      return "";
    }

    // save the quantity of each unit of measure  so we can
    // calculate how many of each unit of measure needed for the pick
    Map<int, ItemUnitOfMeasure> itemUnitOfMeasureMap = new Map();
    _pickableInventoryItemPackageType?.itemUnitOfMeasures.forEach((itemUnitOfMeasure) =>
        itemUnitOfMeasureMap.putIfAbsent(itemUnitOfMeasure.quantity!, () => itemUnitOfMeasure)
    );
    List<int> itemUnitOfMeasureQuantityList = itemUnitOfMeasureMap.keys.toList()..sort((a, b) => b.compareTo(a));

    String pickByUnitOfMeasureIndicator = "";
    itemUnitOfMeasureQuantityList.forEach((itemUnitOfMeasureQuantity) {
      if (quantity > 0 && itemUnitOfMeasureMap[itemUnitOfMeasureQuantity]!.quantity! <= quantity) {
        // continue if we can pick at this item unit of measure
        int pickQuantityAtUnitOfMeasure = (quantity ~/ itemUnitOfMeasureMap[itemUnitOfMeasureQuantity]!.quantity!);

        pickByUnitOfMeasureIndicator += pickQuantityAtUnitOfMeasure.toString() + " " +
            itemUnitOfMeasureMap[itemUnitOfMeasureQuantity]!.unitOfMeasure!.name! + ", ";
        quantity = quantity % itemUnitOfMeasureMap[itemUnitOfMeasureQuantity]!.quantity!;
      }
    });
    pickByUnitOfMeasureIndicator = pickByUnitOfMeasureIndicator.trim();
    if (pickByUnitOfMeasureIndicator.endsWith(",")) {
      pickByUnitOfMeasureIndicator = pickByUnitOfMeasureIndicator.substring(0, pickByUnitOfMeasureIndicator.length - 1);
    }

    return " (" + pickByUnitOfMeasureIndicator + ")";
  }

  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the pick on the RF
    _reloadInventoryOnRF();
  }

  setupControllers(Pick pick) {

    if(pick.confirmItemFlag == false) {
      _itemController.text = pick.item?.name ?? "";
    }
    printLongLogMessage("pick.confirmLocationFlag: ${pick.confirmLocationFlag}");
    printLongLogMessage("pick.confirmLocationCodeFlag: ${pick.confirmLocationCodeFlag}");
    if (pick.confirmLocationFlag == false &&
        pick.confirmLocationCodeFlag == false) {
      _sourceLocationController.text = pick.sourceLocation?.name ?? "";
    }
    if (pick.quantity! > pick!.pickedQuantity!) {

      _quantityController.text = (pick.quantity! - pick!.pickedQuantity!).toString();
    }
    else {
      _quantityController.text = "0";
    }
  }

  _startItemBarcodeScanner()  async {
    /**
     *
        String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
        print("barcode scanned: $barcodeScanRes");
        _sourceLocationController.text = barcodeScanRes;
     * */

  }
  _startLocationBarcodeScanner() async {
    /**
     *
        String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
        print("barcode scanned: $barcodeScanRes");
        _itemController.text = barcodeScanRes;
     * */

  }

  Future<bool> _validateSourceLocation() async {
    // validate the source location
    if (_sourceLocationController.text.isEmpty) {
      return true;
    }
    showLoading(context);
    WarehouseLocation warehouseLocation;
    try {
      if (_currentPick?.confirmLocationCodeFlag == true) {
        // ok, the pick is required to verify by location code, make sure
        // the user in put a location code
        warehouseLocation =
        await WarehouseLocationService.getWarehouseLocationByCode(
            _sourceLocationController.text
        );
      }
      else {
        warehouseLocation =
        await WarehouseLocationService.getWarehouseLocationByName(
            _sourceLocationController.text
        );
      }
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      await showBlockedErrorDialog(context, ex.errMsg());
      return false;

    }

    Navigator.of(context).pop();
    if (warehouseLocation == null) {
      await showBlockedErrorDialog(context, "can't find location by input value ${_sourceLocationController.text}");
      return false;
    }
    else if (warehouseLocation.id != _currentPick?.sourceLocationId) {
      await showBlockedErrorDialog(context, "Location ${_sourceLocationController.text} is not the right location for pick");
      return false;

    }
    return true;
  }


}