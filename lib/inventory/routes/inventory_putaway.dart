import 'package:cwms_mobile/shared/scanning/scan_app_bar.dart';
import 'package:cwms_mobile/i18n/spanish_ui.dart';
import '../services/putaway_sync_queue.dart';
import '../services/putaway_sync_gateway.dart';
import 'dart:async';

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:flutter/material.dart';

import '../../shared/services/barcode_service.dart';
import '../../shared/models/barcode.dart';

// Page to allow the user scan in an LPN and start the put away process
// The LPN can be in receiving stage / storage location / etc
// with or without any pre-assigned destination
class InventoryPutawayPage extends StatefulWidget {
  InventoryPutawayPage({Key? key, this.queueLoader}) : super(key: key);

  final Future<PutawaySyncQueue> Function()? queueLoader;

  @override
  State<StatefulWidget> createState() => _InventoryPutawayPageState();
}

class _InventoryPutawayPageState extends State<InventoryPutawayPage>
    with WidgetsBindingObserver {
  // allow user to scan in LPN
  TextEditingController _lpnController = new TextEditingController();

  int _inventoryCount = 0;

  FocusNode lpnFocusNode = FocusNode();

  List<InventoryDepositRequest> _inventoryDepositRequests = [];
  PutawaySyncQueue? _queue;
  String? _queueError;
  final Set<String> _savingLpns = {};

  Future<void> _initializeQueue() async {
    try {
      final queue = await (widget.queueLoader?.call() ??
          PutawaySyncGateway.currentQueue());
      if (!mounted) return;
      _queue = queue;
      queue.addListener(_queueChanged);
      _queueChanged();
      unawaited(queue.kick());
    } catch (error) {
      if (mounted)
        setState(() {
          _queueError = 'Unable to open saved scans. $error';
        });
    }
  }

  void _queueChanged() {
    if (!mounted || _queue == null) return;
    setState(() {
      _inventoryDepositRequests = _queue!.entries.map((entry) {
        return InventoryDepositRequest()
          ..lpn = entry.lpn
          ..quantity = entry.quantity
          ..itemName = entry.itemName.isEmpty ? '—' : entry.itemName
          ..requestInProcess = entry.state == 'pending' ||
              entry.state == 'syncing' ||
              entry.state == 'saving'
          ..requestResult = entry.state == 'completed'
          ..result = entry.message;
      }).toList();
    });
    _inventoryCount = _queue!.serverInventoryCount;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final queue = _queue;
      if (queue != null) unawaited(queue.kick());
    }
  }

  static const _navy = Color(0xFF142D4E);
  static const _blue = Color(0xFF2864DC);
  static const _muted = Color(0xFF718096);
  static const _border = Color(0xFFE1E7EF);

  Widget _connectionStatus() {
    final state = _queue?.connection ?? 'checking';
    final pending = _queue?.pendingCount ?? 0;
    final label = _queueError ??
        ({
              'online': uiTemplate(
                  context, '{0} ready to deposit', [_inventoryCount]),
              'offline': uiText(context, 'Waiting for server — scans saved'),
              'login': uiText(context, 'Sign in again to resume saved scans'),
              'error':
                  uiText(context, 'Unable to synchronize — scans retained'),
              'checking': uiText(context, 'Checking server connection…'),
            }[state] ??
            uiText(context, 'Checking server connection…'));
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: _navy, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(uiTemplate(context, '{0} pending', [pending]),
            style: TextStyle(
                color: pending > 0 ? const Color(0xFFA56613) : _muted,
                fontSize: 12)),
      ])),
      if (state == 'login')
        TextButton(
            onPressed: () => Navigator.of(context).pushNamed('login_page'),
            child: Text(uiText(context, 'Sign in'))),
      if (_queue != null)
        IconButton(
            tooltip: uiText(context, 'Sync'),
            onPressed: () => unawaited(_queue!.kick()),
            icon: const Icon(Icons.refresh_rounded, color: _muted, size: 22)),
    ]);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeQueue();

    lpnFocusNode.addListener(() {
      print("lpnFocusNode.hasFocus: ${lpnFocusNode.hasFocus}");
      if (!lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
        // if we tab out, then add the LPN to the list
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
        _onAddingLPN();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      appBar: ScanAppBar(
          title: Text(uiText(context, 'Putaway')),
          backgroundColor: const Color(0xFFF3F5F9),
          foregroundColor: _navy,
          elevation: 0,
          scrolledUnderElevation: 0),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
          child: Center(
              child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(
                      child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _border)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _connectionStatus(),
                          const SizedBox(height: 14),
                          _buildLPNScanner(context),
                          const SizedBox(height: 14),
                          _buildButtons(context),
                        ]),
                  ))),
              SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 12),
                  sliver: SliverToBoxAdapter(
                      child: Row(children: [
                    Expanded(
                        child: Text(uiText(context, 'Scanned LPNs'),
                            style: const TextStyle(
                                color: _navy,
                                fontSize: 16,
                                fontWeight: FontWeight.w700))),
                    Text('${_inventoryDepositRequests.length}',
                        style: const TextStyle(color: _muted, fontSize: 13)),
                  ]))),
              if (_inventoryDepositRequests.isEmpty)
                SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: SliverToBoxAdapter(
                        child: Column(children: [
                      const Icon(Icons.qr_code_scanner_rounded,
                          size: 38, color: Color(0xFFA8B7C9)),
                      const SizedBox(height: 12),
                      Text(uiText(context, 'Scan an LPN to get started'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _muted, fontSize: 14)),
                    ]))),
              SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildInventoryDepositRequestListTile(
                                  context, index)),
                          childCount: _inventoryDepositRequests.length))),
            ]),
      ))),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildLPNScanner(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
          child: TextFormField(
        controller: _lpnController,
        onFieldSubmitted: (_) => _onAddingLPN(),
        focusNode: lpnFocusNode,
        autofocus: true,
        style: const TextStyle(fontSize: 15, color: _navy),
        decoration: InputDecoration(
          labelText: CWMSLocalizations.of(context).lpn,
          hintText: uiText(context, 'Scan or enter LPN'),
          hintStyle: const TextStyle(fontSize: 14, color: _muted),
          floatingLabelStyle: const TextStyle(color: _blue),
          filled: true,
          fillColor: const Color(0xFFF7F9FC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _blue, width: 1.5)),
          suffixIcon: IconButton(
              tooltip: uiText(context, 'Clear'),
              onPressed: _clearLPN,
              icon: const Icon(Icons.close, size: 19, color: _muted)),
        ),
      )),
      const SizedBox(width: 8),
      SizedBox(
          height: 56,
          child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: _queue == null ? null : _onAddingLPN,
              child: Text(CWMSLocalizations.of(context).add,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)))),
    ]);
  }

  void _clearLPN() {
    _lpnController.clear();
    lpnFocusNode.requestFocus();
  }

  Widget _buildButtons(BuildContext context) {
    Widget label(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(text,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('$_inventoryCount',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]));
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
          child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: _navy,
                  side: const BorderSide(color: _border),
                  shape: shape,
                  padding: const EdgeInsets.symmetric(horizontal: 4)),
              onPressed: _inventoryCount == 0 ? null : _startDeposit,
              child: label(CWMSLocalizations.of(context).depositInventory))),
      const SizedBox(width: 10),
      Expanded(
          child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  shape: shape,
                  padding: const EdgeInsets.symmetric(horizontal: 4)),
              onPressed: _inventoryCount == 0 ? null : _startBatchDeposit,
              child:
                  label(CWMSLocalizations.of(context).batchDepositInventory))),
    ]);
  }

  void _onAddingLPN() async {
    final input = _lpnController.text.trim();
    final barcode = BarcodeService.parseBarcode(input);
    final lpn =
        (barcode.is_2d == true ? BarcodeService.getLPN(barcode) : input).trim();
    if (lpn.isEmpty || _savingLpns.contains(lpn)) return;
    final queue = _queue;
    if (queue == null) {
      showErrorDialog(
          context, _queueError ?? 'Please wait for saved scans to load.');
      return;
    }
    _savingLpns.add(lpn);
    try {
      await queue.add(lpn);
      if (!mounted) return;
      if (_lpnController.text.trim() == input ||
          _lpnController.text.trim() == lpn) _lpnController.clear();
      lpnFocusNode.requestFocus();
      showToast('LPN saved for synchronization');
      unawaited(queue.kick());
    } catch (error) {
      if (mounted)
        showErrorDialog(context, 'Could not save this scan. Please try again.');
    } finally {
      _savingLpns.remove(lpn);
    }
  }

  // call the deposit form to deposit the inventory on the RF
  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_deposit");
    final queue = _queue;
    if (queue != null) {
      await queue.clearCompleted();
      unawaited(queue.kick());
    }
  }

  // call the batch deposit form to batch deposit the inventory on the RF
  Future<void> _startBatchDeposit() async {
    await Navigator.of(context).pushNamed("inventory_batch_deposit");
    final queue = _queue;
    if (queue != null) {
      await queue.clearCompleted();
      unawaited(queue.kick());
    }
  }

  Widget _buildInventoryDepositRequestListTile(
      BuildContext context, int index) {
    final request = _inventoryDepositRequests[index];
    final pending = request.requestInProcess == true;
    final completed = request.requestResult == true;
    final color = completed
        ? const Color(0xFF16866C)
        : pending
            ? const Color(0xFFA56613)
            : const Color(0xFFCB3B43);
    final tint = completed
        ? const Color(0xFFEAF7F1)
        : pending
            ? const Color(0xFFFFF5E5)
            : const Color(0xFFFFECEE);
    final status = completed
        ? 'Synchronized'
        : pending
            ? 'Pending confirmation'
            : 'Failed';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: completed ? _border : color.withValues(alpha: .25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: tint, borderRadius: BorderRadius.circular(10)),
              child: Icon(
                  completed
                      ? Icons.check
                      : pending
                          ? Icons.refresh_rounded
                          : Icons.error_outline,
                  color: color,
                  size: 21)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(request.lpn ?? '—',
                    style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(uiText(context, status),
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ])),
          if (request.quantity != null)
            Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${request.quantity}',
                          style: const TextStyle(
                              color: _navy,
                              fontSize: 19,
                              fontWeight: FontWeight.w700)),
                      Text(uiText(context, 'Qty'),
                          style: const TextStyle(color: _muted, fontSize: 11)),
                    ])),
        ]),
        if (request.itemName != null && request.itemName != '—')
          Padding(
              padding: const EdgeInsets.only(left: 44, top: 10),
              child: Text(request.itemName!,
                  style:
                      const TextStyle(color: Color(0xFF4B5E73), fontSize: 14))),
        if (pending || !completed)
          Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: tint, borderRadius: BorderRadius.circular(10)),
              child: Text(
                  uiText(
                      context,
                      pending
                          ? 'Pending confirmation — scan saved'
                          : request.result ?? ''),
                  style: TextStyle(color: color, fontSize: 13, height: 1.4))),
        if (!pending && !completed)
          Wrap(alignment: WrapAlignment.end, spacing: 8, children: [
            if (_queue?.canRemoveFailed(request.lpn ?? '') == true)
              TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: _muted,
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                icon: const Icon(Icons.delete_outline, size: 17),
                label: Text(uiText(context, 'Remove'),
                    style: const TextStyle(fontSize: 13)),
                onPressed: () async {
                  try {
                    await _queue?.removeFailed(request.lpn ?? '');
                  } catch (_) {
                    if (mounted)
                      showErrorDialog(context,
                          'Could not remove saved scan. Please try again.');
                  }
                },
              ),
            TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                icon: const Icon(Icons.refresh_rounded, size: 17),
                onPressed: () async {
                  final queue = _queue;
                  if (queue == null) return;
                  try {
                    await queue.add(request.lpn ?? '');
                    unawaited(queue.kick());
                  } catch (_) {
                    if (mounted)
                      showErrorDialog(
                          context, 'Could not save retry. Please try again.');
                  }
                },
                label: Text(uiText(context, 'Retry this LPN'),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600))),
          ]),
      ]),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _queue?.removeListener(_queueChanged);
    _lpnController.dispose();
    lpnFocusNode.dispose();
    super.dispose();
  }
}

// Putaway layout: full-width cards and inline action counts.

// Failed scans without movement history can be removed locally.
