
import 'dart:core';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/services/order.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart';
import 'package:flutter/services.dart';
import '../../shared/global.dart';

import '../models/order.dart';


class OrderManualPickPage extends StatefulWidget{

  OrderManualPickPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _OrderManualPickPageState();

}

class _OrderManualPickPageState extends State<OrderManualPickPage> {

  // input batch id
  TextEditingController _orderNumberController = new TextEditingController();
  FocusNode _orderNumberFocusNode = FocusNode();

  Order _currentOrder;

  bool _readyToConfirm = true;

  // flag to indicate whether we will need to
  // validate partial LPN pick. Default to false to skip
  // the validation for performance seek, temporary. We may
  // need to convert to configuration!
  bool _validatePartialLPNPick = true;
  bool _pickToShipStage = true;


  TextEditingController _lpnController = new TextEditingController();
  FocusNode _lpnFocusNode = FocusNode();

  List<Inventory>  inventoryOnRF;

  @override
  void initState() {
    super.initState();

    _validatePartialLPNPick = Global.getConfigurationAsBoolean("outboundOrderValidatePartialLPNPick");
    // _pickToShipStage = Global.getConfigurationAsBoolean("pickToShipStage");

    _currentOrder = null;
    inventoryOnRF = <Inventory>[];


    _orderNumberFocusNode.addListener(() {
      print("_orderNumberFocusNode.hasFocus: ${_orderNumberFocusNode.hasFocus}");

      if (!_orderNumberFocusNode.hasFocus && _orderNumberController.text.isNotEmpty) {
        _enterOnOrderController(10);
      }
    });


    _lpnFocusNode.addListener(() {
      print("_lpnFocusNode.hasFocus: ${_lpnFocusNode.hasFocus}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty && _readyToConfirm) {
        // if we tab out, then add the LPN to the list
        _readyToConfirm = false;   // block the 'confirm button'
        _enterOnLPNController(10);
      }
    });

    _reloadInventoryOnRF();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).manualPick)),
      resizeToAvoidBottomInset: true,
      body:
        Padding(
          padding: const EdgeInsets.all(16.0),
          child:
            Column(
              children: [

                // input controller for order number
                _buildOrderNumberInput(context),
                // build a hypelink to allow the user to click and show
                // what the user will need to pick and the remain quantity to be picked
                _currentOrder == null ? Container() : _buildPickingInformation(context),
                // whether directly pick the inventory onto production line's in stage
                // or pick the inventory onto the RF
                _currentOrder == null ? Container() : _buildPickToShipStageInput(context),
                // allow user to scan in LPN
                _currentOrder == null ? Container() : _buildLPNInput(context),
                // allow user to input LPN
                _buildButtons(context),
              ],
          ),
        ),
      // bottomNavigationBar: buildBottomNavigationBar(context)
      endDrawer: MyDrawer(),
    );
  }
  Widget _buildOrderNumberInput(BuildContext context) {
    return buildTwoSectionInputRow(
              CWMSLocalizations.of(context).orderNumber,
              TextFormField(
                  controller: _orderNumberController,
                  showCursor: true,
                  autofocus: true,
                  focusNode: _orderNumberFocusNode,
                  decoration: InputDecoration(
                    suffixIcon:
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                        mainAxisSize: MainAxisSize.min, // added line
                        children: <Widget>[
                          IconButton(
                            onPressed: () => _clearField(),
                            icon: Icon(Icons.close),
                          ),
                        ],
                      ),
                  )
              )
          );
  }


  Widget _buildPickingInformation(BuildContext context) {
    return
        // confirm the location
        Row(
          children: <Widget>[
             RichText(
              text: TextSpan(
                text: 'click to see the item to be picked',
                style: new TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                    fontSize: 15
                ),
                recognizer: new TapGestureRecognizer()
                ..onTap = () => openPickingInformationForm()
              ),
            )

        ]
      );
  }

  void openPickingInformationForm() async{

    printLongLogMessage("openPickingInformationForm");

    await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          var child = Column(
              children: <Widget>[
                ListTile(title:  Text("item list")),
                _buildPickableItemList(context)
              ],
          );
          //使用AlertDialog会报错
          //return AlertDialog(content: child);
          return Center(
              child: Dialog(child: child)
          );
        },
    );
  }

  Widget _buildPickableItemList(BuildContext context) {
    return
      Expanded(
        child: ListView.builder(
            itemCount: _currentOrder.orderLines.length,
            itemBuilder: (BuildContext context, int index) {

              return ListTile(

                title: Text(
                    CWMSLocalizations.of(context).item + ':' + _currentOrder.orderLines[index].item.name),
                subtitle: Text(
                    CWMSLocalizations.of(context).expectedQuantity + ':' + _currentOrder.orderLines[index].openQuantity.toString()),
              );
            }),
      );
  }

  _clearField() {
    _orderNumberController.text = "";
    setState(() {
      _currentOrder = null;
    });
    _orderNumberFocusNode.requestFocus();
    _readyToConfirm = true;
  }

  void _enterOnOrderController(int tryTime) async {

    // if the user input an empty work order number, then clear the page
    if (_orderNumberController.text.isEmpty) {
      _clearField();
      return;
    }
    printLongLogMessage("_enterOnOrderController: Start to get order information, tryTime = $tryTime");
    if (tryTime <= 0) {
      // do nothing as we run out of try time
      return;
    }
    printLongLogMessage("_enterOnOrderController / _orderNumberFocusNode.hasFocus:   ${_orderNumberFocusNode.hasFocus}");
    if (_orderNumberFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnOrderController(tryTime - 1));

      return;

    }

    showLoading(context);
    _currentOrder = await OrderService.getOrderByNumber(_orderNumberController.text);


    Navigator.of(context).pop();
    if (_currentOrder == null) {
      showErrorDialog(context, "Can't find order by number " + _orderNumberController.text);

    }

    if (_currentOrder.allowForManualPick != true) {

      await showBlockedErrorDialog(context, "order " + _orderNumberController.text + " is marked as not for manual pick");


      setState(()  {
        _currentOrder = null;

      });
      _orderNumberFocusNode.requestFocus();
    }
    else {

      _lpnController.text = "";
      setState(()  {
        _currentOrder;

      });
    }


  }


  Widget _buildPickToShipStageInput(BuildContext context) {
    return
      buildTwoSectionInputRow(
        CWMSLocalizations.of(context).pickToProductionLineInStage,

        Checkbox(
          value: _pickToShipStage,
          onChanged: (bool value) {
            setState(() {
              _pickToShipStage = value;
            });
          },
        ),
      );
  }

  Widget _buildLPNInput(BuildContext context) {
    return  buildTwoSectionInputRow(
      CWMSLocalizations.of(context).lpn+ ": ",
      Focus(
        child:
        SystemControllerNumberTextBox(
            type: "lpn",
            controller: _lpnController,
            readOnly: false,
            showKeyboard: false,
            focusNode: _lpnFocusNode,
            onClear: (value) {
              _lpnControllerCleared();
            },
            autofocus: true,
            validator: (v) {
              // if we only need one LPN, then make sure the user input the LPN in this form.
              // otherwise, we will flow to next LPN Capture form to let the user capture
              // more LPNs
              if (v.trim().isEmpty) {
                return CWMSLocalizations.of(context).missingField(CWMSLocalizations.of(context).lpn);
              }

              return null;
            }),
      ),
    );
  }

  void _lpnControllerCleared() {
    _lpnFocusNode.requestFocus();
  }

  void _enterOnLPNController(int tryTime) async {
    // we may come here when the user scan / press
    // enter in the LPN controller. In either case, we will need to make sure
    // the lpn doesn't have focus before we start confirm

    printLongLogMessage("_enterOnLPNController: Start to confirm work order produced inventory, tryTime = $tryTime");
    if (tryTime <= 0) {
      // do nothing as we run out of try time

      setState(() {
        // enable the confirm button
        _readyToConfirm = true;
      });
      return;
    }
    printLongLogMessage("_enterOnLPNController / lpnFocusNode.hasFocus:   ${_lpnFocusNode.hasFocus}");
    if (_lpnFocusNode.hasFocus) {
      // printLongLogMessage("lpn controller still have focus, will wait for 100 ms and try again");
      Future.delayed(const Duration(milliseconds: 100),
              () => _enterOnLPNController(tryTime - 1));

      return;

    }

    // check if we can fully pick from the LPN
    _onOrderManualPickConfirm();


  }


  Widget _buildButtons(BuildContext context) {

    return Column(
      children: [

        buildTwoButtonRow(context,
            ElevatedButton(
                onPressed: _currentOrder == null || !_readyToConfirm? null : _onConfirmButtonClick,
                child: Text(CWMSLocalizations.of(context).confirm),
            ),
            Badge(
              showBadge: true,
              padding: EdgeInsets.all(8),
              badgeColor: Colors.deepPurple,
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
                  ),
                ),
            )
        )
      ],
    );

  }

  _onConfirmButtonClick() async {
    _readyToConfirm = false;
    _onOrderManualPickConfirm();
  }
  _onOrderManualPickConfirm() async {

    // make sure the user input an valid LPN
    if (_lpnController.text.isEmpty) {
      await showBlockedErrorDialog(context, "LPN is required");
      _lpnFocusNode.requestFocus();
      _readyToConfirm = true;
      return;
    }


    //verify if we can pick full quantity from the LPN or partial quantity

    showLoading(context);
    bool continuePicking = true;
    bool continueWholeLPN = true;


    if (_validatePartialLPNPick) {
      try {
        List<Inventory> inventories = await InventoryService.findInventory(lpn: _lpnController.text);

        if (inventories.isEmpty) {

          throw new WebAPICallException("can't find inventory by LPN " + _lpnController.text);
        }

        // check the quantity we can pick from the invenotry
        int pickableQuantity = await OrderService.getPickableQuantityForManualPick(
            _currentOrder.id, _lpnController.text
        );

        printLongLogMessage("we can pick $pickableQuantity from lpn ${_lpnController.text}");

        // check the total quantity of the LPN
        int inventoryQuantity =  inventories.fold(0, (previous, current) => previous + current.quantity);

        if (pickableQuantity < inventoryQuantity) {

          // ok, we will need to inform the user that it will be a partial pick
          await showYesNoCancelDialog(context, "partial pick",
              "The LPN has quantity of $inventoryQuantity but the order only requires $pickableQuantity," +
                  " do you want to continue with a partial pick? \nYes to pick partial LPN. \nNo to pick whole LPN, \nCancel to cancel the pick",
                  () {
                // the user press Yes, continue with partial quantity
                continuePicking= true;
                continueWholeLPN = false;
              },
                  () {
                // the user press Yes, continue with partial quantity
                continuePicking= true;
                continueWholeLPN = true;
              },
                  ()  => continuePicking = false);
        }
      }
      on WebAPICallException catch(ex) {

        Navigator.of(context).pop();
        await showBlockedErrorDialog(context, ex.errMsg());
        _readyToConfirm = true;
        return;

      }

    }


    Navigator.of(context).pop();
    if (!continuePicking) {
      // the user choose not continue to pick. let's
      // return and reset the ready for confirm to true

      _readyToConfirm = true;
      return;
    }


    showLoading(context);
    try {
      List<Pick> picks = await OrderService.generateManualPick(
          _currentOrder.id, _lpnController.text,
          continueWholeLPN

      );
      printLongLogMessage("get ${picks.length} by generating manual pick for the order ${_currentOrder.number}");

      // let's finish each pick one by one
      for(var i = 0; i < picks.length; i++){

        printLongLogMessage("start to confirm pick # $i, quantity ${picks[i].quantity - picks[i].pickedQuantity}");
        if (_pickToShipStage) {

          WarehouseLocation shipStageLocation = await WarehouseLocationService.getWarehouseLocationById(
              picks[i].destinationLocationId);

          PickService.confirmPick(
                picks[i], (picks[i].quantity - picks[i].pickedQuantity), lpn: _lpnController.text,
                nextLocationName: shipStageLocation.name).then((value) {

                  showToast("pick confirmed");
            } , onError: (e) {
              showErrorToast("pick confirmed error, please contact your supervisor or manager");
              showErrorDialog(context, "pick confirmed error, please contact your supervisor or manager");
            }
          );
        }
        else {

          // Async confirmed the pick to increase the performance
          // await PickService.confirmPick(
          PickService.confirmPick(
              picks[i], (picks[i].quantity - picks[i].pickedQuantity), lpn: _lpnController.text).then((value) {

            showToast("pick confirmed");
          } , onError: (e) {
            showErrorToast("pick confirmed error, please contact your supervisor or manager");
            showErrorDialog(context, "pick confirmed error, please contact your supervisor or manager");
          });
        }
      }
    }
    on WebAPICallException catch(ex) {

      Navigator.of(context).pop();
      await showBlockedErrorDialog(context, ex.errMsg());
      _readyToConfirm = true;
      _lpnFocusNode.requestFocus();
      return;

    }
    printLongLogMessage("All manual picks are done");

    Navigator.of(context).pop();
    _readyToConfirm = true;
    showToast("lpn ${_lpnController.text} is picked");
    _refreshScreenAfterPickConfirm();

  }
  _refreshScreenAfterPickConfirm(){
    // after we sucessfully pick the LPN, clear the LPN field
    _lpnController.text = "";
    _lpnFocusNode.requestFocus();
    _readyToConfirm = true;
    _reloadInventoryOnRF();
  }

  void _reloadInventoryOnRF() {

    InventoryService.getInventoryOnCurrentRF()
        .then((value) {
      setState(() {
        inventoryOnRF = value;
      });
    });

  }

  // call the deposit form to deposit the inventory on the RF
  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the inventory on the RF
    _reloadInventoryOnRF();
  }



}