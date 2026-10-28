import 'package:cwms_mobile/shared/scanning/scan_app_bar.dart';
import 'package:cwms_mobile/shared/scanning/scan_feedback.dart';
import 'package:cwms_mobile/i18n/spanish_ui.dart';import 'package:cwms_mobile/shared/adaptive_layout.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/material.dart';
import '../../shared/services/barcode_service.dart';
import '../../shared/models/barcode.dart';
import '../services/inbound_qc_service.dart';

// Page to allow the user scan in an LPN and start the put away process
// The LPN can be in receiving stage / storage location / etc
// with or without any pre-assigned destination
class InboundQCPage extends StatefulWidget {
  InboundQCPage({super.key, this.inventoryLoader, this.requestLoader});

  final Future<List<Inventory>> Function(String lpn)? inventoryLoader;
  final Future<InboundQCRequests> Function(Inventory inventory)? requestLoader;

  @override
  State<StatefulWidget> createState() => _InboundQCPageState();
}

class _InboundQCPageState extends State<InboundQCPage> {
  // allow user to scan in LPN
  TextEditingController _lpnController = new TextEditingController();

  String _itemName = "";
  String _itemDescription = "";
  String _lpn = "";
  bool _readyForQCResult = false;
  Inventory? _inventoryForQC;
  bool _busy = false;
  String? _qcMessage;

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

    _lpnFocusNode.addListener(() {
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
        _onLPNScanned();
      }
    });

    _lpnController.clear();
    _lpnFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _lpnController.dispose();
    _lpnFocusNode.dispose();
    _startQCButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScanAppBar(title:  Text(uiText(context,"Inbound QC"))),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: TabletContent(
            child: AdaptiveSections(
              header: _buildQCHeader(context),
              primary: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLPNScanner(context),
                    if (_busy) const LinearProgressIndicator(),
                    if (_qcMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(uiText(context,_qcMessage!),
                            key: const Key('inbound-qc-message')),
                      ),
                    const SizedBox(height: 12),
                    _buildButtons(context)
                  ]),
              secondary: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInventoryCard(context),
                    const SizedBox(height: 16),
                    _buildQCResultButtons(context)
                  ]),
            ),
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
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined,
              color: Color(0xFF9FC5FF), size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  [
                Text(uiText(context,"Inbound quality check"),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(uiText(context,"Scan an LPN to begin inspection"),
                    style: TextStyle(color: Color(0xB8FFFFFF), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLPNScanner(BuildContext context) {
    return TextFormField(
      controller: _lpnController,
      focusNode: _lpnFocusNode,
      autofocus: true,
      readOnly: _busy,
      onFieldSubmitted: (_) => _onLPNScanned(),
      decoration: InputDecoration(
        labelText: CWMSLocalizations.of(context).lpn,
        hintText: uiText(context,"Scan or enter LPN"),
        prefixIcon: const Icon(Icons.qr_code_scanner),
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: .45),
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
      onPressed: _busy ? null : onPressed,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _infoRow("LPN", _lpn),
          _infoRow("Item", _itemName),
          _infoRow("Description", _itemDescription),
        ],
      ),
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
          onPressed: _readyForQCResult && !_busy ? _onStartQC : null,
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

  Future<void> _onStartQC() async {
    final inventory = _inventoryForQC;
    if (_busy || inventory == null || !_readyForQCResult) return;
    setState(() {
      _busy = true;
      _qcMessage = null;
    });
    try {
      final result = await (widget.requestLoader?.call(inventory) ??
          InboundQCService.loadRequests(inventory));
      if (!mounted) return;
      final requests = result.requests
          .where((request) => request.qcInspectionRequestItems.any((item) =>
              item.qcInspectionRequestItemOptions
                  .any((option) => option.qcRuleItem?.enabled == true)))
          .toList();
      if (requests.isEmpty) {
        setState(() {
          _qcMessage = result.requests.isEmpty
              ? 'No pending inspection was found for this LPN. Check its QC history or ask an administrator to review the task.'
              : 'This QC task has no enabled inspection checks. Ask an administrator to check the QC rule configuration.';
        });
        return;
      }
      if (result.recoveredLegacy) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title:  Text(uiText(context, "Unfinished QC task")),
            content:  Text(
                uiText(context,
                "This legacy task has a PASS summary, but all checkpoints are pending and no inspection time is recorded. Complete the inspection before submitting.")),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child:  Text(uiText(context, "OK")),
              )
            ],
          ),
        );
        if (!mounted) return;
      }
      for (final request in requests) {
        await Navigator.of(context)
            .pushNamed('qc_inspection', arguments: request);
        if (!mounted) return;
      }
      _onClear();
    } on WebAPICallException catch (ex) {
      if (mounted) showErrorDialog(context, ex.errMsg());
    } catch (_) {
      if (mounted)
        showErrorDialog(context,
            'Could not load the QC inspection. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onLPNScanned() async {
    return ScanFeedback.run(() async {

    if (_busy) return;
    var lpn = _lpnController.text.trim();
    if (lpn.isEmpty) return;
    final Barcode barcode = BarcodeService.parseBarcode(lpn);
    if (barcode.is_2d == true) {
      lpn = BarcodeService.getLPN(barcode).trim();
      if (lpn.isEmpty) {
        showErrorDialog(context, "Can't get LPN from the barcode");
        return;
      }
    }
    setState(() {
      _busy = true;
      _inventoryForQC = null;
      _readyForQCResult = false;
      _itemName = _itemDescription = _lpn = '';
      _qcMessage = null;
    });
    try {
      final inventoryList = await (widget.inventoryLoader?.call(lpn) ??
          InventoryService.findInventory(lpn: lpn));
      if (!mounted) return;
      if (inventoryList.isEmpty) {
        setState(() => _qcMessage = 'No inventory found for LPN $lpn.');
        return;
      }
      final selected = inventoryList.length == 1
          ? inventoryList.first
          : await _showInventoryDialog(inventoryList);
      if (!mounted || selected == null) return;
      setupDisplay(selected);
    } on WebAPICallException catch (ex) {
      if (mounted) showErrorDialog(context, ex.errMsg());
    } catch (_) {
      if (mounted)
        showErrorDialog(context,
            'Could not load this LPN. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  
    });
  }

  void setupDisplay(Inventory inventory) {
    setState(() {
      _inventoryForQC = inventory;
      _itemName = inventory.item?.name ?? '';
      _itemDescription = inventory.item?.description ?? '';
      _lpn = inventory.lpn ?? '';
      _readyForQCResult = inventory.inboundQCRequired == true;
      _qcMessage = _readyForQCResult
          ? null
          : 'This LPN is not awaiting inbound QC. Review its QC history if an inspection was already completed.';
      _lpnController.clear();
    });
  }

  void _onClear() {
    setState(() {
      _itemName = _itemDescription = _lpn = '';
      _readyForQCResult = false;
      _inventoryForQC = null;
      _qcMessage = null;
      _lpnController.clear();
    });
    _lpnFocusNode.requestFocus();
  }

  Future<Inventory?> _showInventoryDialog(List<Inventory> inventories) {
    int selectedIndex = 0;
    return showDialog<Inventory>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title:  Text(uiText(context, "Select inventory for QC")),
          content: SizedBox(
            width: 420,
            height: 300,
            child: ListView.builder(
              itemCount: inventories.length,
              itemBuilder: (context, index) {
                final inventory = inventories[index];
                return ListTile(
                  selected: selectedIndex == index,
                  leading: Icon(selectedIndex == index
                      ? Icons.check_circle
                      : Icons.check_circle_outline),
                  title: Text(inventory.item?.name ?? inventory.lpn ?? ''),
                  subtitle: Text(
                      uiTemplate(context, "{0} · Qty {1}",
                      [inventory.lpn ?? "",inventory.quantity ?? 0])),
                  onTap: () => setDialogState(() => selectedIndex = index),
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(CWMSLocalizations.of(context).cancel)),
            TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(inventories[selectedIndex]),
                child: Text(CWMSLocalizations.of(context).confirm)),
          ],
        ),
      ),
    );
  }
}
