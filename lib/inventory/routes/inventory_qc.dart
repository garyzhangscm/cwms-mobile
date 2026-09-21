import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/material.dart';
import '../../shared/services/barcode_service.dart';
import '../../shared/models/barcode.dart';

// Page to allow the user scan in an LPN and start the put away process
// The LPN can be in receiving stage / storage location / etc
// with or without any pre-assigned destination
class InventoryQCPage extends StatefulWidget {
  InventoryQCPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _InventoryQCPageState();
}

class _InventoryQCPageState extends State<InventoryQCPage> {
  // allow user to scan in LPN
  TextEditingController _lpnController = new TextEditingController();

  String? _itemName;
  String? _itemDescription;
  String? _lpn;
  bool _readyForQCResult = false;
  Inventory? _inventoryForQC;
  int _selectedInventoryIndex = 0;
  List<QCInspectionRequest> qcInspectionRequests = [];

  FocusNode _lpnFocusNode = FocusNode();
  FocusNode _startQCButtonFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _itemName = "";
    _itemDescription = "";
    _lpn = "";
    _readyForQCResult = false;
    _inventoryForQC = null;
    qcInspectionRequests = [];

    _lpnFocusNode.addListener(() {
      print("lpnFocusNode.hasFocus: ${_lpnFocusNode.hasFocus}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
        // allow the user to input barcode

        Barcode barcode = BarcodeService.parseBarcode(_lpnController.text);
        if (barcode.is_2d == true) {
          // for 2d barcode, let's get the result and set the LPN back to the text
          String lpn = BarcodeService.getLPN(barcode);
          printLongLogMessage("get lpn from lpn?: ${lpn}");
          if (lpn == "") {
            showErrorDialog(context, "can't get LPN from the barcode");
            return;
          } else {
            _lpnController.text = lpn;
          }
        }

        _onLPNScanned();
      }
    });

    _lpnController.clear();
    _lpnFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Claytech One - Inventory QC")),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildQCHeader(context),
              const SizedBox(height: 16),
              _buildLPNScanner(context),
              const SizedBox(height: 10),
              _buildButtons(context),
              const SizedBox(height: 16),
              _buildInventoryCard(context),
              const SizedBox(height: 16),
              _buildQCResultButtons(context),
            ],
          ),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildQCHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF172F50),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(children: [
        const Icon(Icons.verified_user_outlined,
            color: Color(0xFF9FC5FF), size: 34),
        const SizedBox(width: 14),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
              Text("Inventory quality check",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text("Scan an LPN to review QC status",
                  style: TextStyle(color: Color(0xB8FFFFFF), fontSize: 14)),
            ])),
      ]),
    );
  }

  Widget _buildLPNScanner(BuildContext context) {
    return TextFormField(
      controller: _lpnController,
      focusNode: _lpnFocusNode,
      autofocus: true,
      decoration: InputDecoration(
        labelText: CWMSLocalizations.of(context).lpn,
        hintText: "Scan or enter LPN",
        prefixIcon: const Icon(Icons.qr_code_scanner),
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(.45),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: Theme.of(context).primaryColor, width: 1.5)),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return
        // confirm input and clear input
        buildTwoButtonRow(
      context,
      _secondaryButton(context, Icons.search,
          CWMSLocalizations.of(context).confirm, _onLPNScanned),
      _secondaryButton(context, Icons.refresh,
          CWMSLocalizations.of(context).clear, _onClear),
    );
  }

  Widget _secondaryButton(BuildContext context, IconData icon, String label,
      VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        foregroundColor: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).colorScheme.surface,
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context) {
    final lastQC = _inventoryForQC?.lastQCTime?.toLocal().toString() ?? "";
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(children: [
        _infoRow("LPN", _lpn ?? ""),
        _infoRow("Item", _itemName ?? ""),
        _infoRow("Description", _itemDescription ?? ""),
        _infoRow("Last QC", lastQC),
        _infoRow(
            "QC required",
            _readyForQCResult
                ? CWMSLocalizations.of(context).yes
                : CWMSLocalizations.of(context).no),
      ]),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w600))),
        Expanded(
            child: Text(value.isEmpty ? "—" : value,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(0xFF172F50),
                    fontSize: 16,
                    fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _buildQCResultButtons(BuildContext context) {
    return
        // confirm input and clear input
        buildSingleButtonRow(
      context,
      ElevatedButton(
          focusNode: _startQCButtonFocusNode,
          onPressed: _readyForQCResult ? _onStartQC : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            elevation: 0,
            foregroundColor: Colors.white,
            backgroundColor: Theme.of(context).primaryColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Text(CWMSLocalizations.of(context).startQC)),
    );
  }

  _onStartQC() async {
    // get the qc inspection request from the qc sample and
    // flow to the QC inspection page

    showLoading(context);
    try {
      printLongLogMessage("find ${qcInspectionRequests.length} qc request");
      Navigator.of(context).pop();
      if (qcInspectionRequests.isEmpty) {
        showWarningDialog(
            context, CWMSLocalizations.of(context).inventoryNotQCRequired);
      } else {
        int qcInspectionRequestItemsCount = 0;
        printLongLogMessage("start to load every qcInspectionRequest");

        for (final qcInspectionRequest in qcInspectionRequests) {
          printLongLogMessage(
              "qcInspectionRequest.number ${qcInspectionRequest.number}");
          printLongLogMessage(
              "qcInspectionRequest.qcInspectionRequestItems.length ${qcInspectionRequest.qcInspectionRequestItems.length}");

          if (qcInspectionRequest.qcInspectionRequestItems.isNotEmpty) {
            printLongLogMessage("start actual qc");
            await Navigator.of(context)
                .pushNamed("qc_inspection", arguments: qcInspectionRequest);
            qcInspectionRequestItemsCount +=
                qcInspectionRequest.qcInspectionRequestItems.length;
          }
        }
        printLongLogMessage("clear everything");
        _onClear();
        printLongLogMessage(
            "qcInspectionRequestItemsCount: ${qcInspectionRequestItemsCount}");
        if (qcInspectionRequestItemsCount == 0) {
          showWarningDialog(
              context, CWMSLocalizations.of(context).inventoryNotQCRequired);
        }
      }
    } on WebAPICallException catch (ex) {
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
      qcInspectionRequests = [];
      _readyForQCResult = false;

      try {
        List<Inventory> inventoryList =
            await InventoryService.findInventory(lpn: lpn);

        printLongLogMessage(
            "get ${inventoryList.length} inventory by lpn $lpn");

        if (inventoryList.length == 0) {
          Navigator.of(context).pop();
          showErrorDialog(context, "can't find LPN by " + lpn);
          return;
        }

        // TO-DO, we will support only one inventory record for now
        if (inventoryList.length == 1) {
          // ok, we find only one
          _inventoryForQC = inventoryList.first;
          await setupDisplay(_inventoryForQC!);
        } else if (inventoryList.length > 1) {
          // now we only allow qc by inventory, prompt dialog to let the user
          // choose only one inventory
          _showInventoryDialog(inventoryList);
          if (_inventoryForQC != null) {
            await setupDisplay(_inventoryForQC!);
          }
        }

        Navigator.of(context).pop();
      } on WebAPICallException {
        Navigator.of(context).pop();
        //await showBlockedErrorDialog(context, ex.errMsg());
      }
    }
  }

  setupDisplay(Inventory inventory) async {
    if (_inventoryForQC?.lastQCTime == null) {
      qcInspectionRequests =
          await InventoryService.getManualQCInspectionRequest(inventory);
    }

    setState(() {
      _itemName = inventory.item!.name;
      _itemDescription = inventory.item!.description;
      _lpn = inventory.lpn;

      if (qcInspectionRequests.isEmpty) {
        _readyForQCResult = false;
      } else {
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
                ElevatedButton(
                  child: Text(CWMSLocalizations.of(context).cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text(CWMSLocalizations.of(context).confirm),
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

  Widget _buildInventoryList(
      BuildContext context, List<Inventory> inventoryList) {
    return Expanded(
      child: ListView.builder(
          itemCount: inventoryList.length,
          itemBuilder: (BuildContext context, int index) {
            return Ink(
                color: _selectedInventoryIndex == index
                    ? Colors.lightGreen
                    : Colors.grey,
                child: ListTile(
                  dense: true,
                  onTap: () {
                    setState(() {
                      _selectedInventoryIndex = index;
                    });
                  },
                  title: Text(
                    inventoryList[index].lpn ?? "",
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    ),
                  ),
                  subtitle: Text(inventoryList[index].item?.description ?? ""),
                ));
          }),
    );
  }

  void _confirmInvenotrySelection(List<Inventory> inventoryList) {
    setState(() {
      _inventoryForQC = inventoryList[_selectedInventoryIndex];
    });
  }
}
