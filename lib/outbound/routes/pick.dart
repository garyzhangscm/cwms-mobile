import 'dart:async';
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

  Pick currentPick;
  String destinationLPN;
  String workNumber;

  // all picks assigned to current pick. We will allow the user to choose next pick
  // if current pick is not suitable
  List<Pick> assignedPicks;

  PickPage({Key? key,
        required this.currentPick,
        destinationLPN,
        workNumber,
        assignedPicks}) :
        this.destinationLPN = destinationLPN ?? "",
        this.workNumber = workNumber ?? "",
        this.assignedPicks = assignedPicks ?? [],
        super(key: key);



  @override
  State<StatefulWidget> createState() => _PickPageState();

}

class _PickPageState extends State<PickPage> {


  // input batch id
  TextEditingController _itemController = new TextEditingController();
  TextEditingController _sourceLocationController = new TextEditingController();
  TextEditingController _quantityController = new TextEditingController();
  TextEditingController _lpnController = new TextEditingController();
  int _selectedNextPickIndex = -1;

  FocusNode _lpnFocusNode = FocusNode();
  FocusNode _lpnControllerFocusNode = FocusNode();
  FocusNode _sourceLocationFocusNode = FocusNode();
  FocusNode _sourceLocationControllerFocusNode = FocusNode();
  FocusNode _quantityFocusNode = FocusNode();
  FocusNode _quantityControllerFocusNode = FocusNode();

  Timer? _timer;  // timer to refresh inventory on RF every 2 second

  int _lpnQuantity = 0;

  // pickable inveotory's item package type. Used to show how to pick
  // if the source location is mixed of item package types, then
  // show (Mixed Item Package Type)
  // if the source location is not mixed of item package type,
  // then show (X case, Y package, Z Each)
  ItemPackageType? _pickableInventoryItemPackageType;

  List<Inventory>  inventoryOnRF = [];


  List<String> _pickErrorOptions = [];
  String _selectedPickErrorOption = "";


  @override
  void dispose() {
    super.dispose();
    // remove any timer so we won't need to load the next work again after
    // the user return from this page
    _timer?.cancel();


  }

  @override
  void initState() {
    super.initState();
    printLongLogMessage("initState / start to setup setupPickableInventoryItemPackageType");
    printLongLogMessage("initState / widget.currentPick == null ? ${widget.currentPick}");
    setupPickableInventoryItemPackageType(widget.currentPick);
    _selectedPickErrorOption = "";

    _itemController.clear();
    _sourceLocationController.clear();
    _quantityController.clear();
    _lpnController.clear();
    _lpnQuantity = 0;
    _selectedNextPickIndex = -1;
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
              buildTwoSectionInformationRow("Work Number:", widget.workNumber),
              buildTwoSectionInformationRow("Location:", widget.currentPick.sourceLocation?.name ?? ""),
              _buildLocationInput(context),
              _buildLPNInput(context),
              buildTwoSectionInformationRowWithWidget(
                  CWMSLocalizations.of(context).item,
                  _buildItemDisplayWidget(context, widget.currentPick)),
              // buildTwoSectionInformationRow("Item Number:", _currentPick.item.name),
              // add the batch pick quantity only if the quantity to be picked is more than the single pick
              // _currentPick.batchPickQuantity > _currentPick.quantity - _currentPick.pickedQuantity ?
              (widget.currentPick.batchPickQuantity ?? 0) > 0 ?
                  buildTwoSectionInformationRow("Batch Pick Quantity:",
                      widget.currentPick.batchPickQuantity.toString() +
                          (_pickableInventoryItemPackageType == null ? "" :
                              _getPickQuantityIndicator(widget.currentPick.batchPickQuantity!)))
                  :
                  buildTwoSectionInformationRow("Pick Quantity:",
                      widget.currentPick.quantity.toString() +
                      (_pickableInventoryItemPackageType == null ? "" :
                      _getPickQuantityIndicator(widget.currentPick.quantity!))) ,
              buildTwoSectionInformationRow("Picked Quantity:",
                  widget.currentPick.pickedQuantity.toString() +
                      (_pickableInventoryItemPackageType == null ? "" :
                      _getPickQuantityIndicator(widget.currentPick.pickedQuantity!))),
              (widget.currentPick.batchPickQuantity ?? 0) > 0 ?
                  buildTwoSectionInformationRow("Remaining Quantity:",
                      widget.currentPick.batchPickQuantity!.toString() +
                          (_pickableInventoryItemPackageType == null ? "" :
                          _getPickQuantityIndicator(widget.currentPick.batchPickQuantity!)))
                  :
                  buildTwoSectionInformationRow("Remaining Quantity:",
                      (widget.currentPick.quantity! - widget.currentPick.pickedQuantity!).toString() +
                          (_pickableInventoryItemPackageType == null ? "" :
                          _getPickQuantityIndicator(widget.currentPick.quantity! - widget.currentPick.pickedQuantity!))),
              buildTwoSectionInformationRow("Inventory Quantity:",
                      _lpnQuantity.toString() +
                      (_pickableInventoryItemPackageType == null ? "" :
                      _getPickQuantityIndicator(_lpnQuantity))),
              widget.destinationLPN.isEmpty? Container() : buildTwoSectionInformationRow("Destination LPN:", widget.destinationLPN),
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
                            CWMSLocalizations.of(context).item + ":",
                            pick.item?.name ?? ""),
                        buildTwoSectionInformationRow(
                            CWMSLocalizations.of(context).item + ":",
                            pick.item?.description ?? ""),
                        buildTwoSectionInformationRow(
                            CWMSLocalizations.of(context).color + ":",
                            pick.color ?? ""),
                        buildTwoSectionInformationRow(
                            CWMSLocalizations.of(context).style + ":",
                            pick.style ?? ""),
                        buildTwoSectionInformationRow(
                            CWMSLocalizations.of(context).productSize + ":",
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
        CWMSLocalizations.of(context).location,
      widget.currentPick.confirmLocationFlag == true || widget.currentPick.confirmLocationCodeFlag == true ?
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
            child: Text(widget.currentPick.sourceLocation?.name ?? "", textAlign: TextAlign.left ),
          ),
    );
  }


  Widget _buildLPNInput(BuildContext context) {
    return buildTwoSectionInputRow(
      CWMSLocalizations.of(context).lpn,
        widget.currentPick.confirmLpnFlag == true ?
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
        CWMSLocalizations.of(context).quantity,
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

    _pickErrorOptions = (widget.assignedPicks.length > 0) ?
      [
        CWMSLocalizations.of(context).error,
        CWMSLocalizations.of(context).skip,
        CWMSLocalizations.of(context).cancelPickAndReallocate,
        CWMSLocalizations.of(context).chooseNextPick,
      ]
      :
      [
        CWMSLocalizations.of(context).error,
        CWMSLocalizations.of(context).skip,
        CWMSLocalizations.of(context).cancelPickAndReallocate,
      ] ;

    _selectedPickErrorOption = CWMSLocalizations.of(context).error;

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
            thickness: WidgetStateProperty.all(6),
            thumbVisibility: WidgetStateProperty.all(true),
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

              _onPickConfirm(widget.currentPick, int.parse(_quantityController.text));
            },
            child: Text(CWMSLocalizations.of(context).confirm)
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
                  child: Text(CWMSLocalizations.of(context).depositInventory),
                )
            ),

        )
      );


  }

  void _processPickError(String pickErrorOption) {
    printLongLogMessage("start to process pick error ${pickErrorOption}");

    if (pickErrorOption == CWMSLocalizations.of(context).skip) {
      _skipCurrentPick();
    }
    else if (pickErrorOption == CWMSLocalizations.of(context).cancelPickAndReallocate) {
      cancelPickAndReallocate();
    }
    else if (pickErrorOption == CWMSLocalizations.of(context).chooseNextPick) {
      _openAssignedPickModel();
    }

  }

  Future<void> _openAssignedPickModel() async {
    _selectedNextPickIndex =  widget.assignedPicks.indexWhere((pick) => pick.id! == widget.currentPick.id);
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose a Pick'),
          content:
            SingleChildScrollView(
              physics: ScrollPhysics(),
              child: Column(
                children: <Widget>[
                  ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: widget.assignedPicks.length,
                      itemBuilder: (context,index){
                        return
                          Card(
                            child:
                              ListTile(
                                selected: index == _selectedNextPickIndex,
                                enabled: widget.assignedPicks[index].quantity! > widget.assignedPicks[index].pickedQuantity! &&
                                    widget.assignedPicks[index].sourceLocationId != widget.currentPick.sourceLocationId,
                                onTap: () {
                                  _selectNextPick(index);

                                  Navigator.of(context).pop();

                                },
                                // The same can be achieved using the .resolveWith() constructor.
                                // The text color will be identical to the icon color above.
                                textColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return Colors.grey;
                                  }
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.green;
                                  }
                                  return Colors.black;
                                }),
                                title: Text(
                                    "${widget.assignedPicks[index].sourceLocation?.name ?? ""} : " +
                                        "${widget.assignedPicks[index].item?.name ?? ""}"),
                                subtitle: Text("Qty: ${widget.assignedPicks[index].quantity!}," +
                                    " Remaining Qty: ${widget.assignedPicks[index].quantity! - widget.assignedPicks[index].pickedQuantity!}"),


                              )
                          );
                      })
                ],
              ),
            ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(textStyle: Theme.of(context).textTheme.labelLarge),
              child: Text(CWMSLocalizations.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _selectNextPick(int index) {

    this._selectedNextPickIndex = index;
    setState(() {
      this.widget.currentPick = widget.assignedPicks[index];
    });

    setupPickableInventoryItemPackageType(widget.currentPick);
  }


  void _enterOnLocationController(int tryTime) async {

    // if the location is empty, then ask the user to input the
    // right location
    if (_sourceLocationController.text.isEmpty) {
      await showBlockedErrorDialog(context,
          CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).location));
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
    RFService.changeCurrentRFLocation(widget.currentPick.sourceLocationId!).then((value) => printLongLogMessage("RF location changed"));
    printLongLogMessage("Move to the next focus node");
    if (widget.currentPick.confirmLpnFlag == true) {
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
          CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).lpn));
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

  Future<int> validateLPNByQuantity(String lpn) async{
    List<Inventory> inventories = [];
    try {
      inventories = await InventoryService.findInventory(
          lpn: lpn,
          locationName: widget.currentPick.sourceLocation?.name ?? ""
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
    int openPickQuanity = (widget.currentPick.batchPickQuantity ?? 0) > widget.currentPick.quantity! - widget.currentPick.pickedQuantity! ?
        (widget.currentPick.batchPickQuantity ?? 0) : widget.currentPick.quantity! - widget.currentPick.pickedQuantity!;

    printLongLogMessage("validateLPNByQuantity: _currentPick.batchPickQuantity = ${widget.currentPick.batchPickQuantity}");
    printLongLogMessage("validateLPNByQuantity: _currentPick.quantity = ${widget.currentPick.quantity}");
    printLongLogMessage("validateLPNByQuantity: _currentPick.pickedQuantity = ${widget.currentPick.pickedQuantity}");
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
    if (pick.batchedPicks.length == 0) {
      pick.batchedPicks = [pick];
    }

    print("pick.batchedPicks.size: ${pick.batchedPicks.length}");
    int totalOpenQuantity =
        pick.batchedPicks.map((e) => (e.quantity! - e.pickedQuantity!) > 0 ? e.quantity! - e.pickedQuantity! : 0)
            .reduce((a, b) => a + b);

    if (confirmedQuantity > totalOpenQuantity) {
      showErrorDialog(context,
        CWMSLocalizations.of(context).overPickNotAllowed);
      return;
    }

    // sort the picks so that in case of batch pick,
    // if we can find a perfect match between the quantity and one pick, we will
    // complete the pick first
    pick.batchedPicks.sort((pickA, pickB)   {
      // if the second pick's quantity is perfect match, then sort the second
      // pick first, otherwise we will keep the same sequence
      if (pickB.quantity! - pickB.pickedQuantity! == confirmedQuantity) {
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

      if (currentConfirmedPick.pickedQuantity! >= currentConfirmedPick.quantity!) {
        // skip the pick if it is already confirmed
        continue;
      }
      currentConfirmedPickConfirmedQuantity = confirmedQuantity > (currentConfirmedPick.quantity! - currentConfirmedPick.pickedQuantity!) ?
          currentConfirmedPick.quantity! - currentConfirmedPick.pickedQuantity! : confirmedQuantity;
      printLongLogMessage("start to confirm pick ${currentConfirmedPick.number} with quantity ${currentConfirmedPickConfirmedQuantity}");

      try {
        if (currentConfirmedPick.confirmLpnFlag == true && _lpnController.text.isNotEmpty) {
          printLongLogMessage(
              "We will confirm the pick with LPN ${_lpnController.text}");
          await PickService.confirmPick(
              currentConfirmedPick, currentConfirmedPickConfirmedQuantity, lpn: _lpnController.text,
              destinationLpn: widget.destinationLPN);
        }
        else {
          printLongLogMessage("We will NOT confirm the pick with specify the LPN");
          await PickService.confirmPick(
              currentConfirmedPick, currentConfirmedPickConfirmedQuantity,
              destinationLpn: widget.destinationLPN);
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
        {'result': true,
          'confirmedQuantity': totalConfirmedQuantity,
          'pickId': widget.currentPick.id
        });
    pickResult.confirmedPickResult = confirmedPickResultMap;
    // refresh the pick on the RF
    // _reloadInventoryOnRF();


    Navigator.pop(context, pickResult);
  }



  Future<void> cancelPickAndReallocate() async {
    printLongLogMessage("start to cancel and reallocate current pick");
    showLoading(context);

    Set<int> pickIds = new Set();
    if (widget.currentPick.batchedPicks.length > 0) {
      pickIds = {...widget.currentPick.batchedPicks.map((pick) => pick.id!)};
    }
    else {
      pickIds.add(widget.currentPick.id!);
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
    widget.currentPick.skipCount = widget.currentPick.skipCount! + 1;
    var pickResult = PickResult.fromJson(
        {'result': true, 'confirmedQuantity': 0});

    Navigator.pop(context, pickResult);

  }

  void setupPickableInventoryItemPackageType(Pick pick) {
    // get all the inventory from the pick's source location
    printLongLogMessage("setupPickableInventoryItemPackageType, pick.quantity == null ? ${pick.quantity == null}");
    printLongLogMessage("setupPickableInventoryItemPackageType, pick.pickedQuantity == null ? ${pick.pickedQuantity == null}");
    int pickableQuantity = max(0, pick.quantity! - pick.pickedQuantity!);
    printLongLogMessage("start to get pickable inventory item package type for pick ${pick.number} with pickable quantity: ${pickableQuantity}");
    if (pickableQuantity > 0) {
      InventoryService.findPickableInventory(
          pick.item!.id!,
          pick.inventoryStatus!.id!,
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
                inventory.itemPackageType!.id!, () => inventory.itemPackageType!));
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
    _timer?.cancel();
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the inventory on the RF
    // when we come back from the deposit page, we will refresh
    // 3 times as the deposit happens async so when we return from
    // the deposit page, the last deposit may not be actually done yet
    _reloadInventoryOnRF(refreshCount: 3);
  }

  void _reloadInventoryOnRF({int refreshCount = 0}) {

    InventoryService.getInventoryOnCurrentRF()
        .then((value) {
      setState(() {
        inventoryOnRF = value;

        if (refreshCount > 0) {

          _timer = Timer(new Duration(seconds: 2), () {
            this._reloadInventoryOnRF(refreshCount: refreshCount - 1);
          });
        }
        else {
          _timer?.cancel();
        }
      });
    });

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
    if (pick.quantity! > pick.pickedQuantity!) {

      _quantityController.text = (pick.quantity! - pick.pickedQuantity!).toString();
    }
    else {
      _quantityController.text = "0";
    }
  }

  Future<bool> _validateSourceLocation() async {
    // validate the source location
    if (_sourceLocationController.text.isEmpty) {
      return true;
    }
    showLoading(context);
    WarehouseLocation warehouseLocation;
    try {
      if (widget.currentPick.confirmLocationCodeFlag == true) {
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
    if (warehouseLocation.id != widget.currentPick.sourceLocationId) {
      await showBlockedErrorDialog(context, "Location ${_sourceLocationController.text} is not the right location for pick");
      return false;

    }
    return true;
  }


}