import 'package:badges/badges.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_batch.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_request_action.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/inventory/services/cycle_count_batch.dart';
import 'package:cwms_mobile/inventory/services/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/widgets/count_batch_list_item.dart';
import 'package:cwms_mobile/inventory/widgets/inventory_deposit_request_item.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

// Page to allow the user scan in an LPN and start the put away process
// The LPN can be in receiving stage / storage location / etc
// with or without any pre-assigned destination
class InventoryQCPage extends StatefulWidget{

  InventoryQCPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _InventoryQCPageState();

}

class _InventoryQCPageState extends State<InventoryQCPage> {

  // allow user to scan in LPN
  TextEditingController _lpnController = new TextEditingController();

  String _itemName;
  String _itemDescription;
  String _lpn;
  bool _readyForQCResult = false;
  Inventory _inventoryForQC;
  int _selectedInventoryIndex = 0;


  FocusNode _lpnFocusNode = FocusNode();
  FocusNode _startQCButtonFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _itemName = "";
    _itemDescription = "";
    _lpn =  "";
    _readyForQCResult = false;
    _inventoryForQC = null;

    _lpnFocusNode.addListener(() {
      print("lpnFocusNode.hasFocus: ${_lpnFocusNode.hasFocus}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        _onLPNScanned();

      }
    });

    _lpnController.clear();
    _lpnFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text("CWMS - Inventory QC")),
      body:
        Padding(padding: EdgeInsets.all(10),
          child:
            Column(
              children: [
                _buildLPNScanner(context),
                _buildButtons(context),
                buildTwoSectionInformationRow(CWMSLocalizations.of(context).lpn, _lpn),
                buildTwoSectionInformationRow(CWMSLocalizations.of(context).item, _itemName),
                buildTwoSectionInformationRow(CWMSLocalizations.of(context).item, _itemDescription),
                _buildQCResultButtons(context),
              ],
        ),

      ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildLPNScanner(BuildContext context) {
    return TextFormField(
        controller: _lpnController,
        focusNode: _lpnFocusNode,
        autofocus: true,
        decoration: InputDecoration(
          labelText: CWMSLocalizations.of(context).lpn,
        ),);
  }



  Widget _buildButtons(BuildContext context) {

    return
      // confirm input and clear input
      buildTwoButtonRow(context,
        ElevatedButton(
            onPressed: _onLPNScanned,
            child: Text(CWMSLocalizations.of(context).confirm)
        ),
        ElevatedButton(
            onPressed: _onClear,
            child: Text(CWMSLocalizations.of(context).clear)
        ),

      ) ;
  }


  Widget _buildQCResultButtons(BuildContext context) {

    return
      // confirm input and clear input
      buildSingleButtonRow(context,
        ElevatedButton(
            focusNode: _startQCButtonFocusNode,
            onPressed:
            _readyForQCResult ? _onStartQC : null,
            child: Text(CWMSLocalizations.of(context).startQC)
        ),
      ) ;
  }


  _onStartQC() async {
    // get the qc inspection request from the qc sample and
    // flow to the QC inspection page

    showLoading(context);
    try {
      List<QCInspectionRequest> qcInspectionRequests =
          await InventoryService.getPendingQCInspectionRequest(_inventoryForQC);

      printLongLogMessage("find ${qcInspectionRequests.length} qc request");
      Navigator.of(context).pop();
      if (qcInspectionRequests.isEmpty) {

        showWarningDialog(context, CWMSLocalizations.of(context).inventoryNotQCRequired);
      }
      else {

        int qcInspectionRequestItemsCount = 0;
        for(final qcInspectionRequest in qcInspectionRequests){
          if (qcInspectionRequest.qcInspectionRequestItems.isNotEmpty) {
            await Navigator.of(context).pushNamed("qc_inspection", arguments: qcInspectionRequest);
            qcInspectionRequestItemsCount += qcInspectionRequest.qcInspectionRequestItems.length;
          }
        }
        _onClear();
        if (qcInspectionRequestItemsCount == 0) {

          showWarningDialog(context, CWMSLocalizations.of(context).inventoryNotQCRequired);
        }

      }

    }
    on WebAPICallException catch(ex) {

      printLongLogMessage("error while starting qc for work order");

      Navigator.of(context).pop();
      showErrorDialog(context, ex.errMsg());
      return;

    }

  }

  _onLPNScanned() async {

    String lpn = _lpnController.text;
    if (lpn.isNotEmpty) {
      showLoading(context);
      try {
        List<Inventory> inventoryList = await InventoryService.findInventory(
            lpn: lpn);

        printLongLogMessage("get ${inventoryList.length} inventory by lpn $lpn");
        printLongLogMessage("hide the loading prompt");
        Navigator.of(context).pop();
        // TO-DO, we will support only one inventory record for now
        if (inventoryList.length == 1) {
          // ok, we find only one
          _inventoryForQC = inventoryList.first;
          setupDisplay(_inventoryForQC);
        }
        else if (inventoryList.length > 1) {
          // now we only allow qc by inventory, prompt dialog to let the user
          // choose only one inventory
          _showInventoryDialog(inventoryList);
          if (_inventoryForQC != null) {
            setupDisplay(_inventoryForQC);
          }
        }

      }
      on WebAPICallException catch (ex) {
        Navigator.of(context).pop();
        showErrorDialog(context, ex.errMsg());
        return;
      }
    }

  }


  setupDisplay(Inventory inventory) {


    setState(() {


      _itemName = inventory.item.name;
      _itemDescription = inventory.item.description;
      _lpn = inventory.lpn;

      // check if the inventory needs qc
      if (!inventory.inboundQCRequired) {
        showWarningDialog(context,  CWMSLocalizations.of(context).inventoryNotQCRequired);
        _readyForQCResult = false;
      }
      else {

        _readyForQCResult = true;
      }

      _lpnController.clear();
    });
  }

  _onClear() {

    setState(() {

      _itemName = "";
      _itemDescription = "";
      _lpn = "";
      _readyForQCResult = false;
      _inventoryForQC = null;

      _lpnController.clear();
      _lpnFocusNode.requestFocus();
    });
  }


  // prompt a dialog for user to choose valid orders
  Future<void> _showInventoryDialog(List<Inventory> inventoryList) async {

    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        var child = Column(
          children: <Widget>[
            Row(
              children: [
                FlatButton(
                  child: Text(CWMSLocalizations
                      .of(context)
                      .cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                FlatButton(
                  child: Text(CWMSLocalizations
                      .of(context)
                      .confirm),
                  onPressed: () {
                    _confirmInvenotrySelection(inventoryList);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            _buildInventoryList(context, inventoryList)
          ],
        );
        //使用AlertDialog会报错
        //return AlertDialog(content: child);
        return Dialog(child: child);
      },
    );
  }

  Widget _buildInventoryList(BuildContext context,
      List<Inventory> inventoryList) {
    return
      Expanded(
        child: ListView.builder(
            itemCount: inventoryList.length,
            itemBuilder: (BuildContext context, int index) {

              return
                Ink(
                  color: _selectedInventoryIndex == index ? Colors.lightGreen : Colors.grey,
                  child:
                    ListTile(
                      dense: true,
                      onTap: () {
                        setState(() {
                          _selectedInventoryIndex = index;
                        });
                      },
                      title: Text(
                        inventoryList[index].lpn ,
                        style: TextStyle(
                          height: 1.15,
                          color: Colors.blueGrey[700],
                          fontSize: 17,
                        ),
                      ),
                      subtitle: Text(inventoryList[index].item.description),
                    )
                );

            }),
      );
  }

  void _confirmInvenotrySelection(List<Inventory> inventoryList) {
    setState(() {

      _inventoryForQC = inventoryList[_selectedInventoryIndex];
    });
  }
}