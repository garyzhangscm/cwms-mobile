import 'package:badges/badges.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inbound/models/receipt.dart';
import 'package:cwms_mobile/inbound/models/receipt_line.dart';
import 'package:cwms_mobile/inbound/services/receipt.dart';
import 'package:cwms_mobile/inbound/widgets/receipt_line_list_item.dart';
import 'package:cwms_mobile/inbound/widgets/receipt_list_item.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/inventory/models/item_unit_of_measure.dart';
import 'package:cwms_mobile/inventory/models/lpn_capture_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory_status.dart';
import 'package:cwms_mobile/inventory/services/item_package_type.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/models/cwms_http_exception.dart';
import 'package:cwms_mobile/shared/services/qr_code_service.dart';
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:flutter/material.dart';
import 'package:progress_dialog/progress_dialog.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


class ReverseProductionPage extends StatefulWidget{

  ReverseProductionPage({Key key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _ReverseProductionPageState();

}

class _ReverseProductionPageState extends State<ReverseProductionPage> {


  final  _formKey = GlobalKey<FormState>();
  Inventory _inventoryForReverse;
  // information for display. When there's multiple inventory attribute
  // match with the LPN input, then we will show MULTIPLE-VALUES instead of
  // the actual value and won't allow reverse
  String _lpn;
  String _clientName;
  String _itemName;
  String _itemPackageTypeName;
  String _quantity;
  String _locationName;
  bool _allowReverse;
  String _workOrderNumber;
  bool _reverseInProgress;


  TextEditingController _lpnController = new TextEditingController();
  FocusNode _lpnFocusNode = FocusNode();

  @override
  void initState() {

    super.initState();
    _inventoryForReverse = null;
    _allowReverse = false;
    _reverseInProgress = false;


    _lpnFocusNode.addListener(() {
      print("lpnFocusNode.hasFocus: ${_lpnFocusNode.hasFocus}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
        _onLoadingLPNInformation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).reverseProduction)),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Form(
          key: _formKey,
          // autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: Column(
            children: <Widget>[
              _buildLPNController(context),
              _allowReverse ?
                  _buildReverseInventoryInformationDisplay(context) :
                  Container(),
              // _buildEmptyReverseInventoryInformationDisplay(context),
              _buildButtons(context)
            ],
          ),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }


  void _clear() {

    setState(() {

      _inventoryForReverse = null;
      _lpn = "";
      _clientName = "";
      _itemName = "";
      _itemPackageTypeName = "";
      _quantity = "";
      _locationName = "";
      _workOrderNumber = "";
      _allowReverse = false;
      _reverseInProgress = false;

    });
    _lpnController.clear();

  }
  void _onLoadingLPNInformation() async {

    if (_lpnController.text.isEmpty) {

      showErrorDialog(context, "please input the LPN number");
      return;
    }
    showLoading(context);

    List<Inventory> inventories = await InventoryService.findInventory(lpn :_lpnController.text, includeDetails: true);

    if (inventories.isEmpty) {

      Navigator.of(context).pop();
      showToast(CWMSLocalizations.of(context).noInventoryFound);
      _clear();
      return;
    }

    Set<String> clientNames = new Set();
    Set<String> itemNames = new Set();
    Set<String> itemPackageTypeNames = new Set();
    Set<String> workOrderNumbers = new Set();
    int totalQuantity = 0;
    _allowReverse = false;
    bool includeNonWorkOrderInventory = false;

    inventories.forEach((inventory) {
      clientNames.add(inventory.client == null ? "" : inventory.client.name);
      itemNames.add(inventory.item.name);
      itemPackageTypeNames.add(inventory.itemPackageType.name);
      totalQuantity += inventory.quantity;
      _locationName = inventory.location.name;
      if (inventory.workOrder == null) {
        includeNonWorkOrderInventory = true;
      }
      else {
        workOrderNumbers.add(inventory.workOrder.number);
      }
    });

    if (includeNonWorkOrderInventory) {

      showErrorDialog(context, CWMSLocalizations.of(context).reverseErrorNoWorkOrder);
      return;
    }
    if (workOrderNumbers.length >1) {

      showErrorDialog(context, CWMSLocalizations.of(context).reverseErrorMixedWorkOrder);
      return;
    }
    if (clientNames.length > 1) {
      showErrorDialog(context, CWMSLocalizations.of(context).reverseErrorMixedWithClient);
      return;
    }
    if (itemNames.length > 1) {
      showErrorDialog(context, CWMSLocalizations.of(context).reverseErrorMixedWithItem);
      return;
    }
    setState(() {
      _lpn = _lpnController.text;
      _itemName = itemNames.first;
      _clientName = clientNames.first;
      _workOrderNumber = workOrderNumbers.first;
      if (itemPackageTypeNames.length > 1) {
        _itemPackageTypeName = "MULTIPLE-VALUES";
      }
      else {
        _itemPackageTypeName = itemPackageTypeNames.first;
      }
      _quantity = totalQuantity.toString();
      _locationName;
      _allowReverse = true;

    });
    _lpnController.clear();
    Navigator.of(context).pop();
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

  Widget _buildEmptyReverseInventoryInformationDisplay(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10),
      child: IntrinsicHeight(
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(children: [
                  Container(height: 240.0),
                ]),
              ),
              // Expanded(child: Container(color: Colors.amber)),
            ]),
      ),
    );

  }

  Widget _buildReverseInventoryInformationDisplay(BuildContext context) {
    if (_reverseInProgress) {

      return SizedBox(
        height: 250,
        child:  Stack(
          alignment:Alignment.center ,
          fit: StackFit.expand, //未定位widget占满Stack整个空间
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 10),
              child: IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(children: [
                          buildTwoSectionInformationRow(CWMSLocalizations.of(context).lpn,
                              _lpn),
                          buildTwoSectionInformationRow(CWMSLocalizations.of(context).item,
                              _itemName),
                          buildTwoSectionInformationRow(CWMSLocalizations.of(context).itemPackageType,
                              _itemPackageTypeName),
                          buildTwoSectionInformationRow(CWMSLocalizations.of(context).workOrderNumber,
                              _workOrderNumber),
                          buildTwoSectionInformationRow(CWMSLocalizations.of(context).quantity, _quantity),
                          buildTwoSectionInformationRow(CWMSLocalizations.of(context).location, _locationName),
                        ]),
                      ),
                      // Expanded(child: Container(color: Colors.amber)),
                    ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 100.0, bottom: 100),
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
    else {

      return
        SizedBox(
          height: 250,
          child:
            Padding(
              padding: const EdgeInsets.only(top: 10.0, bottom: 10),
              child: IntrinsicHeight(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(children: [
                          buildTwoSectionInformationRow(CWMSLocalizations.of(context).lpn,
                              _lpn),
                          buildTwoSectionInformationRow(CWMSLocalizations.of(context).item,
                              _itemName),
                          buildTwoSectionInformationRow(CWMSLocalizations.of(context).itemPackageType,
                              _itemPackageTypeName),
                          buildTwoSectionInformationRow(CWMSLocalizations.of(context).workOrderNumber,
                              _workOrderNumber),
                          buildTwoSectionInformationRow(CWMSLocalizations.of(context).quantity, _quantity),
                          buildTwoSectionInformationRow(CWMSLocalizations.of(context).location, _locationName),
                        ]),
                      ),
                      // Expanded(child: Container(color: Colors.amber)),
                    ]),
                ),
              )
        );
    }

  }
  Widget _buildButtons(BuildContext context) {
    return buildTwoButtonRow(
      context,
      ElevatedButton(
        onPressed: _allowReverse ? _reverseProduction : null,
        child: Text(CWMSLocalizations
            .of(context).reverseProduction),
      ),
      ElevatedButton(
        onPressed: _clear,
        child: Text(CWMSLocalizations
            .of(context).clear),
      ),
    );

  }
  _reverseProduction() {
    // show in progress indicator
    setState(() {
      _reverseInProgress = true;
    });

    // start reverse the inventory



  }
}