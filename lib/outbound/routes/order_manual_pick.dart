import 'dart:async';
import '../models/pick_rejection.dart';
import 'package:cwms_mobile/shared/scanning/scan_app_bar.dart';
import 'package:cwms_mobile/shared/scanning/scan_feedback.dart';
import '../models/remaining_pallet_demand.dart';
import '../widgets/remaining_pallets_card.dart';
import 'package:cwms_mobile/i18n/spanish_ui.dart';
import 'order_manual_pick_legacy.dart';
import 'package:cwms_mobile/outbound/services/preprinted_manual_pick.dart';
import 'package:cwms_mobile/outbound/widgets/manual_pick_split_dialog.dart';
import 'dart:core';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/outbound/services/order.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/widgets/system_controlled_number_textbox.dart';
import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badge;
import '../../shared/global.dart';

import '../models/order.dart';

// Luggage keeps its existing workflow until its backend supports split picks.
class OrderManualPickPage extends StatelessWidget {
  const OrderManualPickPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Global.currentFactory?.id == 'mira-loma-luggage'
          ? LegacyOrderManualPickPage()
          : _PreprintedOrderManualPickPage();
}

class _PreprintedOrderManualPickPage extends StatefulWidget {
  _PreprintedOrderManualPickPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => __PreprintedOrderManualPickPageState();
}

class __PreprintedOrderManualPickPageState
    extends State<_PreprintedOrderManualPickPage> {
  // input batch id
  TextEditingController _orderNumberController = new TextEditingController();
  FocusNode _orderNumberFocusNode = FocusNode();

  Order? _currentOrder;
  Map<int, int> _remainingByLine = {};
  bool _remainingIsCurrent = false;

  bool _readyToConfirm = true;
  bool _loadingOrder = false;
  bool _queueEnabled = false;
  bool _queueRefreshing = false;
  bool _queueOffline = false;
  bool _completionVerified = false;
  bool _statusRefreshing = false;
  int _statusRefreshTicks = 5;
  bool _viewingPallets = false;
  Map<int, int>? _pickedByItem;
  String? _quantityNotice;
  String? _recentOtherSubmitter;
  bool _queueSnapshotLoaded = false;
  String _submitter(Map<String, dynamic> row) {
    final name = row['submittedBy']?.toString().trim();
    return name == null || name.isEmpty ? 'Unknown' : name;
  }

  String _palletSubmitter(Map<String, dynamic> row) {
    final tasks = _queueTasks.where((task) =>
        task['pickId'] != null && '${task['pickId']}' == '${row['pickId']}');
    return tasks.isEmpty ? 'Unknown' : _submitter(tasks.first);
  }

  bool get _allSubmitted =>
      _queueEnabled &&
      _remainingIsCurrent &&
      _pendingManualPick == null &&
      _remainingByLine.isNotEmpty &&
      _remainingByLine.values.every((quantity) => quantity == 0);
  bool get _tasksPending => _queueTasks.any((r) => r['state'] != 'COMPLETED');
  bool get _pickingComplete =>
      _allSubmitted && !_queueOffline && !_tasksPending && _completionVerified;

  String? _retryingTask;
  List<Map<String, dynamic>> _queueTasks = [];
  Timer? _queueTimer;
  bool get _queueBlocked =>
      _queueOffline || _queueTasks.any((row) => row['state'] == 'NEEDS_REVIEW');

  Future<void> _refreshQueue() async {
    if (!_queueEnabled || _currentOrder?.id == null || _queueRefreshing) return;
    final orderId = _currentOrder!.id!;
    final generation = _orderLookupGeneration;
    _queueRefreshing = true;
    try {
      final tasks = await PreprintedManualPickService.queue(orderId);
      if (!mounted ||
          generation != _orderLookupGeneration ||
          _currentOrder?.id != orderId) return;
      final knownRequests = _queueTasks.map((r) => r['requestId']).toSet();
      final otherNewTasks = _queueSnapshotLoaded
          ? tasks
              .where((r) =>
                  !knownRequests.contains(r['requestId']) &&
                  _submitter(r) != 'Unknown' &&
                  _submitter(r).toLowerCase() !=
                      (Global.currentUser?.username ?? '').toLowerCase())
              .toList()
          : <Map<String, dynamic>>[];
      if (otherNewTasks.isNotEmpty)
        _recentOtherSubmitter = _submitter(otherNewTasks.first);
      _queueSnapshotLoaded = true;
      final previouslyCompleted = _queueTasks
          .where((row) => row['state'] == 'COMPLETED')
          .map((row) => row['requestId'])
          .toSet();
      final hasNewCompletion = tasks.any((row) =>
          row['state'] == 'COMPLETED' &&
          !previouslyCompleted.contains(row['requestId']));
      setState(() {
        _queueTasks = tasks;
        _queueOffline = false;
      });
      if (hasNewCompletion) _reloadInventoryOnRF();
      _statusRefreshTicks++;
      if (hasNewCompletion ||
          otherNewTasks.isNotEmpty ||
          _statusRefreshTicks >= 5) {
        unawaited(_refreshQueuedAvailability());
      }
    } catch (_) {
      if (mounted && generation == _orderLookupGeneration)
        setState(() => _queueOffline = true);
    } finally {
      _queueRefreshing = false;
    }
  }

  Widget _buildQueue() => Card(
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pallet processing',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Text(
                'Submitted pallets are processing. Resolve any errors below.'),
            if (_queueOffline)
              const Text(
                  'Connection lost. Checking saved tasks before accepting another scan.',
                  style: TextStyle(color: Colors.red)),
            if (_queueTasks.any((row) => row['state'] == 'NEEDS_REVIEW'))
              const Text(
                  'Resolve the task below before scanning another pallet.',
                  style: TextStyle(color: Colors.red)),
            if (_queueTasks.isEmpty)
              const Text('No submitted pallets for this order.'),
            ..._queueTasks
                .where((row) => row['state'] != 'COMPLETED')
                .map((row) {
              final completed = row['state'] == 'COMPLETED';
              final failed = row['state'] == 'NEEDS_REVIEW';
              return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                      completed
                          ? Icons.check_circle
                          : failed
                              ? Icons.error_outline
                              : Icons.schedule,
                      color: completed
                          ? Colors.green
                          : failed
                              ? Colors.red
                              : Colors.blue),
                  title: Text('${row['sourceLpn']} · ${row['quantity']}'),
                  subtitle: Text(
                      'Submitted by ${_submitter(row)}\n${completed ? 'Completed' : failed ? (row['errorMessage']?.toString() ?? 'Needs review') : 'Accepted — processing'}'),
                  trailing: failed
                      ? TextButton(
                          onPressed: _retryingTask != null
                              ? null
                              : () async {
                                  final orderId = _currentOrder!.id!;
                                  setState(() => _retryingTask =
                                      row['requestId'] as String);
                                  try {
                                    await PreprintedManualPickService
                                        .retryQueued(orderId,
                                            row['requestId'] as String);
                                    await _refreshQueue();
                                  } catch (_) {
                                    if (mounted)
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Could not retry. The saved task is retained.')));
                                  } finally {
                                    if (mounted)
                                      setState(() => _retryingTask = null);
                                  }
                                },
                          child: Text(_retryingTask == row['requestId']
                              ? 'Checking…'
                              : 'Retry saved task'))
                      : null);
            }),
          ])));

  bool _confirmingPick = false;
  Map<String, dynamic>? _pendingManualPick;
  int _orderLookupGeneration = 0;
  String? _lastAutomaticLpnAttempt;
  String _observedLpnText = "";

  // flag to indicate whether we will need to
  // validate partial LPN pick. Default to false to skip
  // the validation for performance seek, temporary. We may
  // need to convert to configuration!
  bool _pickToShipStage = true;

  TextEditingController _lpnController = new TextEditingController();
  FocusNode _lpnFocusNode = FocusNode();

  List<Inventory> inventoryOnRF = [];

  @override
  void initState() {
    super.initState();

    // Start each Manual Pick session at ship stage; staff may opt into RF.
    _pickToShipStage = true;

    _currentOrder = null;
    inventoryOnRF = <Inventory>[];

    _lpnFocusNode.addListener(_handleLpnFocusChanged);
    _lpnController.addListener(_handleLpnTextChanged);

    _reloadInventoryOnRF();
    _restorePendingPick();
    _queueTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => _refreshQueue());
  }

  Future<void> _restorePendingPick() async {
    final pending = await PreprintedManualPickService.pending();
    if (!mounted) return;
    if (pending == null) {
      final last = await PreprintedManualPickService.lastQueuedOrder();
      if (!mounted || last == null || _orderNumberController.text.isNotEmpty)
        return;
      _orderNumberController.text = last['orderNumber'] as String;
      await _enterOnOrderController(0);
      return;
    }
    setState(() {
      _pendingManualPick = pending;
      _queueEnabled = pending['queued'] == true;
      _orderNumberController.text = pending['orderNumber'] as String;
      _lpnController.text = pending['sourceLpn'] as String;
      _currentOrder = Order()
        ..id = pending['orderId'] as int
        ..number = pending['orderNumber'] as String;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ScanAppBar(title: Text(CWMSLocalizations.of(context).manualPick)),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // input controller for order number
              if (_pendingManualPick != null)
                Text(uiText(context,
                    "Pick awaiting confirmation. Press Confirm to resume. Keep both labels; do not split again.")),
              _buildOrderNumberInput(context),
              if (_quantityNotice != null)
                Card(
                    child: ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.blue),
                  title: Text(_quantityNotice!),
                  trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _quantityNotice = null)),
                )),
              // build a hypelink to allow the user to click and show
              // what the user will need to pick and the remain quantity to be picked

              // whether directly pick the inventory onto production line's in stage
              // or pick the inventory onto the RF
              _currentOrder == null
                  ? Container()
                  : _buildPickToShipStageInput(context),
              // allow user to scan in LPN
              if (_currentOrder != null && !_allSubmitted)
                _buildLPNInput(context),
              // allow user to input LPN
              _buildButtons(context),
              if (_queueEnabled &&
                  _currentOrder != null &&
                  (_tasksPending || _queueOffline))
                _buildQueue(),
              if (_allSubmitted) _buildCompletionCard(),
              if (_currentOrder != null) _buildPickedSummary(),
              if (_currentOrder != null)
                RemainingPalletsCard(
                  lines: RemainingPalletDemand.forOrder(
                      _currentOrder!, _remainingByLine),
                  updating: _confirmingPick,
                  pendingConfirmation: _pendingManualPick != null,
                  current: _remainingIsCurrent && _pendingManualPick == null,
                ),
            ],
          ),
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
            readOnly: _pendingManualPick != null || _confirmingPick,
            showCursor: true,
            autofocus: true,
            focusNode: _orderNumberFocusNode,
            textInputAction: TextInputAction.go,
            onFieldSubmitted: (_) => _enterOnOrderController(10),
            decoration: InputDecoration(
              suffixIcon: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // added line
                mainAxisSize: MainAxisSize.min, // added line
                children: <Widget>[
                  TextButton(
                    onPressed: _loadingOrder || _confirmingPick
                        ? null
                        : () => _enterOnOrderController(10),
                    child: _loadingOrder
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(CWMSLocalizations.of(context).nextStep),
                  ),
                  IconButton(
                    onPressed: _pendingManualPick != null || _confirmingPick
                        ? null
                        : () => _clearField(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            )));
  }

  Widget _buildPickingInformation(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        style: TextButton.styleFrom(
            padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
        onPressed: openPickingInformationForm,
        child: Text(uiText(context, "click to see the item to be picked"),
            softWrap: true,
            style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ),
    );
  }

  void openPickingInformationForm() async {
    printLongLogMessage("openPickingInformationForm");

    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        var child = Column(
          children: <Widget>[
            ListTile(title: Text(uiText(context, "item list"))),
            _buildPickableItemList(context)
          ],
        );
        //使用AlertDialog会报错
        //return AlertDialog(content: child);
        return Center(child: Dialog(child: child));
      },
    );
  }

  Widget _buildPickableItemList(BuildContext context) {
    return Expanded(
      child: ListView.builder(
          itemCount: _currentOrder?.orderLines.length,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              title: Text(CWMSLocalizations.of(context).item +
                  ':' +
                  (_currentOrder?.orderLines[index].item?.name ?? "")),
              subtitle: Text(CWMSLocalizations.of(context).expectedQuantity +
                  ':' +
                  (_remainingByLine[_currentOrder?.orderLines[index].id] ?? 0)
                      .toString()),
            );
          }),
    );
  }

  _clearField() {
    unawaited(PreprintedManualPickService.forgetQueuedOrder());
    _orderLookupGeneration++;
    _loadingOrder = false;
    _orderNumberController.text = "";
    setState(() {
      _currentOrder = null;
      _pickedByItem = null;
      _remainingByLine = {};
      _remainingIsCurrent = false;
      _queueTasks = [];
      _quantityNotice = null;
      _recentOtherSubmitter = null;
      _queueSnapshotLoaded = false;
      _queueEnabled = false;
      _queueOffline = false;
      _completionVerified = false;
      _statusRefreshTicks = 5;
      _lpnController.clear();
      _lastAutomaticLpnAttempt = null;
    });
    _orderNumberFocusNode.requestFocus();
    _readyToConfirm = true;
  }

  Future<void> _enterOnOrderController(int tryTime) async {
    if (_confirmingPick || _pendingManualPick != null) return;
    final number = _orderNumberController.text.trim();
    if (number.isEmpty) {
      _clearField();
      return;
    }
    if (_loadingOrder) return;
    final generation = ++_orderLookupGeneration;
    setState(() {
      _loadingOrder = true;
      _currentOrder = null;
      _pickedByItem = null;
    });
    try {
      final order = await OrderService.getOrderByNumber(number);
      final availability =
          await OrderService.getManualPickAvailability(order.id!);
      if (!mounted ||
          generation != _orderLookupGeneration ||
          _orderNumberController.text.trim() != number) return;
      if (availability.reservationRequired) {
        setState(() => _loadingOrder = false);
        await showBlockedErrorDialog(context,
            'Reserve quantity before picking this order. Open Sales Orders > Allocate, reserve the required quantity, then reload the order on your phone.');
      } else if (order.allowForManualPick != true) {
        await showBlockedErrorDialog(
            context, 'order $number is marked as not for manual pick');
      } else if (availability.remainingQuantity <= 0 &&
          availability.allocationMode != 'ITEM_QUANTITY') {
        await showBlockedErrorDialog(context,
            "there's no open quantity left for manual pick of order $number");
      } else {
        final queueEnabled = availability.allocationMode == 'ITEM_QUANTITY' &&
            await PreprintedManualPickService.queueEnabled();
        if (!mounted || generation != _orderLookupGeneration) return;
        setState(() {
          _completionVerified = false;
          _quantityNotice = null;
          _recentOtherSubmitter = null;
          _queueSnapshotLoaded = false;
          _statusRefreshTicks = 5;
          _queueEnabled = queueEnabled;
          _queueTasks = [];
          _queueOffline = queueEnabled;
          _currentOrder = order;
          _remainingByLine = availability.remainingByLine;
          _remainingIsCurrent = true;
          _orderNumberController.text = number;
          _lpnController.clear();
        });
        if (queueEnabled) await _refreshQueue();
        if (!queueEnabled) unawaited(_refreshPickedSummary());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && generation == _orderLookupGeneration) {
            _lpnFocusNode.requestFocus();
          }
        });
      }
    } catch (error) {
      if (mounted &&
          generation == _orderLookupGeneration &&
          _orderNumberController.text.trim() == number) {
        await showErrorDialog(context,
            error is WebAPICallException ? error.errMsg() : error.toString());
      }
    } finally {
      if (mounted && generation == _orderLookupGeneration) {
        setState(() => _loadingOrder = false);
      }
    }
  }

  @override
  void dispose() {
    _queueTimer?.cancel();
    _orderLookupGeneration++;
    _lpnFocusNode.removeListener(_handleLpnFocusChanged);
    _lpnController.removeListener(_handleLpnTextChanged);
    _orderNumberController.dispose();
    _lpnController.dispose();
    _orderNumberFocusNode.dispose();
    _lpnFocusNode.dispose();
    super.dispose();
  }

  bool isOrderOpenForManualPick(Order order) =>
      _remainingByLine.values.any((quantity) => quantity > 0);

  Widget _buildPickToShipStageInput(BuildContext context) {
    return buildTwoSectionInputRow(
      CWMSLocalizations.of(context).pickToShipStage,
      Checkbox(
        value: _pickToShipStage,
        onChanged: _confirmingPick
            ? null
            : (bool? value) {
                setState(() {
                  _pickToShipStage = value!;
                });
              },
      ),
    );
  }

  Widget _buildLPNInput(BuildContext context) {
    return buildTwoSectionInputRow(
      CWMSLocalizations.of(context).lpn + ": ",
      Focus(
        child: SystemControllerNumberTextBox(
            type: "lpn",
            controller: _lpnController,
            readOnly: _pendingManualPick != null || _confirmingPick,
            // iPhone users type LPNs; hiding its keyboard can repeatedly lose focus.
            showKeyboard: Theme.of(context).platform == TargetPlatform.iOS,
            focusNode: _lpnFocusNode,
            onClear: (value) {
              _lpnControllerCleared();
              return null;
            },
            autofocus: true,
            validator: (v) {
              // if we only need one LPN, then make sure the user input the LPN in this form.
              // otherwise, we will flow to next LPN Capture form to let the user capture
              // more LPNs
              if (v?.trim().isEmpty == true) {
                return CWMSLocalizations.of(context)
                    .missingField(CWMSLocalizations.of(context).lpn);
              }

              return null;
            }),
      ),
    );
  }

  void _lpnControllerCleared() {
    _lpnFocusNode.requestFocus();
  }

  String get _lpnAttemptKey =>
      '${_currentOrder?.id}:${_lpnController.text.trim()}';

  void _handleLpnTextChanged() {
    // Selection/focus changes also notify the controller. Only actual text edits rearm auto-submit.
    if (_observedLpnText == _lpnController.text) return;
    _observedLpnText = _lpnController.text;
    _lastAutomaticLpnAttempt = null;
  }

  void _handleLpnFocusChanged() {
    if (!_lpnFocusNode.hasFocus) _enterOnLPNController(0);
  }

  Future<void> _enterOnLPNController(int _) async {
    if (!mounted ||
        _confirmingPick ||
        _loadingOrder ||
        !_readyToConfirm ||
        _currentOrder == null ||
        _pendingManualPick != null ||
        _lpnFocusNode.hasFocus ||
        _lpnController.text.trim().isEmpty ||
        _lastAutomaticLpnAttempt == _lpnAttemptKey) return;
    await _onOrderManualPickConfirm();
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        buildTwoButtonRow(
            context,
            ElevatedButton(
              onPressed: _currentOrder == null ||
                      !_readyToConfirm ||
                      _confirmingPick ||
                      _allSubmitted
                  ? null
                  : _onConfirmButtonClick,
              child: Text(CWMSLocalizations.of(context).confirm),
            ),
            badge.Badge(
              showBadge: true,
              badgeStyle: badge.BadgeStyle(
                padding: EdgeInsets.all(8),
                badgeColor: Colors.deepPurple,
              ),
              badgeContent: Text(
                inventoryOnRF.length.toString(),
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: inventoryOnRF.isEmpty || _confirmingPick
                      ? null
                      : _startDeposit,
                  child: Text(CWMSLocalizations.of(context).depositInventory),
                ),
              ),
            ))
      ],
    );
  }

  _onConfirmButtonClick() async {
    await _onOrderManualPickConfirm();
  }

  Future<void> _onOrderManualPickConfirm() async {
    return ScanFeedback.run(() async {
      if (!mounted || _confirmingPick || _currentOrder == null) return;
      if (_queueEnabled &&
          _remainingIsCurrent &&
          _pendingManualPick == null &&
          _remainingByLine.values.fold<int>(0, (sum, value) => sum + value) <=
              0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No reserved quantity remains. Open Allocate to reserve stock before picking.')));
        return;
      }
      if (_queueEnabled && _queueBlocked && _pendingManualPick == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Check the pending tasks before scanning another pallet.')));
        return;
      }
      _lastAutomaticLpnAttempt = _lpnAttemptKey;
      _confirmingPick = true;
      if (mounted) setState(() => _readyToConfirm = false);
      try {
        await _confirmOrderManualPick();
      } finally {
        _confirmingPick = false;
        if (mounted) setState(() => _readyToConfirm = true);
      }
    });
  }

  Future<void> _confirmOrderManualPick() async {
    Map<String, dynamic>? request = await PreprintedManualPickService.pending();
    if (request == null) {
      final source = _lpnController.text.trim();
      if (source.isEmpty) {
        await showBlockedErrorDialog(context, 'LPN is required');
        return;
      }
      Map<String, dynamic> preview;
      showLoading(context);
      try {
        preview = await PreprintedManualPickService.preview(
            _currentOrder!.id!, source);
      } catch (error) {
        if (mounted) {
          Navigator.of(context).pop();
          await _showPickRejection(error is WebAPICallException
              ? error.errMsg()
              : 'Could not load picking quantities. Please try again.');
        }
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      final sourceQuantity = preview['sourceQuantity'];
      final pickableQuantity = preview['pickableQuantity'];
      if (sourceQuantity is! int ||
          sourceQuantity <= 0 ||
          pickableQuantity is! int ||
          pickableQuantity <= 0 ||
          pickableQuantity > sourceQuantity) {
        await showBlockedErrorDialog(context,
            'No valid picking quantity. Reload the order and scan again.');
        return;
      }
      // Only a freshly validated full pallet can bypass the split dialog.
      // The POST still rechecks demand and stock and keeps its retry ID.
      final Map<String, dynamic>? choice = pickableQuantity == sourceQuantity
          ? {'quantity': sourceQuantity, 'newLpn': '', 'keepOriginal': false}
          : await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (_) => ManualPickSplitDialog(
                  sourceLpn: source,
                  sourceQuantity: sourceQuantity,
                  pickableQuantity: pickableQuantity));
      if (choice == null || !mounted) return;
      request = {
        'orderId': _currentOrder!.id!,
        'orderNumber': _currentOrder!.number!,
        if (_queueEnabled) 'queued': true,
        'sourceLpn': source,
        'expectedQuantity': preview['sourceQuantity'],
        ...choice,
        'destination':
            _pickToShipStage ? '@SHIP_STAGE' : Global.getLastLoginRFCode()
      };
    } else {
      final retry = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text(uiText(context, "Pick awaiting confirmation")),
                  content: Text(uiTemplate(
                      context,
                      "Order {0}\nLPN {1}\nQuantity {2}\nRetry this same pick to check and finish it safely.",
                      [
                        request!['orderNumber'],
                        request['sourceLpn'],
                        request['quantity']
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, 'close'),
                        child: Text(uiText(context, "Close"))),
                    TextButton(
                        onPressed: () => Navigator.pop(context, 'retry'),
                        child: Text(uiText(context, "Retry"))),
                    TextButton(
                        onPressed: () => Navigator.pop(context, 'cancel'),
                        child: Text(uiText(context, "Cancel if not started")))
                  ]));
      if (!mounted) return;
      if (retry == 'cancel') {
        try {
          final cancelled = await PreprintedManualPickService.cancelUnstarted();
          if (!mounted) return;
          if (cancelled) {
            setState(() => _pendingManualPick = null);
            _clearField();
            _reloadInventoryOnRF();
          } else
            await showBlockedErrorDialog(context,
                'This pick has already been reserved or processed. Retry it or ask a supervisor; do not split again.');
        } catch (_) {
          if (mounted)
            await showBlockedErrorDialog(context,
                'Could not verify cancellation. Keep both labels and retry later.');
        }
        return;
      }
      if (retry != 'retry') return;
    }
    showLoading(context);
    try {
      await PreprintedManualPickService.submit(request);
      if (request['queued'] != true) ScanFeedback.confirmed();
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() {
        _pendingManualPick = null;
        _remainingIsCurrent = false;
        _completionVerified = false;
      });
    } catch (error) {
      final pending = await PreprintedManualPickService.pending();
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _pendingManualPick = pending);
      unawaited(_refreshQueuedAvailability());
      await showBlockedErrorDialog(
          context,
          error is WebAPICallException
              ? error.errMsg()
              : 'Confirmation is not yet known. Keep both labels and retry the same pick; do not split again.');
      return;
    }
    if (request['queued'] == true) {
      // Acceptance is not completion. Release the scanner while the server finishes the saved task.
      _lpnController.clear();
      _lpnFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          duration: Duration(seconds: 1),
          content: Text('Pallet accepted — remaining quantity is updating.')));
      unawaited(_refreshQueue());
      unawaited(_refreshQueuedAvailability());
      return;
    }
    _refreshScreenAfterPickConfirm();
    try {
      await _refreshOrderInformation();
    } catch (_) {
      if (mounted)
        await showBlockedErrorDialog(context,
            'Pick confirmed, but the order could not be refreshed. Please reload the order.');
    }
  }

  Future<void> _refreshQueuedAvailability() async {
    final id = _currentOrder?.id;
    final generation = _orderLookupGeneration;
    if (id == null || _statusRefreshing) return;
    _statusRefreshing = true;
    try {
      final availability = await OrderService.getManualPickAvailability(id);
      if (!mounted ||
          generation != _orderLookupGeneration ||
          _currentOrder?.id != id) return;
      final changed = _remainingIsCurrent &&
          (_remainingByLine.length != availability.remainingByLine.length ||
              _remainingByLine.entries
                  .any((e) => availability.remainingByLine[e.key] != e.value));
      final externalChange =
          changed && !_confirmingPick && _pendingManualPick == null;
      final expected = _currentOrder!.orderLines.fold<int>(
          0,
          (sum, line) =>
              sum + (line.expectedQuantity ?? 0) - (line.shippedQuantity ?? 0));
      final picks = await PreprintedManualPickService.currentPicks(id);
      final pickedByItem = <int, int>{};
      for (final row in picks) {
        final item = (row['itemId'] as num?)?.toInt();
        final quantity = (row['pickedQuantity'] as num?)?.toInt() ?? 0;
        if (item != null && quantity > 0)
          pickedByItem.update(item, (value) => value + quantity,
              ifAbsent: () => quantity);
      }
      bool complete = false;
      if (availability.remainingQuantity == 0 && !_tasksPending) {
        final picked = picks.fold<int>(
            0,
            (sum, row) =>
                sum + ((row['pickedQuantity'] as num?)?.toInt() ?? 0));
        complete = expected > 0 && picked == expected;
      }
      if (!mounted ||
          generation != _orderLookupGeneration ||
          _currentOrder?.id != id) return;
      setState(() {
        if (externalChange) {
          final quantities = availability.remainingByLine.entries.map((e) {
            final lines =
                _currentOrder!.orderLines.where((line) => line.id == e.key);
            final item = lines.isEmpty
                ? 'Line ${e.key}'
                : (lines.first.item?.name ?? 'Line ${e.key}');
            return '$item: ${e.value}';
          }).join(', ');
          _quantityNotice =
              '${_recentOtherSubmitter == null ? 'Order quantities changed' : '${_recentOtherSubmitter} submitted another pallet; order quantities changed'}. Remaining to pick — $quantities. Review the updated quantity before confirming.';
        }
        _recentOtherSubmitter = null;
        _pickedByItem = pickedByItem;
        _remainingByLine = availability.remainingByLine;
        _remainingIsCurrent = true;
        _completionVerified = complete;
        _statusRefreshTicks = 0;
      });
      if (_allSubmitted) _lpnFocusNode.unfocus();
    } catch (_) {
      if (mounted && generation == _orderLookupGeneration) {
        setState(() {
          _pickedByItem = null;
          _remainingIsCurrent = false;
          _completionVerified = false;
        });
      }
    } finally {
      _statusRefreshing = false;
    }
  }

  Widget _buildCompletionCard() => Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    _pickingComplete
                        ? 'Picking complete'
                        : _tasksPending
                            ? 'All quantities submitted'
                            : 'No reserved quantity remaining',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _pickingComplete ? Colors.green : null)),
                const SizedBox(height: 8),
                Text(_pickingComplete
                    ? 'All required quantities have been picked. This does not mean the order has shipped.'
                    : _tasksPending
                        ? 'Processing remaining pallets. Any errors will appear above.'
                        : 'Checking the order. If picking is unfinished, reserve more stock in Allocate.'),
                if (_pickingComplete)
                  Wrap(spacing: 8, children: [
                    ElevatedButton(
                        onPressed: _clearField,
                        child: const Text('Next Order')),
                  ]),
              ],
            )),
      );

  Future<void> _showPickRejection(String message) async {
    final rejection = PickRejection.parse(message);
    if (rejection == null) {
      await showBlockedErrorDialog(context, message);
      return;
    }
    ScanFeedback.reportError(rejection.reason);
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
              title: Text(rejection.title),
              content: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('LPN: ${rejection.lpn}'),
                    Text('Current location: ${rejection.location}'),
                    const SizedBox(height: 16),
                    Text(rejection.reason),
                    const SizedBox(height: 12),
                    Text(rejection.nextAction),
                  ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Scan Another LPN'))
              ],
            ));
    if (mounted) {
      _lpnController.clear();
      _lpnFocusNode.requestFocus();
    }
  }

  Future<void> _refreshPickedSummary() async {
    final id = _currentOrder?.id;
    final generation = _orderLookupGeneration;
    if (id == null) return;
    try {
      final picks = await PreprintedManualPickService.currentPicks(id);
      final totals = <int, int>{};
      for (final row in picks) {
        final item = (row['itemId'] as num?)?.toInt();
        final quantity = (row['pickedQuantity'] as num?)?.toInt() ?? 0;
        if (item != null && quantity > 0)
          totals.update(item, (v) => v + quantity, ifAbsent: () => quantity);
      }
      if (mounted &&
          generation == _orderLookupGeneration &&
          _currentOrder?.id == id) setState(() => _pickedByItem = totals);
    } catch (_) {
      if (mounted && generation == _orderLookupGeneration)
        setState(() => _pickedByItem = null);
    }
  }

  Widget _buildPickedSummary() {
    final items = <int, String>{};
    for (final line in _currentOrder!.orderLines) {
      if (line.item?.id != null)
        items[(line.item?.id)!] = line.item?.name ?? 'Item ${line.item?.id}';
    }
    return SizedBox(
        width: double.infinity,
        child: Card(
            margin: const EdgeInsets.only(top: 16),
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xffdfe6ef))),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Picked so far',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff163253))),
                      const SizedBox(height: 8),
                      if (_pickedByItem == null)
                        Text(_remainingIsCurrent
                            ? 'Updating picked quantities…'
                            : 'Picked quantity unavailable. Reload the order.')
                      else
                        for (final item in items.entries)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                  '${item.value}: ${_pickedByItem![item.key] ?? 0} picked')),
                      if (_pickedByItem?.values
                              .any((quantity) => quantity > 0) ==
                          true)
                        TextButton(
                            onPressed:
                                _viewingPallets ? null : _showPickedPallets,
                            child: Text(_viewingPallets
                                ? 'Loading pallets…'
                                : 'View Picked Pallets')),
                    ]))));
  }

  Future<void> _showPickedPallets() async {
    final id = _currentOrder?.id;
    final generation = _orderLookupGeneration;
    if (id == null) return;
    setState(() => _viewingPallets = true);
    try {
      final rows = await PreprintedManualPickService.pickedPallets(id);
      if (!mounted || generation != _orderLookupGeneration) return;
      await showModalBottomSheet<void>(
          context: context,
          builder: (_) => SafeArea(
                child: Column(children: [
                  const ListTile(title: Text('Currently picked pallets')),
                  Expanded(
                      child: ListView(
                          children: rows
                              .map((row) => ListTile(
                                    title: Text(row['lpn']
                                                ?.toString()
                                                .trim()
                                                .isNotEmpty ==
                                            true
                                        ? row['lpn'].toString()
                                        : 'LPN unavailable'),
                                    subtitle: Text(
                                        'Submitted by ${_palletSubmitter(row)}'),
                                    trailing:
                                        Text('Qty: ${row['quantity'] ?? 0}'),
                                  ))
                              .toList())),
                ]),
              ));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not load picked pallets. Please try again.')));
    } finally {
      if (mounted) {
        setState(() => _viewingPallets = false);
        unawaited(_refreshQueuedAvailability());
      }
    }
  }

  _refreshScreenAfterPickConfirm() {
    // after we sucessfully pick the LPN, clear the LPN field
    _lpnController.text = "";
    _lpnFocusNode.requestFocus();
    _readyToConfirm = true;

    _reloadInventoryOnRF();
  }

  Future<void> _refreshOrderInformation() async {
    final number = _currentOrder!.number!;
    final orderId = _currentOrder!.id!;
    final generation = _orderLookupGeneration;
    // Item labels are already loaded. Only current shipment demand changes.
    final availability = await OrderService.getManualPickAvailability(orderId);
    if (!mounted ||
        generation != _orderLookupGeneration ||
        _orderNumberController.text.trim() != number) return;
    _remainingByLine = availability.remainingByLine;
    _remainingIsCurrent = true;
    unawaited(_refreshPickedSummary());

    if (!isOrderOpenForManualPick(_currentOrder!)) {
      await showBlockedDialog(context, 'Order picking complete',
          'Order $number has no remaining quantity to pick.');
      if (mounted) _clearField();
    } else {
      setState(() {
        _currentOrder;
      });
    }
  }

  void _reloadInventoryOnRF() {
    InventoryService.getInventoryOnCurrentRF().then((value) {
      if (!mounted) return;
      setState(() {
        inventoryOnRF = value;
      });
    });
  }

  // call the deposit form to deposit the inventory on the RF
  Future<void> _startDeposit() async {
    await Navigator.of(context).pushNamed("inventory_batch_deposit");

    // refresh the inventory on the RF
    _reloadInventoryOnRF();
  }
}
