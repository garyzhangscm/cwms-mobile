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
import 'package:flutter/gestures.dart';
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

  bool _readyToConfirm = true;
  bool _loadingOrder = false;
  bool _confirmingPick = false;
  Map<String, dynamic>? _pendingManualPick;
  int _orderLookupGeneration = 0;

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

    _pickToShipStage = Global.getConfigurationAsBoolean("pickToShipStage");

    _currentOrder = null;
    inventoryOnRF = <Inventory>[];

    _lpnFocusNode.addListener(() {
      print("_lpnFocusNode.hasFocus: ${_lpnFocusNode.hasFocus}");
      if (!_lpnFocusNode.hasFocus &&
          _lpnController.text.isNotEmpty &&
          _readyToConfirm) {
        // if we tab out, then add the LPN to the list
        _readyToConfirm = false; // block the 'confirm button'
        _enterOnLPNController(10);
      }
    });

    _reloadInventoryOnRF();
    _restorePendingPick();
  }

  Future<void> _restorePendingPick() async {
    final pending = await PreprintedManualPickService.pending();
    if (!mounted || pending == null) return;
    setState(() {
      _pendingManualPick = pending;
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
      appBar: AppBar(title: Text(CWMSLocalizations.of(context).manualPick)),
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
              // build a hypelink to allow the user to click and show
              // what the user will need to pick and the remain quantity to be picked
              _currentOrder == null
                  ? Container()
                  : _buildPickingInformation(context),
              // whether directly pick the inventory onto production line's in stage
              // or pick the inventory onto the RF
              _currentOrder == null
                  ? Container()
                  : _buildPickToShipStageInput(context),
              // allow user to scan in LPN
              _currentOrder == null ? Container() : _buildLPNInput(context),
              // allow user to input LPN
              _buildButtons(context),
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
            readOnly: _pendingManualPick != null,
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
                    onPressed: _loadingOrder
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
                    onPressed:
                        _pendingManualPick != null ? null : () => _clearField(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            )));
  }

  Widget _buildPickingInformation(BuildContext context) {
    return
        // confirm the location
        Row(children: <Widget>[
      RichText(
        text: TextSpan(
            text: uiText(context, "click to see the item to be picked"),
            style: new TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.bold,
                fontSize: 15),
            recognizer: new TapGestureRecognizer()
              ..onTap = () => openPickingInformationForm()),
      )
    ]);
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
    _orderLookupGeneration++;
    _loadingOrder = false;
    _orderNumberController.text = "";
    setState(() {
      _currentOrder = null;
      _remainingByLine = {};
    });
    _orderNumberFocusNode.requestFocus();
    _readyToConfirm = true;
  }

  Future<void> _enterOnOrderController(int tryTime) async {
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
    });
    try {
      final order = await OrderService.getOrderByNumber(number);
      final availability = order.allowForManualPick == true
          ? await OrderService.getManualPickAvailability(order.id!)
          : null;
      if (!mounted ||
          generation != _orderLookupGeneration ||
          _orderNumberController.text.trim() != number) return;
      if (order.allowForManualPick != true) {
        await showBlockedErrorDialog(
            context, 'order $number is marked as not for manual pick');
      } else if (availability!.remainingQuantity <= 0) {
        await showBlockedErrorDialog(context,
            "there's no open quantity left for manual pick of order $number");
      } else {
        setState(() {
          _currentOrder = order;
          _remainingByLine = availability.remainingByLine;
          _orderNumberController.text = number;
          _lpnController.clear();
        });
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
    _orderLookupGeneration++;
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
        onChanged: (bool? value) {
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
            readOnly: _pendingManualPick != null,
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

  void _enterOnLPNController(int tryTime) async {
    // we may come here when the user scan / press
    // enter in the LPN controller. In either case, we will need to make sure
    // the lpn doesn't have focus before we start confirm

    printLongLogMessage(
        "_enterOnLPNController: Start to confirm order manual pick, tryTime = $tryTime");
    if (tryTime <= 0) {
      // do nothing as we run out of try time

      setState(() {
        // enable the confirm button
        _readyToConfirm = true;
      });
      return;
    }
    printLongLogMessage(
        "_enterOnLPNController / lpnFocusNode.hasFocus:   ${_lpnFocusNode.hasFocus}");
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
        buildTwoButtonRow(
            context,
            ElevatedButton(
              onPressed: _currentOrder == null || !_readyToConfirm
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
                  onPressed: inventoryOnRF.length == 0 ? null : _startDeposit,
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
    if (_confirmingPick || _currentOrder == null) return;
    _confirmingPick = true;
    if (mounted) setState(() => _readyToConfirm = false);
    try {
      await _confirmOrderManualPick();
    } finally {
      _confirmingPick = false;
      if (mounted) setState(() => _readyToConfirm = true);
    }
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
          await showBlockedErrorDialog(
              context,
              error is WebAPICallException
                  ? error.errMsg()
                  : 'Could not load picking quantities. Please try again.');
        }
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      final choice = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (_) => ManualPickSplitDialog(
              sourceLpn: source,
              sourceQuantity: preview['sourceQuantity'] as int,
              pickableQuantity: preview['pickableQuantity'] as int));
      if (choice == null || !mounted) return;
      request = {
        'orderId': _currentOrder!.id!,
        'orderNumber': _currentOrder!.number!,
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
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _pendingManualPick = null);
    } catch (error) {
      final pending = await PreprintedManualPickService.pending();
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() => _pendingManualPick = pending);
      await showBlockedErrorDialog(
          context,
          error is WebAPICallException
              ? error.errMsg()
              : 'Confirmation is not yet known. Keep both labels and retry the same pick; do not split again.');
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

  _refreshScreenAfterPickConfirm() {
    // after we sucessfully pick the LPN, clear the LPN field
    _lpnController.text = "";
    _lpnFocusNode.requestFocus();
    _readyToConfirm = true;

    _reloadInventoryOnRF();
  }

  Future<void> _refreshOrderInformation() async {
    final number = _currentOrder!.number!;
    final generation = _orderLookupGeneration;
    final order = await OrderService.getOrderByNumber(number);
    final availability =
        await OrderService.getManualPickAvailability(order.id!);
    if (!mounted ||
        generation != _orderLookupGeneration ||
        _orderNumberController.text.trim() != number) return;
    _currentOrder = order;
    _remainingByLine = availability.remainingByLine;
    printLongLogMessage("Refresh order and load all open quantites");

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
    await Navigator.of(context).pushNamed("inventory_deposit");

    // refresh the inventory on the RF
    _reloadInventoryOnRF();
  }
}
