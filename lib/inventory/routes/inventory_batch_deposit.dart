import 'dart:async';
import 'dart:math';

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/services/inventory.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:collection/collection.dart';

import '../../exception/WebAPICallException.dart';
import '../../shared/global.dart';
import '../models/inventory_batch_deposit_sort_by_criteria.dart';

// Page to allow the user scan in an LPN and start the put away process
// The LPN can be in receiving stage / storage location / etc
// with or without any pre-assigned destination
class InventoryBatchDepositPage extends StatefulWidget {
  InventoryBatchDepositPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _InventoryBatchDepositPageState();
}

class _InventoryBatchDepositPageState extends State<InventoryBatchDepositPage> {
  // Limit client-side concurrency so Deposit All does not exhaust the
  // server's database connection pool.
  static const int _maxConcurrentDeposits = 4;
  final _destinationLocationFieldController = TextEditingController();

  List<Inventory> inventoryOnRF = [];

  // key: LPN
  // Value: inventory deposit request
  Map<String, InventoryDepositRequest> _inventoryDepositRequests = new Map();
  // key: LPN
  // Value: selected or not
  Map<String, bool> _selectedLPNMap = new Map();

  InventoryBatchDepositSortByCriteria? _selectedSortByCriteria;

  Timer? _timer; // timer to refresh inventory on RF every 2 second

  @override
  void initState() {
    super.initState();

    inventoryOnRF = [];
    _inventoryDepositRequests = new Map();
    _selectedLPNMap = new Map();

    _selectedSortByCriteria = InventoryBatchDepositSortByCriteria.LPN;

    _reloadInventoryOnRF();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              "Claytech One ${CWMSLocalizations.of(context).batchDepositInventory}")),
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _buildTopSelection(context),
            _buildSortByCriteria(context),
            _buildDepositRequestList(context)
          ],
        ),
      ),
      endDrawer: MyDrawer(),
    );
  }

  // build the top selection
  // 1. deposit all
  // 2. deposit selected LPN
  // 3. sort by criteria
  Widget _buildTopSelection(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        //交叉轴的布局方式，对于column来说就是水平方向的布局方式
        crossAxisAlignment: CrossAxisAlignment.center,
        //就是字child的垂直布局方向，向上还是向下
        verticalDirection: VerticalDirection.down,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.45,
            child: _buildDepositAllButton(context),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.45,
            child: _buildDepositSelectedLPNButton(context),
          ),
        ]);
  }

  Widget _buildDepositAllButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      onPressed: _isThereAvailableInventoryForDeposit() ? _depositAll : null,
      child: Text("Deposit All"),
    );
  }

  Widget _buildDepositSelectedLPNButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      onPressed:
          _isThereAvailableInventoryForDeposit() ? _depositSelectedLPN : null,
      child: Text("Deposit Selected LPN"),
    );
  }

  Widget _buildSortByCriteria(BuildContext context) {
    return buildTwoSectionInputRow(
        "Sort By",
        DropdownButton(
          // hint: Text(CWMSLocalizations.of(context)!.pleaseSelect),
          items: _getSortByCriteriaItems(),
          value: _selectedSortByCriteria,
          elevation: 1,
          isExpanded: true,
          icon: Icon(
            Icons.list,
            size: 20,
          ),
          onChanged: (InventoryBatchDepositSortByCriteria? value) {
            //下拉菜单item点击之后的回调
            setState(() {
              _selectedSortByCriteria = value;
            });
          },
        ));
  }

  List<DropdownMenuItem<InventoryBatchDepositSortByCriteria>>
      _getSortByCriteriaItems() {
    return InventoryBatchDepositSortByCriteria.values
        .map((e) => DropdownMenuItem(
              value: e,
              child: Text(e.name),
            ))
        .toList();
  }

  Future<void> _depositAll() async {
    printLongLogMessage("start to deposit all LPNs that is still on the RF");
    List<InventoryDepositRequest> nonProcessedInventoryDepositRequest =
        _getAllNonProcessedInventoryDepositRequests();

    if (nonProcessedInventoryDepositRequest.isEmpty) {
      showErrorToast("No more inventory to be deposit");
      return;
    }

    await _deposit(nonProcessedInventoryDepositRequest);

    // clear the selection
    _selectedLPNMap.clear();
  }

  Future<void> _depositSelectedLPN() async {
    printLongLogMessage(
        "start to deposit selected LPNs that is still on the RF");
    List<InventoryDepositRequest> selectedInventoryDepositRequest =
        _getSelectedInventoryDepositRequests();

    if (selectedInventoryDepositRequest.isEmpty) {
      showErrorToast("No LPN is selected");
      return;
    }

    await _deposit(selectedInventoryDepositRequest);

    // clear the selection
    _selectedLPNMap.clear();
  }

  Future<void> _deposit(
      List<InventoryDepositRequest> inventoryDepositRequests) async {
    final batchPerf = Stopwatch()..start();
    printLongLogMessage(
        "[PERF] batch deposit start requests=${inventoryDepositRequests.length}");
    List<InventoryDepositRequest> _inventoryDepositRequestWithoutDestination =
        _getInventoryDepositRequestWithoutDestination(inventoryDepositRequests);

    if (_inventoryDepositRequestWithoutDestination.isNotEmpty) {
      printLongLogMessage(
          "we will pop up a dialog and ask the user to input a destination");
      var destinationLocation = await _showDestinationLocationDialog(context);
      printLongLogMessage(
          "[PERF] batch deposit destination dialog ${batchPerf.elapsedMilliseconds}ms");
      if (destinationLocation == null) {
        showErrorToast(
            "No destination location is provided, deposit cancelled");
        return;
      } else {
        // we got the location, for any inventory that doesn't have any destination location, let's deposit to this destination
        await _processDepositRequests(
          _inventoryDepositRequestWithoutDestination,
          (request) => _depositInventoryToDestinationLocation(
              request, destinationLocation),
        );
      }
    }

    // start to deposit any inventory that already have a destination
    final designatedRequests = inventoryDepositRequests
        .where((inventoryDepositRequest) =>
            !_inventoryDepositRequestWithoutDestination.any(
                (inventoryDepositRequestWithoutDestination) =>
                    inventoryDepositRequestWithoutDestination.lpn ==
                    inventoryDepositRequest.lpn))
        .toList();
    await _processDepositRequests(designatedRequests, (request) {
      printLongLogMessage(
          "start to deposit lpn ${request.lpn} to its designated destination ${request.nextLocationName}");
      return _depositInventory(request);
    });
    printLongLogMessage(
        "[PERF] batch deposit complete ${batchPerf.elapsedMilliseconds}ms "
        "requests=${inventoryDepositRequests.length}");
  }

  Future<void> _processDepositRequests(
      List<InventoryDepositRequest> requests,
      Future<Tuple2<bool, String>> Function(InventoryDepositRequest)
          worker) async {
    for (var start = 0;
        start < requests.length;
        start += _maxConcurrentDeposits) {
      final end = min(start + _maxConcurrentDeposits, requests.length);
      final batch = requests.sublist(start, end);
      printLongLogMessage(
          "[PERF] batch deposit client window ${start + 1}-$end/${requests.length}");
      await Future.wait(batch.map((request) async {
        if (!mounted) return;
        setState(() {
          request.requestInProcess = true;
          request.requestResult = false;
          request.result = "";
        });
        final result = await worker(request);
        if (!mounted) return;
        setState(() {
          request.requestInProcess = false;
          request.requestResult = result.item1;
          request.result = result.item2;
        });
      }));
    }
  }

  Widget _buildDepositRequestList(BuildContext context) {
    return Expanded(
        child: ListView.separated(
      itemCount: _inventoryDepositRequests.keys.length,
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
    String key = _inventoryDepositRequests.keys.elementAt(index);

    // printLongLogMessage("_inventoryDepositRequests[key].requestInProcess: ${_inventoryDepositRequests[key]!.requestInProcess}");
    // printLongLogMessage("_inventoryDepositRequests[key].requestResult: ${_inventoryDepositRequests[key]!.requestResult}");
    if (_inventoryDepositRequests[key]!.requestInProcess == true) {
      // show loading indicator if the inventory still reverse in progress
      printLongLogMessage(
          "show loading for index $index / ${_inventoryDepositRequests[key]!.lpn!}");
      return SizedBox(
          height: 90,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand, //未定位widget占满Stack整个空间
            children: <Widget>[
              ListTile(
                title: Text(CWMSLocalizations.of(context).lpn +
                    ": " +
                    _inventoryDepositRequests[key]!.lpn!),
                subtitle: Column(children: <Widget>[
                  Row(children: <Widget>[
                    Text(CWMSLocalizations.of(context).item + ": ",
                        textScaleFactor: .9,
                        style: TextStyle(
                          height: 1.15,
                          color: Colors.blueGrey[700],
                          fontSize: 17,
                        )),
                    Text(_inventoryDepositRequests[key]!.itemName!,
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
                    Text(_inventoryDepositRequests[key]!.quantity.toString(),
                        textScaleFactor: .9,
                        style: TextStyle(
                          height: 1.15,
                          color: Colors.blueGrey[700],
                          fontSize: 17,
                        )),
                  ]),
                  Row(children: <Widget>[
                    Text(CWMSLocalizations.of(context).location + ": ",
                        textScaleFactor: .9,
                        style: TextStyle(
                          height: 1.15,
                          color: Colors.blueGrey[700],
                          fontSize: 17,
                        )),
                    Text(_inventoryDepositRequests[key]!.currentLocationName!,
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
    } else if (_inventoryDepositRequests[key]!.requestResult == true) {
      return SizedBox(
          height: 90,
          child: ListTile(
            title: Text(CWMSLocalizations.of(context).lpn +
                ": " +
                _inventoryDepositRequests[key]!.lpn!),
            subtitle: Column(children: <Widget>[
              Row(children: <Widget>[
                Text(CWMSLocalizations.of(context).item + ": ",
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    )),
                Text(_inventoryDepositRequests[key]!.itemName!,
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
                Text(_inventoryDepositRequests[key]!.quantity.toString(),
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    )),
              ]),
              Row(children: <Widget>[
                Text(CWMSLocalizations.of(context).location + ": ",
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    )),
                Text(_inventoryDepositRequests[key]!.currentLocationName!,
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    )),
              ]),
            ]),
            tileColor: Colors.lightGreen,
          ));
    } else {
      double height = min(
          75 + (_inventoryDepositRequests[key]!.result!.length / 50) * 15, 120);
      return SizedBox(
          height: height,
          child: CheckboxListTile(
            title: Text(CWMSLocalizations.of(context).lpn +
                ": " +
                _inventoryDepositRequests[key]!.lpn!),
            subtitle: Column(children: <Widget>[
              Row(children: <Widget>[
                Text(CWMSLocalizations.of(context).item + ": ",
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    )),
                Text(_inventoryDepositRequests[key]!.itemName!,
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
                Text(_inventoryDepositRequests[key]!.quantity.toString(),
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    )),
              ]),
              Row(children: <Widget>[
                Text(CWMSLocalizations.of(context).location + ": ",
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    )),
                Text(_inventoryDepositRequests[key]!.currentLocationName!,
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    )),
                Padding(
                  padding: const EdgeInsets.only(left: 26.0),
                  child: Text(CWMSLocalizations.of(context).nextLocation + ": ",
                      textScaleFactor: .9,
                      style: TextStyle(
                        height: 1.15,
                        color: Colors.blueGrey[700],
                        fontSize: 17,
                      )),
                ),
                Text(_inventoryDepositRequests[key]!.nextLocationName!,
                    textScaleFactor: .9,
                    style: TextStyle(
                      height: 1.15,
                      color: Colors.blueGrey[700],
                      fontSize: 17,
                    )),
              ]),
            ]),
            value:
                _selectedLPNMap.containsKey(key) ? _selectedLPNMap[key] : false,
            onChanged: (bool? selected) {
              setState(() {
                _selectedLPNMap[key] = selected ?? false;
              });
            },
            tileColor: Colors.white,
          ));
    }
  }

  @override
  void dispose() {
    super.dispose();
    // remove any timer so we won't need to load the next work again after
    // the user return from this page
    _timer?.cancel();
  }

  void _reloadInventoryOnRF({int refreshCount = 0}) {
    InventoryService.getInventoryOnCurrentRF().then((inventoryList) async {
      // load location information

      WarehouseLocation rfLocation =
          await WarehouseLocationService.getWarehouseLocationByName(
              Global.getLastLoginRFCode());

      inventoryList.forEach((inventory) async {
        inventory.location = rfLocation;
        if (inventory.inventoryMovements.isNotEmpty &&
            inventory.inventoryMovements[0].locationId != null &&
            inventory.inventoryMovements[0].location == null) {
          WarehouseLocation nextLocation =
              await WarehouseLocationService.getWarehouseLocationById(
                  inventory.inventoryMovements[0].locationId!);
          inventory.inventoryMovements[0].location = nextLocation;
        }
      });

      setState(() {
        inventoryOnRF = inventoryList;
        // setup the inventory deposit requests
        // so we can display the request list
        _setupInventoryDepositRequest();

        if (refreshCount > 0) {
          _timer = Timer(new Duration(seconds: 2), () {
            this._reloadInventoryOnRF(refreshCount: refreshCount - 1);
          });
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  // setup the inventory deposit request from the inventory on the RF
  void _setupInventoryDepositRequest() {
    _inventoryDepositRequests = new Map();
    _selectedLPNMap = new Map();
    printLongLogMessage("start setup the inventory deposit request");

    printLongLogMessage(
        "we will setup the deposit request from ${inventoryOnRF.length} inventory record");

    inventoryOnRF.forEach((inventory) {
      if (_inventoryDepositRequests.containsKey(inventory.lpn)) {
        InventoryDepositRequest inventoryDepositRequest =
            _inventoryDepositRequests[inventory.lpn]!;
        inventoryDepositRequest.addInventory(inventory);
        _inventoryDepositRequests[inventory.lpn!] = inventoryDepositRequest;
      } else {
        _inventoryDepositRequests[inventory.lpn!] =
            InventoryDepositRequest.fromInventory(inventory);
        printLongLogMessage(
            "_inventoryDepositRequests[inventory.lpn].currentLocationName: ${_inventoryDepositRequests[inventory.lpn]!.currentLocationName}");

        printLongLogMessage(
            "_inventoryDepositRequests[inventory.lpn].nextLocationName: ${_inventoryDepositRequests[inventory.lpn]!.nextLocationName}");
        printLongLogMessage(
            "_inventoryDepositRequests[inventory.lpn].itemName: ${_inventoryDepositRequests[inventory.lpn]!.itemName}");
        _selectedLPNMap[inventory.lpn!] = false;
      }
    });

    printLongLogMessage(
        "we get ${_inventoryDepositRequests.keys.length} LPNs and ${_inventoryDepositRequests.values.length} deposit record");
    setState(() {
      _inventoryDepositRequests;
      _selectedLPNMap;
    });
  }

  List<InventoryDepositRequest> _getSelectedInventoryDepositRequests() {
    return _inventoryDepositRequests.entries
        .where((element) =>
            _selectedLPNMap[element.key]! && !isRequestProcessed(element.value))
        .map((e) => e.value)
        .toList();
  }

  List<InventoryDepositRequest> _getAllNonProcessedInventoryDepositRequests() {
    return _inventoryDepositRequests.entries
        .where((element) => !isRequestProcessed(element.value))
        .map((e) => e.value)
        .toList();
  }

  // check if there's still inventory waiting for deposit. If not, then we will disable the deposit buttons.
  bool _isThereAvailableInventoryForDeposit() {
    return _inventoryDepositRequests.entries
        .any((element) => !isRequestProcessed(element.value));
  }

  bool isRequestProcessed(InventoryDepositRequest inventoryDepositRequest) {
    return inventoryDepositRequest.requestInProcess != false ||
        inventoryDepositRequest.requestResult != false ||
        inventoryDepositRequest.result!.isNotEmpty;
  }

  // check if all the inventory deposit request has destination. If not,
  // we will need to prompt a dialog to ask the user to input the destination for those
  // who doesn't have any destination yet
  bool _allInventoryDepositRequestHasDestination(
      List<InventoryDepositRequest> inventoryDepositRequests) {
    return inventoryDepositRequests.every((inventoryDepositRequest) =>
        inventoryDepositRequest.multipleNextLocationFlag == true ||
        inventoryDepositRequest.nextLocation != null);
  }

  List<InventoryDepositRequest> _getInventoryDepositRequestWithoutDestination(
      List<InventoryDepositRequest> inventoryDepositRequests) {
    return inventoryDepositRequests
        .where((inventoryDepositRequest) =>
            inventoryDepositRequest.multipleNextLocationFlag == false &&
            inventoryDepositRequest.nextLocation == null)
        .toList();
  }

  Future<WarehouseLocation?> _showDestinationLocationDialog(
      BuildContext context) async {
    _destinationLocationFieldController.clear();

    return showDialog<WarehouseLocation>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(CWMSLocalizations.of(context).nextLocation),
            content: TextField(
              controller: _destinationLocationFieldController,
            ),
            actions: <Widget>[
              ElevatedButton(
                child: Text(CWMSLocalizations.of(context).cancel),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                  child: Text(CWMSLocalizations.of(context).confirm),
                  onPressed: () async {
                    if (_destinationLocationFieldController.text.isEmpty) {
                      showErrorToast("please fill in the destination location");
                    } else {
                      try {
                        WarehouseLocation destinationLocation =
                            await WarehouseLocationService
                                .getWarehouseLocationByName(
                                    _destinationLocationFieldController.text);
                        Navigator.pop(context, destinationLocation);
                      } on WebAPICallException catch (ex) {
                        showErrorToast(ex.errMsg());
                      }
                    }
                  }),
            ],
          );
        });
  }

  Future<Tuple2<bool, String>> _depositInventoryToDestinationLocation(
      InventoryDepositRequest inventoryDepositRequest,
      WarehouseLocation destinationLocation) async {
    final requestPerf = Stopwatch()..start();
    for (int i = 0; i < inventoryDepositRequest.inventoryIdList.length; i++) {
      int inventoryId = inventoryDepositRequest.inventoryIdList.elementAt(i);

      final movePerf = Stopwatch()..start();
      final moveResult = await _moveInventoryWithRetry(
          inventoryId: inventoryId, destinationLocation: destinationLocation);
      if (!moveResult.item1) {
        return moveResult;
      }
      inventoryDepositRequest.currentLocationName = destinationLocation.name;
      printLongLogMessage(
          "[PERF] batch move lpn=${inventoryDepositRequest.lpn} inventory=$inventoryId "
          "${movePerf.elapsedMilliseconds}ms");
    }
    printLongLogMessage(
        "[PERF] batch request lpn=${inventoryDepositRequest.lpn} "
        "${requestPerf.elapsedMilliseconds}ms inventories=${inventoryDepositRequest.inventoryIdList.length}");
    return Tuple2<bool, String>(true, "");
  }

  Future<Tuple2<bool, String>> _depositInventory(
      InventoryDepositRequest inventoryDepositRequest) async {
    for (int i = 0; i < inventoryDepositRequest.inventoryIdList.length; i++) {
      int inventoryId = inventoryDepositRequest.inventoryIdList.elementAt(i);
      // we will need to get the destination for the inventory from the inventory itself
      // if there're multiple destination for this LPN
      if (inventoryDepositRequest.multipleNextLocationFlag == true) {
        inventoryDepositRequest.currentLocationName =
            "=== Multiple Locations ===";
        Inventory? inventory = inventoryOnRF
            .firstWhereOrNull((inventory) => inventory.id == inventoryId);
        if (inventory != null && inventory.inventoryMovements.isNotEmpty) {
          final moveResult = await _moveInventoryWithRetry(
              inventoryId: inventoryId,
              destinationLocation: inventory.inventoryMovements[0].location!);
          if (!moveResult.item1) {
            return moveResult;
          }
        }
      } else {
        final moveResult = await _moveInventoryWithRetry(
            inventoryId: inventoryId,
            destinationLocation: inventoryDepositRequest.nextLocation!);
        if (!moveResult.item1) {
          return moveResult;
        }
        inventoryDepositRequest.currentLocationName =
            inventoryDepositRequest.nextLocation!.name;
      }
    }
    return Tuple2<bool, String>(true, "");
  }

  Future<Tuple2<bool, String>> _moveInventoryWithRetry({
    required int inventoryId,
    required WarehouseLocation destinationLocation,
  }) async {
    const maxRetries = 2;
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        await InventoryService.moveInventory(
          inventoryId: inventoryId,
          destinationLocation: destinationLocation,
        );
        return Tuple2<bool, String>(true, "");
      } on WebAPICallException catch (ex) {
        final message = ex.errMsg();
        final isTransientDatabaseError = message.contains('EntityManager') ||
            message.contains('Could not open') ||
            message.contains('connection pool');
        if (!isTransientDatabaseError || attempt == maxRetries) {
          return Tuple2<bool, String>(false, message);
        }
        final delay = Duration(milliseconds: 500 * (attempt + 1));
        printLongLogMessage(
            "[PERF] retry move inventory=$inventoryId attempt=${attempt + 1} "
            "after ${delay.inMilliseconds}ms");
        await Future.delayed(delay);
      }
    }
    return const Tuple2<bool, String>(false, 'Move failed');
  }
}
