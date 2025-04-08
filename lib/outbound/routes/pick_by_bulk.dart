
import 'dart:collection';
import 'dart:core';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/outbound/models/bulk_pick.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/outbound/models/pick_list.dart';
import 'package:cwms_mobile/outbound/models/pick_result.dart';
import 'package:cwms_mobile/outbound/services/bulk_pick.dart';
import 'package:cwms_mobile/outbound/services/order.dart';
import 'package:cwms_mobile/outbound/services/pick.dart';
import 'package:cwms_mobile/outbound/services/pick_list.dart';
import 'package:cwms_mobile/outbound/widgets/order_list_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/bottom_navigation_bar.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:badges/badges.dart' as badge;

import '../../shared/global.dart';
import '../models/pick_mode.dart';


class PickByBulkPage extends StatefulWidget{

  PickByBulkPage({Key? key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _PickByBulkPageState();

}

class _PickByBulkPageState extends State<PickByBulkPage> {

  // input batch id
  TextEditingController _bulkPickNumberController = new TextEditingController();
  FocusNode _bulkPickNumberFocusNode = FocusNode();


  BulkPick? _currentBulkPick;

  List<Inventory>  inventoryOnRF = [];

  @override
  void initState() {
    super.initState();
    inventoryOnRF = [];

    _currentBulkPick = null;

    _bulkPickNumberFocusNode.addListener(() {
      print("_bulkPickNumberFocusNode.hasFocus: ${_bulkPickNumberFocusNode.hasFocus}");
      if (!_bulkPickNumberFocusNode.hasFocus && _bulkPickNumberController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _onAddingBulkPick();

      }
    });

    _reloadInventoryOnRF();

  }

  @override
  void dispose() {
    super.dispose();
    // for any reason the user return, let's try to unacknowledge the _currentPickList
    if (_currentBulkPick != null) {
      BulkPickService.unacknowledgeBulkPick(_currentBulkPick!.id!).then(
          (bulkPick) {
              // _currentPickList= null;
      }).catchError((err) {
        // ignore any error
        printLongLogMessage("error while unacknowledge the bulk pick ${_currentBulkPick?.number}");
      });
    }

  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context)!.bulkPick)),
      resizeToAvoidBottomInset: true,
      body:
          Column(
            children: [
              _buildBulkPickNumberScanner(context),
              _buildButtons(context),
            ],
          ),
      // bottomNavigationBar: buildBottomNavigationBar(context)
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildBulkPickNumberScanner(BuildContext context) {
    return
      Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(
                  children: <Widget>[
                        TextFormField(
                        controller: _bulkPickNumberController,
                        showCursor: true,
                        autofocus: true,
                        focusNode: _bulkPickNumberFocusNode,
                        decoration: InputDecoration(
                          labelText: CWMSLocalizations.of(context)!.bulkPick,
                          hintText: "please input bulk pick number",
                          suffixIcon:
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                            mainAxisSize: MainAxisSize.min, // added line
                            children: <Widget>[
                              IconButton(
                                onPressed: () => _clear(),
                                icon: Icon(Icons.close),
                              ),
                            ],
                          ),
                        )

                    )
                  ]
              )
          );

  }

  Widget _buildButtons(BuildContext context) {

    return Column(
      children: [
        buildTwoButtonRow(context,
            ElevatedButton(
                onPressed: _currentBulkPick != null  ? _startBulkPick : null,
                child: Text(CWMSLocalizations.of(context)!.start)
            ),
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
                ),
              ),
            )
        )
      ],
    );


  }
  void _clear() {
    if (_currentBulkPick != null) {

      BulkPickService.unacknowledgeBulkPick(_currentBulkPick!.id!);
      _currentBulkPick = null;
    }
    _bulkPickNumberController.clear();
    _bulkPickNumberFocusNode.requestFocus();
  }

  void _onAddingBulkPick() async {

    _currentBulkPick = null;
    if (_bulkPickNumberController.text.isNotEmpty ) {

      showLoading(context);
      try {

        _currentBulkPick = await BulkPickService.getBulkPickByNumber(_bulkPickNumberController.text);

        if (_currentBulkPick != null) {
          // acknowledge the pick list so that no one else can work on the same list
          await BulkPickService.acknowledgeBulkPick(_currentBulkPick!.id!);
        }

        setState(() {
        });
        Navigator.of(context).pop();

        if (_currentBulkPick != null) {
          // if we are here, we know that we get the bulk pick and we are good to start
          _startBulkPick();
        }
      }
      on WebAPICallException catch(ex) {


        Navigator.of(context).pop();
        showErrorDialog(context, ex.errMsg());
        //_orderNumberFocusNode.requestFocus();
        return;

      }
    }
  }


  _startBulkPick() async {

      printLongLogMessage("start to pick for ${_currentBulkPick?.number} ");
      Map argumentMap = new HashMap();
      argumentMap['bulkPick'] = _currentBulkPick;
      argumentMap['pickMode'] = PickMode.BY_BULK;

      await Navigator.of(context).pushNamed("bulk_pick", arguments: argumentMap);

      _clear();
      // refresh the pick on the RF
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


  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the pick on the RF
    _reloadInventoryOnRF();
  }



}