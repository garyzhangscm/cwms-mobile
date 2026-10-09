import '../services/putaway_sync_queue.dart';
import '../services/putaway_sync_gateway.dart';
import 'dart:async';

import 'package:badges/badges.dart' as badge;
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
  GlobalKey _formKey = new GlobalKey<FormState>();

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

  Widget _connectionStatus() {
    final state = _queue?.connection ?? 'checking';
    final label = _queueError ??
        ({
              'online': 'Server connected',
              'offline': 'Waiting for server — scans saved',
              'login': 'Sign in again to resume saved scans',
              'error': 'Unable to synchronize — scans retained',
              'checking': 'Checking server connection…'
            }[state] ??
            'Checking server connection…');
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state == 'online' ? Colors.green : Colors.orange)),
          const SizedBox(width: 8),
          Expanded(
              child: Text('$label · ${_queue?.pendingCount ?? 0} pending',
                  style: const TextStyle(fontSize: 12))),
          if (state == 'login')
            TextButton(
                onPressed: () => Navigator.of(context).pushNamed('login_page'),
                child: const Text('Sign in')),
          if (_queue != null)
            TextButton(
                child: const Text('Sync'),
                onPressed: () {
                  unawaited(_queue!.kick());
                }),
        ]));
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
      appBar: AppBar(title: Text("Claytech One - Inventory Putaway")),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction, //开启自动校验
          child: CustomScrollView(slivers: [
            SliverToBoxAdapter(
                child: Column(children: [
              _connectionStatus(),
              _buildLPNScanner(context),
              _buildButtons(context),
            ])),
            SliverList(
                delegate: SliverChildBuilderDelegate(
                    (context, index) => Column(children: [
                          _buildInventoryDepositRequestListTile(context, index),
                          const Divider(height: 8),
                        ]),
                    childCount: _inventoryDepositRequests.length)),
          ]),
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }

  Widget _buildLPNScanner(BuildContext context) {
    return TextFormField(
        controller: _lpnController,
        onFieldSubmitted: (_) => _onAddingLPN(),
        focusNode: lpnFocusNode,
        autofocus: true,
        decoration: InputDecoration(
          labelText: CWMSLocalizations.of(context).lpn,
          hintText: "please input LPN",
          suffixIcon: IconButton(
            onPressed: () => _clearLPN(),
            icon: Icon(Icons.close),
          ),
        ),
        // 校验用户名（不能为空）
        validator: (v) {
          return (v ?? '').trim().isNotEmpty
              ? null
              : CWMSLocalizations.of(context)
                  .missingField(CWMSLocalizations.of(context).lpn);
        });
  }

  void _clearLPN() {
    _lpnController.text = "";
    lpnFocusNode.requestFocus();
  }

  Widget _buildButtons(BuildContext context) {
    return buildThreeButtonRow(
        context,
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Theme.of(context).primaryColor,
          ),
          onPressed: _onAddingLPN,
          child: Text(CWMSLocalizations.of(context).add),
        ),
        badge.Badge(
          showBadge: true,
          badgeStyle: badge.BadgeStyle(
            padding: EdgeInsets.all(8),
            badgeColor: Colors.deepPurple,
          ),
          badgeContent: Text(
            _inventoryCount.toString(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              onPressed: _inventoryCount == 0 ? null : _startDeposit,
              child: Text(CWMSLocalizations.of(context).depositInventory),
            ),
          ),
        ),
        badge.Badge(
          showBadge: true,
          badgeStyle: badge.BadgeStyle(
            padding: EdgeInsets.all(8),
            badgeColor: Colors.deepPurple,
          ),
          badgeContent: Text(
            _inventoryCount.toString(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              onPressed: _inventoryCount == 0 ? null : _startBatchDeposit,
              child: Text(CWMSLocalizations.of(context).batchDepositInventory),
            ),
          ),
        ));
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
    final message = pending
        ? 'Saved — waiting for synchronization'
        : completed
            ? 'Synchronized'
            : request.result ?? '';
    return Container(
        color: completed
            ? Colors.lightGreen
            : pending
                ? Colors.blueGrey.shade50
                : Colors.amberAccent,
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('LPN: ${request.lpn}'),
          Text('Item: ${request.itemName ?? '—'}'),
          Text('Quantity: ${request.quantity?.toString() ?? '—'}'),
          Text(message, style: const TextStyle(fontSize: 12)),
          if (!pending && !completed)
            TextButton(
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
                child: const Text('Retry this LPN')),
        ]));
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
