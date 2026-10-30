import 'package:cwms_mobile/shared/scanning/scan_app_bar.dart';
import 'package:cwms_mobile/shared/scanning/scan_feedback.dart';
import 'package:cwms_mobile/i18n/spanish_ui.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:badges/badges.dart' as badge;
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';

import '../../exception/WebAPICallException.dart';
import '../../shared/global.dart';
import '../../warehouse_layout/services/warehouse_location.dart';
import '../models/item.dart';
import '../models/item_unit_of_measure.dart';

import '../../shared/services/barcode_service.dart';
import '../../shared/models/barcode.dart';

// Page to allow the user scan in an LPN and start the put away process
// The LPN can be in receiving stage / storage location / etc
// with or without any pre-assigned destination
class PartialInventoryMovePage extends StatefulWidget {
  PartialInventoryMovePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PartialInventoryMovePageState();
}

class _PartialInventoryMovePageState extends State<PartialInventoryMovePage> {
  // allow user to scan in LPN
  TextEditingController _lpnController = new TextEditingController();
  GlobalKey _formKey = new GlobalKey<FormState>();
  TextEditingController _quantityController = new TextEditingController();
  final _newLpnController = TextEditingController();
  final _newLpnFocusNode = FocusNode();
  ItemUnitOfMeasure? _selectedItemUnitOfMeasure;

  List<Inventory> inventoryOnRF = [];

  FocusNode _lpnFocusNode = FocusNode();

  var _itemNames = Set<String>();
  Map<String, Item> _itemMap = HashMap();
  Map<String, List<int>> _itemInventoryIdMap = HashMap();
  // map to save the total quantity of the map so that
  // the partial move won't exceed the total quantity of the
  // item on the LPN
  Map<String, int> _itemQuantityMap = HashMap();
  var _selectedItemName = "";
  Timer? _timer; // timer to refresh inventory on RF every 2 second
  WarehouseLocation? _cachedRfLocation;
  bool _loadingLpn = false;
  bool _moving = false;
  bool _refreshingRF = false;
  bool _rfReady = false;
  int _lookupVersion = 0;
  String _loadedLpn = "";
  String _pageError = "";
  final Set<String> _uncertainLpns = {};
  int _step = 0;
  String? get _printerOverride => Global.currentFactory?.id == 'colton-injection'
      ? 'Colton_new_lable_office' : null;

  List<InventoryDepositRequest> _inventoryDepositRequests = [];

  @override
  void initState() {
    super.initState();

    inventoryOnRF = [];
    _itemNames = Set<String>();
    _itemMap.clear();
    _itemInventoryIdMap.clear();
    _itemQuantityMap.clear();
    _selectedItemName = "";
    _inventoryDepositRequests = [];

    _lpnFocusNode.addListener(() {
      print("lpnFocusNode.hasFocus: ${_lpnFocusNode.hasFocus}");
      if (!_lpnFocusNode.hasFocus && _lpnController.text.isNotEmpty) {
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

        _onLoadingLPNInformation();
      }
    });

    _reloadInventoryOnRF();
  }

  @override
  void dispose() {
    // remove any timer so we won't need to load the next work again after
    // the user return from this page
    _timer?.cancel();
    _lpnController.dispose();
    _quantityController.dispose();
    _newLpnController.dispose();
    _newLpnFocusNode.dispose();
    _lpnFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: ScanAppBar(title: const Text('Partial Move')),
      resizeToAvoidBottomInset: true,
      endDrawer: MyDrawer(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(children: List.generate(3, (i) => Expanded(child: Column(children: [
              CircleAvatar(radius: 18,
                backgroundColor: i == _step ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                foregroundColor: i == _step ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                child: Text('${i + 1}')),
              const SizedBox(height: 8),
              Text(['Source', 'Split', 'Deposit'][i], style: TextStyle(fontWeight: i == _step ? FontWeight.bold : FontWeight.normal)),
            ])))),
            const SizedBox(height: 28),
            if (_pageError.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(_pageError, style: TextStyle(color: theme.colorScheme.error))),
            if (_loadingLpn || _moving || _refreshingRF) const LinearProgressIndicator(),
            if (_step == 0) ...[
              Text('Scan the original pallet', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Choose the pallet you want to split. Its remaining quantity will stay on the original LPN.'),
              const SizedBox(height: 24),
              _buildLPNController(context),
              const SizedBox(height: 20),
              FilledButton(onPressed: _loadingLpn ? null : _onLoadingLPNInformation, child: const Text('Continue')),
              if (inventoryOnRF.isNotEmpty) TextButton(onPressed: () => setState(() => _step = 2), child: Text('View pallets awaiting deposit (${inventoryOnRF.length})')),
            ],
            if (_step == 1) ...[
              Text('Enter split details', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Original LPN: $_loadedLpn'),
              const SizedBox(height: 20),
              if (_itemNames.length == 1) _buildItemInformation(context, _itemNames.first)
              else _builItemController(context),
              if (_selectedItemName.isNotEmpty) ...[
                _builItemDescriptionController(context),
                _buildQuantityController(context),
              ],
              const SizedBox(height: 16),
              TextFormField(key: const ValueKey('partial-new-lpn'), controller: _newLpnController,
                focusNode: _newLpnFocusNode, enabled: !_moving,
                decoration: const InputDecoration(labelText: 'New LPN', border: OutlineInputBorder(), helperText: 'Scan an unused label for the split quantity.'),
                onChanged: (_) => setState(() {}), onFieldSubmitted: (_) => _onAddingLPN()),
              const SizedBox(height: 24),
              ElevatedButton(key: const ValueKey('partial-add'),
                onPressed: !_moving && !_loadingLpn && _validateQuantity() && _newLpnController.text.trim().isNotEmpty ? _onAddingLPN : null,
                child: const Text('Confirm split')),
              TextButton(onPressed: _moving ? null : () {setState(() => _step = 0); _lpnFocusNode.requestFocus();}, child: const Text('Back')),
            ],
            if (_step == 2) ...[
              Text(_moving ? 'Splitting pallet…' : 'Review & deposit', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('After a successful split, place the new pallet in its destination using Deposit.'),
              const SizedBox(height: 20),
              for (final request in _inventoryDepositRequests) Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(request.requestInProcess == true ? 'Processing' : request.requestResult == true ? 'Split completed' : 'Needs attention', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Text('New LPN: ${request.newLpn ?? 'Pending'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Original LPN: ${request.lpn}'),
                  Text('Item: ${request.itemName}'),
                  Text('Quantity: ${request.quantity} (base units)'),
                  if (request.requestResult == false && request.requestInProcess != true) Text(request.result ?? '', style: TextStyle(color: theme.colorScheme.error)),
                  if (request.requestResult == true) ...[
                    const SizedBox(height: 16),
                    Text('Printer: ${_printerOverride ?? Global.lastLoginRF?.printerName ?? Global.getRFConfiguration.printerName ?? 'Device default'}'),
                    OutlinedButton(onPressed: () => _printLPNLabel(request.newLpn!), child: const Text('Print label')),
                  ],
                ]))),
              ElevatedButton(onPressed: _moving || !_rfReady || _refreshingRF || inventoryOnRF.isEmpty ? null : _startDeposit,
                child: Text(CWMSLocalizations.of(context).depositInventory)),
              TextButton(onPressed: _moving ? null : () { _clearLPN(); setState(() => _step = 0); }, child: const Text('Split another pallet')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLPNController(BuildContext context) {
    return TextFormField(
            key: const ValueKey('partial-source-lpn'),
            controller: _lpnController,
            enabled: !_moving,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _onLoadingLPNInformation(),
            onChanged: (_) {
              setState(() {
                _loadedLpn = '';
              });
            },
            autofocus: true,
            // 校验用户名（不能为空）
            focusNode: _lpnFocusNode,
            decoration: InputDecoration(
              labelText: 'Original LPN',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: _moving ? null : () => _clearLPN(),
                icon: Icon(Icons.close),
              ),
            ),
            validator: (v) {
              return v!.trim().isNotEmpty
                  ? null
                  : CWMSLocalizations.of(context)
                      .missingField(CWMSLocalizations.of(context).lpn);
            });
  }

  void _clearLPN() {
    ++_lookupVersion;
    _loadedLpn = '';
    setState(() {
      _lpnController.text = "";
      _loadedLpn = "";
      _newLpnController.clear();
      _itemNames = Set<String>();
      _itemMap.clear();
      _itemInventoryIdMap.clear();
      _itemQuantityMap.clear();
      _selectedItemName = "";
      _quantityController.clear();
      _selectedItemUnitOfMeasure = null;
      _inventoryDepositRequests = [];
    });

    _lpnFocusNode.requestFocus();
  }

  Widget _buildItemInformation(BuildContext context, String itemName) {
    return buildTwoSectionInformationRow(
        CWMSLocalizations.of(context).item, itemName);
  }

  Widget _builItemController(BuildContext context) {
    return DropdownButton(
      // hint: Text(CWMSLocalizations.of(context)!.pleaseSelect),
      items: _getItemNames(),
      value: _selectedItemName,
      elevation: 1,
      isExpanded: true,
      icon: Icon(
        Icons.list,
        size: 20,
      ),
      onChanged: (String? value) {
        //下拉菜单item点击之后的回调
        setState(() {
          _selectedItemName = value!;
          _quantityController.clear();
          _selectedItemUnitOfMeasure = null;
          _setDefaultItemUnitOfMeasure();
        });
      },
    );
  }

  _builItemDescriptionController(BuildContext context) {
    if (_itemMap.containsKey(_selectedItemName)) {
      return buildTwoSectionInformationRow(CWMSLocalizations.of(context).item,
          _itemMap[_selectedItemName]?.description ?? "");
    }

    return buildTwoSectionInformationRow(
        CWMSLocalizations.of(context).item, "");
  }

  _buildQuantityController(BuildContext context) {
    return buildThreeSectionInputRow(
        CWMSLocalizations.of(context).quantity,
        TextFormField(
            keyboardType: TextInputType.number,
            key: const ValueKey('partial-quantity'),
            controller: _quantityController,
            enabled: !_moving && !_loadingLpn,
            onChanged: (_) => setState(() {}),
            autofocus: true,
            decoration: InputDecoration(isDense: true),
            // 校验ITEM NUMBER（不能为空）
            validator: (v) {
              if (v!.trim().isEmpty) {
                return uiText(context, "please type in quantity");
              }
              if (!_validateQuantity()) {
                return "Enter a positive quantity smaller than the quantity on the original LPN.";
              }
              return null;
            }),
        _getItemUnitOfMeasures().isEmpty
            ? Container()
            : DropdownButton(
                hint: Text(CWMSLocalizations.of(context).pleaseSelect),
                items: _getItemUnitOfMeasures(),
                value: _selectedItemUnitOfMeasure,
                elevation: 1,
                isExpanded: true,
                icon: Icon(
                  Icons.list,
                  size: 20,
                ),
                underline: Container(
                  height: 0,
                  color: Colors.deepPurpleAccent,
                ),
                onChanged: (ItemUnitOfMeasure? value) {
                  //下拉菜单item点击之后的回调
                  setState(() {
                    _selectedItemUnitOfMeasure = value;
                  });
                },
              ));
  }

  List<DropdownMenuItem<ItemUnitOfMeasure>> _getItemUnitOfMeasures() {
    List<DropdownMenuItem<ItemUnitOfMeasure>> dropdownMenuItems = [];

    if (!_itemMap.containsKey(_selectedItemName)) {
      return dropdownMenuItems;
    }
    Item item = _itemMap[_selectedItemName]!;

    for (int i = 0;
        i < (item.defaultItemPackageType?.itemUnitOfMeasures.length ?? 0);
        i++) {
      dropdownMenuItems.add(DropdownMenuItem(
        value: item.defaultItemPackageType?.itemUnitOfMeasures[i],
        child: Text(item.defaultItemPackageType?.itemUnitOfMeasures[i]
                .unitOfMeasure!.name ??
            ""),
      ));
    }

    return dropdownMenuItems;
  }

  void _setDefaultItemUnitOfMeasure() {
    final item = _itemMap[_selectedItemName];
    final units = item?.defaultItemPackageType?.itemUnitOfMeasures ?? [];
    if (units.isEmpty) {
      _selectedItemUnitOfMeasure = null;
      return;
    }
    _selectedItemUnitOfMeasure = units.firstWhereOrNull((element) =>
            element.unitOfMeasure?.name?.trim().toUpperCase() == 'PCS' &&
            (element.quantity ?? 0) > 0) ??
        units.firstWhereOrNull((element) =>
            element.id ==
            item?.defaultItemPackageType?.defaultInboundReceivingUOM?.id) ??
        units.first;
  }

  bool _validateQuantity() {
    final enteredQuantity = int.tryParse(_quantityController.text.trim());
    final unitQuantity = _selectedItemUnitOfMeasure?.quantity;
    final availableQuantity = _itemQuantityMap[_selectedItemName];
    if (enteredQuantity == null ||
        enteredQuantity <= 0 ||
        unitQuantity == null ||
        unitQuantity <= 0 ||
        availableQuantity == null) {
      return false;
    }
    return enteredQuantity * unitQuantity < availableQuantity;
  }

  List<DropdownMenuItem<String>> _getItemNames() {
    List<DropdownMenuItem<String>> dropdownMenuItems = [];

    _itemNames.forEach((itemName) {
      dropdownMenuItems.add(DropdownMenuItem(
        value: itemName,
        child: Text(itemName),
      ));
    });

    return dropdownMenuItems;
  }

  // load the inventory information that is associated with the LPN
  // if there's only one item on the LPN, then display the item
  // otherwise, list all the items and let the user choose one
  // to move
  void _onLoadingLPNInformation() async {
    await ScanFeedback.run(() async {
      if (_lpnController.text.isEmpty) {
        showErrorDialog(context, "please input the LPN number");
        return;
      }

      await _loadItemsFromLPN(_lpnController.text);
    });
  }

  /// Get the items from the LPN
  Future<void> _loadItemsFromLPN(String lpn) async {
    return ScanFeedback.run(() async {
      final normalizedLpn = lpn.trim();
      if (normalizedLpn.isEmpty ||
          _loadingLpn ||
          _moving ||
          normalizedLpn == _loadedLpn) {
        // if the user hasn't input the LPN, return an empty list
        return;
      }
      _loadingLpn = true;
      final lookup = ++_lookupVersion;
      _pageError = "";
      setState(() {
        _itemNames.clear();
        _itemMap.clear();
        _itemInventoryIdMap.clear();
        _itemQuantityMap.clear();
        _selectedItemName = "";
        _quantityController.clear();
        _selectedItemUnitOfMeasure = null;
      });

      try {
        final inventories = await InventoryService.findInventory(
            lpn: normalizedLpn, includeDetails: true);

        if (!mounted ||
            lookup != _lookupVersion ||
            _lpnController.text.trim() != normalizedLpn) return;
        if (inventories.isEmpty) {
          _pageError = "LPN $normalizedLpn was not found. Scan another pallet.";
          return;
        }

        for (final inventory in inventories) {
          final item = inventory.item;
          final itemName = item?.name;
          if (itemName == null) continue;
          _itemNames.add(itemName);
          _itemMap[itemName] = item!;
          if (inventory.id != null) {
            _itemInventoryIdMap
                .putIfAbsent(itemName, () => [])
                .add(inventory.id!);
          }
          _itemQuantityMap[itemName] =
              (_itemQuantityMap[itemName] ?? 0) + (inventory.quantity ?? 0);
        }

        setState(() {
          if (_itemNames.isNotEmpty) {
            _loadedLpn = normalizedLpn;
            _step = 1;
            _selectedItemName = _itemNames.first;
            _setDefaultItemUnitOfMeasure();
            if (_selectedItemUnitOfMeasure == null)
              _pageError =
                  "This item has no valid unit of measure. Check its package configuration.";
          } else {
            _pageError = "Item details could not be loaded for this LPN.";
          }
        });
      } catch (err) {
        if (mounted) {
          _pageError = "Unable to load LPN $normalizedLpn. Please try again.";
        }
      } finally {
        _loadingLpn = false;
        if (mounted) setState(() {});
      }
    });
  }

  Widget _buildButtons(BuildContext context) {
    return buildTwoButtonRow(
        context,
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Theme.of(context).primaryColor,
          ),
          key: const ValueKey('partial-add'),
          onPressed: _newLpnController.text.trim().isNotEmpty &&
                  !_moving &&
                  !_loadingLpn &&
                  _loadedLpn == _lpnController.text.trim() &&
                  _validateQuantity() &&
                  _lpnController.text.isNotEmpty &&
                  _selectedItemName != "" &&
                  _selectedItemUnitOfMeasure != null &&
                  _quantityController.text.isNotEmpty
              ? _onAddingLPN
              : null,
          child: Text(CWMSLocalizations.of(context).add),
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
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: ElevatedButton(
              onPressed:
                  _moving || !_rfReady || _refreshingRF || inventoryOnRF.isEmpty
                      ? null
                      : _startDeposit,
              child: Text(CWMSLocalizations.of(context).depositInventory),
            ),
          ),
        ));
    /**
      Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        //交叉轴的布局方式，对于column来说就是水平方向的布局方式
        crossAxisAlignment: CrossAxisAlignment.center,
        //就是字child的垂直布局方向，向上还是向下
        verticalDirection: VerticalDirection.down,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child:
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                // onPressed: _onAddingLPN,
                child: Text(CWMSLocalizations.of(context)!.add),
              ),

          ),

          Padding(
              padding: const EdgeInsets.only(left: 10),
              child:
              Badge(
                showBadge: true,
                padding: EdgeInsets.all(8),
                badgeColor: Colors.deepPurple,
                badgeContent: Text(
                  inventoryOnRF.length.toString(),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                child:
                  ElevatedButton(
                    onPressed: _moving || !_rfReady || _refreshingRF || inventoryOnRF.isEmpty ? null : _startDeposit,
                    child: Text(CWMSLocalizations.of(context)!.depositInventory),
                  ),
              )
          ),
        ],
      );
          **/
  }

  // call the deposit form to deposit the inventory on the RF
  Future<void> _startDeposit() async {
    _timer?.cancel();
    // The partial-move page already has the RF inventory list. Reusing it
    // avoids a second full RF inventory request when Deposit opens.
    await Navigator.of(context).pushNamed(
      "inventory_deposit",
      arguments: List<Inventory>.from(inventoryOnRF),
    );

    // refresh the inventory on the RF
    // when we come back from the deposit page, we will refresh
    // 3 times as the deposit happens async so when we return from
    // the deposit page, the last deposit may not be actually done yet
    if (!mounted) return;
    _reloadInventoryOnRF(refreshCount: 3);
    setState(() {
      _inventoryDepositRequests = [];
    });
  }

  Widget _buildDepositRequestList(BuildContext context) {
    /**
    List<InventoryDepositRequest> inventoryDepositRequests =
        InventoryService.getInventoryDepositRequests(inventoryOnRF, true, true);
    return
      Expanded(
        child: ListView.builder(
            itemCount: inventoryDepositRequests.length,
            itemBuilder: (BuildContext context, int index) {

              return InventoryDepositRequestItem(
                  index: index,
                  inventoryDepositRequest: inventoryDepositRequests[index],
              );
            }),
      );
**/
    return Expanded(
        child: ListView.separated(
      itemCount: _inventoryDepositRequests.length,
      itemBuilder: (BuildContext context, int index) {
        return _buildInventoryDepositRequestListTile(context, index);
      },
      separatorBuilder: (context, index) => Divider(
        color: Colors.black,
      ),
    ));
  }

  Widget _buildInventoryDepositRequestListTile(
      BuildContext context, int index) {
    printLongLogMessage("index ${index}");
    printLongLogMessage(
        "_reversedInventories[index].reverseInProgress: ${_inventoryDepositRequests[index].requestInProcess}");
    printLongLogMessage(
        "_reversedInventories[index].reverseInProgress: ${_inventoryDepositRequests[index].requestResult}");

    if (_inventoryDepositRequests[index].requestInProcess == true) {
      // show loading indicator if the inventory still reverse in progress
      printLongLogMessage(
          "show loading for index $index / ${_inventoryDepositRequests[index].lpn}");
      return SizedBox(
          height: 75,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand, //未定位widget占满Stack整个空间
            children: <Widget>[
              ListTile(
                title: Text(CWMSLocalizations.of(context).lpn +
                    ": " +
                    _inventoryDepositRequests[index].lpn!),
                subtitle: Column(children: <Widget>[
                  Row(children: <Widget>[
                    Text(CWMSLocalizations.of(context).item + ": ",
                        textScaleFactor: .9,
                        style: TextStyle(
                          height: 1.15,
                          color: Colors.blueGrey[700],
                          fontSize: 17,
                        )),
                    Text(_inventoryDepositRequests[index].itemName!,
                        textScaleFactor: .9,
                        style: TextStyle(
                          height: 1.15,
                          color: Colors.blueGrey[700],
                          fontSize: 17,
                        )),
                  ]),
                  Row(children: <Widget>[
                    Text(CWMSLocalizations.of(context).quantity + ": ",
                        textScaleFactor: .9,
                        style: TextStyle(
                          height: 1.15,
                          color: Colors.blueGrey[700],
                          fontSize: 17,
                        )),
                    Text(_inventoryDepositRequests[index].quantity.toString(),
                        textScaleFactor: .9,
                        style: TextStyle(
                          height: 1.15,
                          color: Colors.blueGrey[700],
                          fontSize: 17,
                        )),
                  ]),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 5),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(children: [CircularProgressIndicator()]),
                      ),
                      // Expanded(child: Container(color: Colors.amber)),
                    ]),
              ),
            ],
          ));
    } else if (_inventoryDepositRequests[index].requestResult == true) {
      return SizedBox(
          height: 95,
          child: ListTile(
              title: Text(CWMSLocalizations.of(context).lpn +
                  ": " +
                  _inventoryDepositRequests[index].newLpn!),
              subtitle: Column(children: <Widget>[
                Row(children: <Widget>[
                  Text(uiText(context, "From LPN: "),
                      textScaleFactor: .9,
                      style: TextStyle(
                        height: 1.15,
                        color: Colors.blueGrey[700],
                        fontSize: 17,
                      )),
                  Text(_inventoryDepositRequests[index].lpn!,
                      textScaleFactor: .9,
                      style: TextStyle(
                        height: 1.15,
                        color: Colors.blueGrey[700],
                        fontSize: 17,
                      )),
                ]),
                Row(children: <Widget>[
                  Text(CWMSLocalizations.of(context).item + ": ",
                      textScaleFactor: .9,
                      style: TextStyle(
                        height: 1.15,
                        color: Colors.blueGrey[700],
                        fontSize: 17,
                      )),
                  Text(_inventoryDepositRequests[index].itemName!,
                      textScaleFactor: .9,
                      style: TextStyle(
                        height: 1.15,
                        color: Colors.blueGrey[700],
                        fontSize: 17,
                      )),
                ]),
                Row(children: <Widget>[
                  Text(CWMSLocalizations.of(context).quantity + ": ",
                      textScaleFactor: .9,
                      style: TextStyle(
                        height: 1.15,
                        color: Colors.blueGrey[700],
                        fontSize: 17,
                      )),
                  Text(_inventoryDepositRequests[index].quantity.toString(),
                      textScaleFactor: .9,
                      style: TextStyle(
                        height: 1.15,
                        color: Colors.blueGrey[700],
                        fontSize: 17,
                      )),
                ]),
              ]),
              tileColor: Colors.lightGreen,
              trailing: IconButton(
                  icon: new Icon(Icons.print_rounded),
                  onPressed: () => _printLPNLabel(
                      _inventoryDepositRequests[index].newLpn!))));
    } else {
      double height = min(
          75 + (_inventoryDepositRequests[index].result!.length / 50) * 15,
          120);
      return SizedBox(
          height: height,
          child: ListTile(
            title: Text(CWMSLocalizations.of(context).lpn +
                ": " +
                _inventoryDepositRequests[index].lpn!),
            subtitle: Column(children: <Widget>[
              Row(children: <Widget>[
                Text(CWMSLocalizations.of(context).item + ": ",
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    )),
                Text(_inventoryDepositRequests[index].itemName!,
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    )),
              ]),
              Row(children: <Widget>[
                Text(CWMSLocalizations.of(context).quantity + ": ",
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    )),
                Text(_inventoryDepositRequests[index].quantity.toString(),
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    )),
              ]),
              Row(children: <Widget>[
                Flexible(
                  child: Text(
                      CWMSLocalizations.of(context).result +
                          ": " +
                          _inventoryDepositRequests[index].result.toString(),
                      maxLines: 3,
                      style: TextStyle(
                          color: Colors.lightBlue,
                          fontWeight: FontWeight.normal)),
                ),
              ]),
            ]),
            tileColor: _inventoryDepositRequests[index].pendingConfirmation
                ? Colors.orange.shade50
                : Colors.red.shade100,
          ));
    }
  }

  Future<void> _printLPNLabel(String lpn) async {
    showLoading(context);
    Object? failure;
    try {
      await InventoryService.printLPNLabel(lpn, null, _printerOverride);
    } catch (err) {
      failure = err;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    if (failure != null) {
      final detail = failure is WebAPICallException
          ? failure.errMsg()
          : failure.toString();
      final localPrinterFailed = detail.contains('/localplugin/printing/') ||
          detail.contains('INTERNAL_SERVER_ERROR');
      showErrorDialog(context,
          'Could not print the label for LPN $lpn.\n\n'
          '${localPrinterFailed ? 'The warehouse print service returned an error. Please ask your administrator to check the print service and label printer.' : detail}\n\n'
          'Printing does not undo the completed split. Do not split this pallet again.');
    }
  }

  void _onAddingLPN() {
    ScanFeedback.run(() async {
      if (_moving ||
          _loadingLpn ||
          _loadedLpn != _lpnController.text.trim() ||
          !_validateQuantity()) return;
      if (_uncertainLpns.contains(_loadedLpn)) {
        setState(() {
          _pageError =
              "This LPN has a pending move. Check its source and RF inventory before submitting again.";
        });
        return;
      }
      final newLpn = _newLpnController.text.trim();
      if (newLpn.isEmpty || newLpn.toUpperCase() == _loadedLpn.toUpperCase()) {
        setState(() {
          _pageError = 'Scan a new LPN different from the original LPN.';
        });
        _newLpnFocusNode.requestFocus();
        return;
      }
      if (_uncertainLpns.contains(newLpn)) {
        setState(() {
          _pageError =
              'This new LPN has a pending move. Verify the previous result first.';
        });
        return;
      }
      setState(() {
        _moving = true;
        _pageError = '';
      });
      try {
        final existing = await InventoryService.findInventory(lpn: newLpn);
        if (!mounted) return;
        if (existing.isNotEmpty) {
          setState(() {
            _moving = false;
            _pageError =
                'New LPN $newLpn is already in use. Scan an unused label.';
          });
          _newLpnFocusNode.requestFocus();
          return;
        }
      } catch (_) {
        if (mounted)
          setState(() {
            _moving = false;
            _pageError =
                'Could not verify the new LPN. No move was submitted. Try again.';
          });
        return;
      }
      // move the inventory being scanned onto RF
      printLongLogMessage("==>> Start to adding LPN for deposit");
      printLongLogMessage("quantity: ${_quantityController.text}");

      InventoryDepositRequest inventoryDepositRequest =
          new InventoryDepositRequest();
      inventoryDepositRequest.lpn = _lpnController.text.trim();
      int quantity = int.parse(_quantityController.text);
      if (_selectedItemUnitOfMeasure != null) {
        quantity *= _selectedItemUnitOfMeasure!.quantity!;
        printLongLogMessage(
            "by considering the selected UOM, the final quantity is ${quantity}");
      }

      inventoryDepositRequest.quantity = quantity;
      inventoryDepositRequest.itemName = _selectedItemName;

      inventoryDepositRequest.requestInProcess = true;
      inventoryDepositRequest.requestResult = false;
      inventoryDepositRequest.result = "";

      _inventoryDepositRequests.insert(0, inventoryDepositRequest);
      _step = 2;
      FocusScope.of(context).unfocus();

      // Quantity is already in base units. Do not send inventoryId: the
      // legacy endpoint treats that parameter as a whole-inventory move.
      final move = _moveInventoryAsync(inventoryDepositRequest, '',
          destinationLpn: newLpn);

      // Navigator.of(context).pop();

      setState(() {
        _lpnController.text = "";
        _loadedLpn = "";
        _newLpnController.clear();
        _itemNames = Set<String>();
        _itemMap.clear();
        _itemInventoryIdMap.clear();
        _itemQuantityMap.clear();
        _selectedItemName = "";
      });

      await move;
      if (mounted) {
        setState(() {
          _moving = false;
        });
      }
    });
  }

  Future<WarehouseLocation> _getCachedRfLocation() async {
    if (_cachedRfLocation != null) return _cachedRfLocation!;
    _cachedRfLocation =
        await WarehouseLocationService.getWarehouseLocationByName(
            Global.lastLoginRFCode!);
    return _cachedRfLocation!;
  }

  Future<void> _moveInventoryAsync(
      InventoryDepositRequest inventoryDepositRequest, String unitOfMeasure,
      {int? inventoryId,
      int retryTime = 0,
      required String destinationLpn}) async {
    return ScanFeedback.run(() async {
      const maxMoveRetries = 2;
      final totalPerf = Stopwatch()..start();
      try {
        final locationPerf = Stopwatch()..start();
        final locationWasCached = _cachedRfLocation != null;
        final rfLocation = await _getCachedRfLocation();
        printLongLogMessage(
            "[PERF] partial move location=${locationPerf.elapsedMilliseconds}ms cached=$locationWasCached");
        final movePerf = Stopwatch()..start();
        final resultInventories = await InventoryService.moveInventory(
            destinationLpn: destinationLpn,
            lpn: inventoryDepositRequest.lpn!,
            quantity: inventoryDepositRequest.quantity!,
            itemName: inventoryDepositRequest.itemName!,
            unitOfMeasure: unitOfMeasure,
            destinationLocation: rfLocation);
        printLongLogMessage(
            "[PERF] partial move API inventory=$inventoryId request=${movePerf.elapsedMilliseconds}ms total=${totalPerf.elapsedMilliseconds}ms result=${resultInventories.length}");

        if (!mounted) return;
        final returnedQuantity = resultInventories.fold<int>(
            0, (total, inventory) => total + (inventory.quantity ?? 0));
        if (resultInventories.isEmpty ||
            returnedQuantity != inventoryDepositRequest.quantity ||
            resultInventories.any((inventory) => inventory.lpn != destinationLpn)) {
          _uncertainLpns.add(inventoryDepositRequest.lpn!);
          _uncertainLpns.add(destinationLpn);
          ScanFeedback.current?.uncertain = true;
          throw StateError(
              'Move result could not be verified. Check the original and new LPN before trying again.');
        }
        ScanFeedback.confirmed();
        inventoryDepositRequest.newLpn = destinationLpn;
        inventoryDepositRequest.requestInProcess = false;
        inventoryDepositRequest.requestResult = true;
        inventoryDepositRequest.result = "";
        setState(() {});
        await _reloadInventoryOnRF();
      } catch (err) {
        printLongLogMessage(
            "Move failed for ${inventoryDepositRequest.lpn}, attempt $retryTime/$maxMoveRetries: $err");

        if (ScanFeedback.isUncertain(err)) {
          ScanFeedback.current?.uncertain = true;
          _uncertainLpns.add(inventoryDepositRequest.lpn!);
          _uncertainLpns.add(destinationLpn);
        }

        if (!mounted) return;
        inventoryDepositRequest.requestInProcess = false;
        inventoryDepositRequest.requestResult = false;
        final message = err is WebAPICallException
            ? err.errMsg()
            : (err is DioException
                ? "Pending confirmation. Check this LPN before submitting again."
                : err.toString());
        inventoryDepositRequest.result =
            "$message, LPN: ${inventoryDepositRequest.lpn}";
        setState(() {});
      }
    });
  }

  Future<void> _reloadInventoryOnRF({int refreshCount = 0}) async {
    if (!mounted || _refreshingRF) return;
    setState(() {
      _refreshingRF = true;
      _rfReady = false;
    });
    try {
      final value = await InventoryService.getInventoryOnCurrentRF();
      if (!mounted) return;
      setState(() {
        inventoryOnRF = value;
        _rfReady = true;
      });
      _timer?.cancel();
      if (refreshCount > 0)
        _timer = Timer(const Duration(seconds: 2),
            () => _reloadInventoryOnRF(refreshCount: refreshCount - 1));
    } catch (_) {
      if (mounted)
        setState(() {
          _pageError =
              'Could not refresh inventory on this device. Reopen this page before Deposit; do not repeat a successful move.';
        });
    } finally {
      if (mounted)
        setState(() {
          _refreshingRF = false;
        });
    }
  }
}
