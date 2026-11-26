import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../shared/global.dart';
import '../../shared/http_client.dart';
import '../models/wave.dart';
import '../models/remaining_pallet_demand.dart';
import '../../inventory/models/item.dart';
import '../../shared/workspace_ui.dart';
import '../../inventory/services/item.dart';
import '../../inventory/services/inventory.dart';
import '../../warehouse_layout/services/warehouse_location.dart';

class ReserveWaveApi {
  ReserveWaveApi(this.waveId);

  final int waveId;
  final _warehouse = Global.currentWarehouse!.id;
  final _http = CWMSHttpClient.getDio();

  static bool get available =>
      Uri.tryParse(Global.currentServer?.url ?? '')?.port == 4200 ||
      const {'colton-injection', 'fay-injection', 'fay-recycle'}
          .contains(Global.currentFactory?.id);

  Future<Map<String, dynamic>?> lookup() async {
    try {
      return await call('');
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> call(
    String action, {
    Map<String, dynamic> params = const {},
    Map<String, dynamic>? body,
  }) async {
    final response = await _http.request<dynamic>(
      'outbound/wave-reserve/$waveId$action',
      queryParameters: {'warehouseId': _warehouse, ...params},
      data: body,
      options: Options(
        method: body == null ? 'GET' : 'POST',
        receiveTimeout: const Duration(seconds: 35),
      ),
    );
    final envelope = Map<String, dynamic>.from(response.data as Map);
    if (envelope['result'] != 0) {
      throw StateError(
          envelope['message']?.toString() ?? 'Wave request failed');
    }
    return Map<String, dynamic>.from(envelope['data'] as Map);
  }

  Future<List<Map<String, dynamic>>> pickedInventory() async {
    Future<List<Map<String, dynamic>>> read(
        String path, Map<String, dynamic> params) async {
      final response = await _http.get<Map<String, dynamic>>(
        path,
        queryParameters: {'warehouseId': _warehouse, ...params},
        options: Options(receiveTimeout: const Duration(seconds: 20)),
      );
      final envelope = response.data;
      if (envelope?['result'] != 0 || envelope?['data'] is! List) {
        throw StateError('Could not load current picked inventory.');
      }
      return (envelope!['data'] as List).cast<Map<String, dynamic>>();
    }

    final picks = await read('outbound/picks', {'waveId': waveId});
    final byId = {
      for (final pick in picks)
        if (pick['id'] is int) pick['id']: pick,
    };
    if (byId.isEmpty) return [];
    final inventory = await read('inventory/inventories', {
      'pickIds': byId.keys.join(','),
      'includeVirturalInventory': true,
    });
    return [
      for (final row in inventory)
        if (byId.containsKey(row['pickId']) &&
            row['lpn'] is String &&
            row['quantity'] is num &&
            (row['quantity'] as num) > 0)
          {...row, 'wavePick': byId[row['pickId']]},
    ];
  }

  static String error(Object error) {
    if (error is StateError) return error.message.toString();
    if (error is DioException && error.response?.data is Map) {
      return (error.response!.data as Map)['message']?.toString() ??
          'Wave request failed.';
    }
    return 'Unable to verify the Wave request. Check the connection and retry.';
  }
}

class ReserveWavePickPage extends StatefulWidget {
  const ReserveWavePickPage(
      {super.key, required this.wave, required this.data});

  final Wave wave;
  final Map<String, dynamic> data;

  @override
  State<ReserveWavePickPage> createState() => _ReserveWavePickPageState();
}

class _ReserveWavePickPageState extends State<ReserveWavePickPage> {
  final _source = TextEditingController();
  final _splitLabel = TextEditingController();
  final _splitFocus = FocusNode();
  final _scannedLabels = <String>[];
  int _splitStep = 0;
  int _splitRemainder = 0;
  String? _splitError;
  List<Map<String, dynamic>> get _labelSteps =>
      _planned.where(_needsLabel).toList();
  int get _labelCount => _labelSteps.length + (_splitRemainder > 0 ? 1 : 0);
  final _sourceFocus = FocusNode();
  late final _api = ReserveWaveApi(widget.wave.id!);
  late final _key = 'wave-pick:${Global.currentServer?.url}:'
      '${Global.currentWarehouse?.id}:${Global.currentUser?.username}:'
      '${widget.wave.id}';
  late var _data = widget.data;
  SharedPreferences? _prefs;
  Map<String, dynamic>? _pending;
  final _planned = <Map<String, dynamic>>[];
  final _completed = <Map<String, dynamic>>[];
  List<Map<String, dynamic>>? _pickedInventory;
  final _items = <int, Item>{};
  final _stageNames = <int, String>{};
  int? _item;
  bool _needsRefresh = false;
  int _refreshVersion = 0;
  List<Map> get _lines => (_data['lines'] as List? ?? []).cast<Map>();
  List<Map> get _saved => (_data['pendingScans'] as List? ?? []).cast<Map>();
  int _itemId(Map line) => (line['item_id'] as num).toInt();
  String? _message;
  bool _busy = false;
  static const _timeWholePallet = bool.fromEnvironment('WAVE_SCAN_TIMING');

  @override
  void initState() {
    super.initState();
    _run(() async {
      _prefs = await SharedPreferences.getInstance();
      final saved = _prefs!.getString(_key);
      if (saved != null) {
        final decoded = Map<String, dynamic>.from(jsonDecode(saved));
        _pending = decoded.containsKey('steps')
            ? decoded
            : {
                'steps': [decoded]
              };
      }
      final completed =
          jsonDecode(_prefs!.getString('$_key:completed') ?? '[]') as List;
      _completed.addAll(completed.cast<Map<String, dynamic>>());
      await Future.wait([_loadItems(), _syncPickedInventory()]);
    });
  }

  Future<void> _run(Future<void> Function() task) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await task();
    } catch (error) {
      _message = ReserveWaveApi.error(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _requestId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<void> _loadItems() async {
    await Future.wait(_lines
        .map(_itemId)
        .toSet()
        .where((id) => !_items.containsKey(id))
        .map((id) async {
      try {
        _items[id] = await ItemService.getItemById(id);
      } catch (_) {
        // The item ID still identifies this SKU if the name lookup fails.
      }
    }));
  }

  Future<void> _syncPickedInventory() async {
    _pickedInventory = null;
    try {
      _pickedInventory = await _api.pickedInventory();
    } catch (_) {
      // Keep the local receipts for recovery. A failed read cannot verify them.
    }
  }

  Future<void> _refresh({Set<int> destinations = const {}}) async {
    final version = ++_refreshVersion;
    final results = await Future.wait([
      _api.call(''),
      _api.pickedInventory().then<List<Map<String, dynamic>>?>(
            (rows) => rows,
            onError: (Object _) => null,
          ),
      for (final id in destinations) _loadStageName(id),
    ]);
    if (!mounted || version != _refreshVersion) return;
    setState(() {
      _data = results[0] as Map<String, dynamic>;
      _pickedInventory = results[1] as List<Map<String, dynamic>>?;
      _needsRefresh = false;
    });
    await _loadItems();
    if (mounted && version == _refreshVersion) setState(() {});
  }

  Future<void> _refreshAfterWholePallet(Set<int> destinations) async {
    final version = _refreshVersion + 1;
    try {
      await _refresh(destinations: destinations);
    } catch (_) {
      if (!mounted || version != _refreshVersion || _busy) return;
      setState(() => _message = 'Pick completed. Refresh Wave to sync.');
    }
  }

  Future<void> _loadStageName(int id) async {
    if (_stageNames.containsKey(id)) return;
    try {
      final location =
          await WarehouseLocationService.getWarehouseLocationById(id);
      final name = location.name;
      if (name != null && name.isNotEmpty) _stageNames[id] = name;
    } catch (_) {
      // The inventory row still carries the location ID.
    }
  }

  Widget _pickedTile(Map<String, dynamic> row) {
    final pick = row['wavePick'] as Map;
    final lineId = pick['shipmentLineId'] ?? row['shipmentLineId'];
    final shipments = _lines.where(
      (line) => line['shipment_line_id'] == lineId,
    );
    final receipts = _completed.where((receipt) =>
        receipt['lpn'] == row['lpn'] &&
        (receipt['pickId'] == row['pickId'] || receipt['pickId'] == null));
    final receiptShipments =
        receipts.map((receipt) => receipt['shipment']).toSet();
    final shipment = shipments.isNotEmpty
        ? shipments.first['shipment_number']
        : pick['shipmentNumber'] ??
            (receiptShipments.length == 1
                ? receiptShipments.single
                : 'Pick ${pick['number'] ?? row['pickId']}');
    final location = row['location'];
    final stage = row['locationName'] ??
        (location is Map ? location['name'] : null) ??
        _stageNames[row['locationId']] ??
        (row['locationId'] != null ? 'Location #${row['locationId']}' : null);
    const confirmedGreen = Color(0xFF237A45);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: confirmedGreen),
        ),
        tileColor: const Color(0xFFF0FAF3),
        textColor: const Color(0xFF17472C),
        leading: const Icon(Icons.check_circle_outline, color: confirmedGreen),
        title: Text(
          '$shipment · ${row['quantity']} units',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('LPN ${row['lpn']}${stage == null ? '' : ' → $stage'}'),
      ),
    );
  }

  void _clearPlan() {
    _planned.clear();
    _scannedLabels.clear();
    _splitStep = 0;
    _splitRemainder = 0;
    _splitError = null;
    _splitLabel.clear();
  }

  void _inspect() {
    final lpn = _source.text.trim();
    final item = _item;
    if (item == null ||
        lpn.isEmpty ||
        _needsRefresh ||
        _prefs == null ||
        _pending != null ||
        _saved.isNotEmpty) {
      return;
    }
    final timer = _timeWholePallet ? (Stopwatch()..start()) : null;
    _run(() async {
      _clearPlan();
      final steps = <Map<String, dynamic>>[];
      final unitsPerPallet = RemainingPalletDemand.forItem(
        _items[item],
        0,
        fallbackName: 'Item #$item',
      ).unitsPerPallet;
      int? remaining;
      int? sourceQuantity;
      String? rejection;
      final candidates = _lines
          .where((line) =>
              _itemId(line) == item && (line['wave_reserved'] as int) > 0)
          .toList();
      final previews = <int, int?>{};

      Future<int?> eligibleQuantity(Map line) async {
        final lineId = line['shipment_line_id'] as int;
        if (previews.containsKey(lineId)) return previews[lineId];
        Map<String, dynamic> preview;
        try {
          preview = await _api.call('/scan-preview', params: {
            'shipmentLineId': lineId,
            'sourceLpn': lpn,
          });
        } on StateError catch (error) {
          rejection = error.message.toString();
          previews[lineId] = null;
          return null;
        }
        final currentQuantity = preview['sourceQuantity'] as int;
        sourceQuantity ??= currentQuantity;
        if (currentQuantity != sourceQuantity) {
          throw StateError(
              'Pallet quantity changed during preview. Scan again.');
        }
        final eligible = min(
            preview['pickableQuantity'] as int, line['wave_reserved'] as int);
        previews[lineId] = eligible;
        return eligible;
      }

      Map<String, dynamic> pickStep(Map line, int qty, int expectedQuantity) =>
          {
            'requestId': _requestId(),
            'shipmentLineId': line['shipment_line_id'],
            'shipment': line['shipment_number'],
            'sourceLpn': lpn,
            'destination': '@SHIP_STAGE',
            'keepOriginal': false,
            'quantity': qty,
            'expectedQuantity': expectedQuantity,
          };

      if (unitsPerPallet != null) {
        for (final line in candidates.where(
            (line) => (line['wave_reserved'] as int) >= unitsPerPallet)) {
          final eligible = await eligibleQuantity(line);
          if (sourceQuantity != null && sourceQuantity != unitsPerPallet) {
            break;
          }
          if (eligible != null && eligible >= unitsPerPallet) {
            if (!mounted) return;
            final previewMs = timer?.elapsedMilliseconds;
            await _persist([
              {...pickStep(line, unitsPerPallet, unitsPerPallet), 'newLpn': ''},
            ]);
            final savedMs = timer?.elapsedMilliseconds;
            await _finish(
              wholePallet: true,
              onTiming: timer == null
                  ? null
                  : (confirmedMs, readyMs) => debugPrint(
                        'WAVE_SCAN preview=$previewMs saved=$savedMs '
                        'confirmed=$confirmedMs ready=$readyMs',
                      ),
              timer: timer,
            );
            return;
          }
        }
      }

      for (final line in candidates) {
        final eligible = await eligibleQuantity(line);
        if (eligible == null) continue;
        final available = remaining ?? sourceQuantity!;
        final qty = min(available, eligible);
        if (qty <= 0) continue;
        steps.add(pickStep(line, qty, available));
        remaining = available - qty;
        if (remaining == 0) break;
      }
      if (steps.isEmpty) {
        throw StateError(rejection ??
            'No quantity can be picked from this pallet for the selected SKU.');
      }
      if (!mounted) return;
      _planned.addAll(steps);
      _splitRemainder = remaining ?? 0;
      if (_labelCount > 0) _focusSplitLabel();
    });
  }

  bool _needsLabel(Map step) =>
      (step['quantity'] as int) < (step['expectedQuantity'] as int);

  Future<void> _persist(List<Map<String, dynamic>> steps,
      {Map<String, dynamic>? remainder}) async {
    final request = <String, dynamic>{
      'steps': steps,
      if (remainder != null) 'remainder': remainder,
    };
    if (!await _prefs!.setString(_key, jsonEncode(request))) {
      throw StateError('Could not save the Pick request on this device.');
    }
    _pending = request;
  }

  List<Map<String, dynamic>> get _pendingSteps =>
      (_pending?['steps'] as List? ?? []).cast<Map<String, dynamic>>();

  Map<String, dynamic> _payload(Map<String, dynamic> step) =>
      Map.of(step)..remove('shipment');

  Future<void> _record(
      Map<String, dynamic> step, Map<String, dynamic> result) async {
    if (result['completed'] != true || result['cancelled'] == true) {
      throw StateError(
          'Pick completion was not verified. Resume this request.');
    }
    final id = step['requestId'];
    if (_completed.any((row) => row['requestId'] == id)) return;
    final lineId = step['shipmentLineId'];
    final matching = _lines.where((line) => line['shipment_line_id'] == lineId);
    final row = {
      'requestId': id,
      'pickId': result['pickId'],
      'shipment': step['shipment'] ??
          (matching.isEmpty
              ? 'Shipment Line #$lineId'
              : matching.first['shipment_number']),
      'quantity': step['quantity'],
      'lpn': _needsLabel(step) && step['keepOriginal'] == false
          ? step['newLpn']
          : step['sourceLpn'],
    };
    final completed = [..._completed, row];
    if (!await _prefs!.setString('$_key:completed', jsonEncode(completed))) {
      throw StateError(
          'Could not save the shipment confirmation. Resume safely.');
    }
    _completed.add(row);
  }

  Future<void> _finish({
    bool wholePallet = false,
    Stopwatch? timer,
    void Function(int, int)? onTiming,
  }) async {
    ++_refreshVersion;
    final confirmedSteps = <Map<String, dynamic>>[];
    final destinations = <int>{};
    var confirmedMs = 0;
    final remainder = (_pending?['remainder'] as Map?)?.cast<String, dynamic>();
    while (_pendingSteps.isNotEmpty) {
      final steps = _pendingSteps;
      final step = steps.first;
      final result = await _api.call('/scan', body: _payload(step));
      confirmedMs = timer?.elapsedMilliseconds ?? 0;
      await _record(step, result);
      confirmedSteps.add(step);
      final destination = result['destinationId'];
      if (destination is int) destinations.add(destination);
      if (steps.length == 1 && remainder == null) {
        await _clearPending();
      } else {
        await _persist(steps.sublist(1), remainder: remainder);
      }
    }
    if (remainder != null) {
      await _relabelRemainder(remainder);
      await _clearPending();
    }
    _clearPlan();
    _source.clear();
    if (wholePallet) {
      final step = confirmedSteps.single;
      _data = {
        ..._data,
        'lines': [
          for (final line in _lines)
            if (line['shipment_line_id'] == step['shipmentLineId'])
              {
                ...line,
                'wave_reserved': max(0,
                    (line['wave_reserved'] as int) - (step['quantity'] as int)),
              }
            else
              line,
        ],
      };
    } else {
      _needsRefresh = true;
      if (mounted) setState(() => _message = 'Pick confirmed. Updating Wave…');
      await _refresh(destinations: destinations);
    }
    _message = remainder == null
        ? 'Pick completed.'
        : 'Pick completed. Remaining stock: ${remainder['quantity']} units on ${remainder['newLpn']}.';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _busy) return;
      _sourceFocus.requestFocus();
      if (timer != null) onTiming?.call(confirmedMs, timer.elapsedMilliseconds);
      if (wholePallet) unawaited(_refreshAfterWholePallet(destinations));
    });
  }

  Future<void> _clearPending() async {
    if (!await _prefs!.remove(_key)) {
      throw StateError('Could not clear the saved Pick request. Retry safely.');
    }
    _pending = null;
  }

  void _focusSplitLabel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _planned.isNotEmpty && _splitStep < _labelCount) {
        _splitFocus.requestFocus();
      }
    });
  }

  void _editSplitLabel(int index) {
    setState(() {
      _splitStep = index;
      _splitError = null;
      _splitLabel.text =
          index < _scannedLabels.length ? _scannedLabels[index] : '';
    });
    _focusSplitLabel();
  }

  void _acceptSplitLabel(String text) {
    if (_busy || _splitStep >= _labelCount) return;
    final label = text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z][A-Z0-9]{7,11}$').hasMatch(label) ||
        label.startsWith('DE')) {
      setState(() => _splitError = 'Scan a valid preprinted LPN.');
      return;
    }
    if (label == _source.text.trim().toUpperCase() ||
        _scannedLabels
            .asMap()
            .entries
            .any((entry) => entry.key != _splitStep && entry.value == label)) {
      setState(() => _splitError = 'Use a different new LPN.');
      return;
    }
    _run(() async {
      final inventory = await InventoryService.findInventory(lpn: label);
      if (!mounted) return;
      if (inventory.isNotEmpty) {
        _splitError = 'This LPN is already in use.';
        return;
      }
      if (_splitStep == _scannedLabels.length) {
        _scannedLabels.add(label);
      } else {
        _scannedLabels[_splitStep] = label;
      }
      _editSplitLabel(_splitStep + 1);
    });
  }

  Future<void> _relabelRemainder(Map<String, dynamic> remainder) async {
    final source = remainder['sourceLpn'] as String;
    final label = remainder['newLpn'] as String;
    final quantity = remainder['quantity'] as int;
    final locationId = remainder['locationId'] as int;
    final inventoryId = remainder['inventoryId'] as int?;
    if (inventoryId == null) {
      final inventory = await InventoryService.findInventory(lpn: source);
      if (inventory.length != 1 ||
          inventory.single.id == null ||
          inventory.single.quantity != quantity ||
          inventory.single.item?.id != remainder['itemId'] ||
          inventory.single.pickId != null ||
          inventory.single.locationId != locationId) {
        throw StateError(
            'Remaining inventory has changed. Check the original pallet before resuming.');
      }
      remainder = {...remainder, 'inventoryId': inventory.single.id};
      await _persist([], remainder: remainder);
    }
    final id = remainder['inventoryId'] as int;
    final current = await InventoryService.getInventoryById(id);
    if (current.quantity != quantity ||
        current.item?.id != remainder['itemId'] ||
        current.pickId != null ||
        current.locationId != locationId ||
        (current.lpn != source && current.lpn != label)) {
      throw StateError(
          'Remaining inventory has changed. Check the pallet before resuming.');
    }
    if (current.lpn == label) return;
    final updated = await InventoryService.relabelInventory(
      id,
      label,
      mergeWithExistingInventory: false,
    );
    if (updated.id != id ||
        updated.lpn != label ||
        updated.quantity != quantity) {
      throw StateError('Could not verify the new LPN for the remaining stock.');
    }
  }

  void _confirm() {
    if (_pending == null &&
        (_planned.isEmpty ||
            _splitStep != _labelCount ||
            _scannedLabels.length != _labelCount)) return;
    _run(() async {
      if (_pending == null) {
        var index = 0;
        final steps = [
          for (final step in _planned)
            {
              ...step,
              'newLpn': _needsLabel(step) ? _scannedLabels[index++] : ''
            },
        ];
        Map<String, dynamic>? remainder;
        if (_splitRemainder > 0) {
          final source = _source.text.trim();
          final inventory = await InventoryService.findInventory(lpn: source);
          if (inventory.length != 1 ||
              inventory.single.quantity != _planned.first['expectedQuantity'] ||
              inventory.single.item?.id != _item ||
              inventory.single.pickId != null ||
              inventory.single.locationId == null) {
            throw StateError(
                'The original pallet has changed or contains multiple inventory records. Scan it again.');
          }
          remainder = {
            'sourceLpn': source,
            'newLpn': _scannedLabels.last,
            'quantity': _splitRemainder,
            'itemId': _item,
            'locationId': inventory.single.locationId,
          };
        }
        await _persist(steps, remainder: remainder);
      }
      await _finish();
    });
  }

  void _resume(Map saved) {
    _run(() async {
      await _persist([
        {
          'requestId': saved['request_id'],
          'shipmentLineId': saved['shipment_line_id'],
          'sourceLpn': saved['source_lpn'],
          'newLpn': saved['new_lpn'] ?? '',
          'destination': '@SHIP_STAGE',
          'keepOriginal':
              saved['keep_original'] == true || saved['keep_original'] == 1,
          'quantity': saved['quantity'],
          'expectedQuantity': saved['source_quantity'],
        }
      ]);
      await _finish();
    });
  }

  void _cancelPending() {
    _run(() async {
      final step = _pendingSteps.first;
      final result = await _api.call('/scan-cancel', params: {
        'shipmentLineId': step['shipmentLineId'],
        'requestId': step['requestId'],
      }, body: {});
      if (result['cancelled'] != true && result['completed'] != true) {
        throw StateError('Pick preparation started. Resume the saved request.');
      }
      // A completed request may have lost its response. Recover its receipt.
      if (result['completed'] == true) {
        final receipt = await _api.call('/scan', body: _payload(step));
        await _record(step, receipt);
      }
      await _clearPending();
      _clearPlan();
      _source.clear();
      _needsRefresh = true;
      await _refresh();
    });
  }

  @override
  void dispose() {
    _clearPlan();
    _source.dispose();
    _splitLabel.dispose();
    _splitFocus.dispose();
    _sourceFocus.dispose();
    super.dispose();
  }

  Widget _skuCard(
    int id,
    int quantity, {
    required bool selected,
    required VoidCallback? onTap,
  }) {
    final demand = RemainingPalletDemand.forItem(
      _items[id],
      quantity,
      fallbackName: 'Item #$id',
    );
    final full = demand.fullPallets;
    final loose = demand.looseQuantity;
    final breakdown = full == null || loose == null
        ? 'Pallet size unavailable'
        : [
            if (full > 0) '$full full ${full == 1 ? 'pallet' : 'pallets'}',
            if (loose > 0) '$loose loose ${loose == 1 ? 'unit' : 'units'}',
          ].join(' + ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? workspaceBlue : const Color(0xffdfe6ef),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        selected: selected,
        selectedColor: workspaceNavy,
        leading: Icon(
          selected ? Icons.check_circle_outline : Icons.inventory_2_outlined,
          color: workspaceBlue,
        ),
        title: Text(demand.itemName,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$quantity to pick'),
              Text(breakdown,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (demand.unitsPerPallet != null)
                Text('${demand.unitsPerPallet} units per full pallet'),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = <int, int>{};
    for (final line in _lines) {
      final id = _itemId(line);
      final quantity = line['wave_reserved'] as int;
      if (quantity > 0)
        totals.update(id, (value) => value + quantity,
            ifAbsent: () => quantity);
    }
    final selected = totals.containsKey(_item)
        ? _item
        : totals.length == 1
            ? totals.keys.single
            : null;
    _item = selected;
    final heading = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: workspaceNavy,
          fontWeight: FontWeight.w700,
        );
    final pending = _pendingSteps;
    final saved = _saved;
    final canReturnAfterPicking = !_busy &&
        !_needsRefresh &&
        _pending == null &&
        saved.isEmpty &&
        totals.isEmpty &&
        _data['state'] != 'PLANNED' &&
        (_pickedInventory?.isNotEmpty ?? false);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: workspaceBackground,
        appBar: AppBar(
          backgroundColor: workspaceBackground,
          foregroundColor: workspaceNavy,
          title: Text('Wave ${widget.wave.number}'),
          actions: [
            IconButton(
              tooltip: 'Refresh Wave',
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        _clearPlan();
                        await _refresh();
                      }),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        bottomNavigationBar: canReturnAfterPicking
            ? SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back to Pick by Wave'),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_busy) const LinearProgressIndicator(),
                  if (_message != null) Text(_message!),
                  if (_pending != null) ...[
                    ListTile(
                      title: Text(
                          'Saved Pick · ${pending.isEmpty ? (_pending!['remainder'] as Map)['sourceLpn'] : pending.first['sourceLpn']}'),
                      subtitle: Text(pending.isEmpty
                          ? 'Remaining stock still needs its new LPN.'
                          : '${pending.length} shipment allocation(s) to verify'),
                    ),
                    FilledButton(
                      onPressed: _busy ? null : _confirm,
                      child: const Text('Resume Pick'),
                    ),
                    if (_pending!['remainder'] == null)
                      TextButton(
                        onPressed: _busy ? null : _cancelPending,
                        child: const Text('Cancel remaining Pick'),
                      ),
                  ] else if (saved.isNotEmpty)
                    for (final scan in saved)
                      ListTile(
                        title: Text('Saved Pick · ${scan['source_lpn']}'),
                        subtitle: Text('${scan['quantity']} units'),
                        trailing: TextButton(
                          onPressed: _busy || _prefs == null
                              ? null
                              : () => _resume(scan),
                          child: const Text('Resume'),
                        ),
                      )
                  else if (_needsRefresh)
                    const Text(
                        'Refresh the Wave before scanning the next pallet.')
                  else if (totals.isEmpty)
                    Text(_data['state'] == 'PLANNED'
                        ? 'Allocate this Wave before picking.'
                        : 'No reserved quantities available to pick.')
                  else ...[
                    Text('Remaining to pick', style: heading),
                    const SizedBox(height: 8),
                    for (final entry in totals.entries)
                      _skuCard(
                        entry.key,
                        entry.value,
                        selected: selected == entry.key,
                        onTap: _busy
                            ? null
                            : () {
                                setState(() {
                                  _item = entry.key;
                                  _clearPlan();
                                  _source.clear();
                                });
                                _sourceFocus.requestFocus();
                              },
                      ),
                    const SizedBox(height: 14),
                    Text('Pallet scan', style: heading),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _source,
                      focusNode: _sourceFocus,
                      enabled: selected != null && _planned.isEmpty,
                      inputFormatters: [
                        TextInputFormatter.withFunction(
                          (previous, next) => _busy ? previous : next,
                        ),
                      ],
                      onChanged: (_) => setState(_clearPlan),
                      onEditingComplete: () {},
                      onSubmitted: (_) => _inspect(),
                      decoration: InputDecoration(
                        labelText: 'Scan pallet LPN',
                        helperText: selected == null
                            ? 'Select a SKU to begin.'
                            : 'Eligible full pallets confirm automatically.',
                        helperMaxLines: 2,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          tooltip: 'Check pallet',
                          onPressed:
                              _busy || selected == null || _planned.isNotEmpty
                                  ? null
                                  : _inspect,
                          icon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    if (_planned.isNotEmpty) ...[
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () {
                                setState(() {
                                  _clearPlan();
                                  _source.clear();
                                });
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (mounted) _sourceFocus.requestFocus();
                                });
                              },
                        child: const Text('Scan another pallet'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Original pallet · ${_planned.first['expectedQuantity']} units',
                        style: heading,
                      ),
                      Text(
                        '${(_planned.first['expectedQuantity'] as int) - _splitRemainder} to ship · $_splitRemainder remaining',
                      ),
                      if (_splitStep < _labelCount) ...[
                        ListTile(
                          title: Text(_splitStep < _labelSteps.length
                              ? '${_labelSteps[_splitStep]['shipment']} · ${_labelSteps[_splitStep]['quantity']} units'
                              : 'Remaining stock · $_splitRemainder units'),
                          subtitle: Text(_splitStep < _labelSteps.length
                              ? 'Step ${_splitStep + 1} of $_labelCount. Separate these units and scan the new label.'
                              : 'Step ${_splitStep + 1} of $_labelCount. Scan the new label for the stock left on the original pallet.'),
                        ),
                        TextField(
                          controller: _splitLabel,
                          focusNode: _splitFocus,
                          enabled: !_busy,
                          onChanged: (_) {
                            if (_splitError != null) {
                              setState(() => _splitError = null);
                            }
                          },
                          onSubmitted: _acceptSplitLabel,
                          decoration: InputDecoration(
                            labelText: _splitStep < _labelSteps.length
                                ? 'Scan new shipment LPN'
                                : 'Scan new remainder LPN',
                            errorText: _splitError,
                            suffixIcon: IconButton(
                              tooltip: 'Use scanned LPN',
                              onPressed: _busy
                                  ? null
                                  : () => _acceptSplitLabel(_splitLabel.text),
                              icon: const RotatedBox(quarterTurns: 2, child: Icon(Icons.arrow_back)),
                            ),
                          ),
                        ),
                        if (_splitStep > 0)
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => _editSplitLabel(_splitStep - 1),
                            child: const Text('Previous label'),
                          ),
                      ] else ...[
                        for (var i = 0, labelIndex = 0;
                            i < _planned.length;
                            i++)
                          ListTile(
                            title: Text(
                                '${_planned[i]['shipment']} · ${_planned[i]['quantity']} units'),
                            subtitle: Text(_needsLabel(_planned[i])
                                ? _scannedLabels[labelIndex++]
                                : 'Original LPN ${_planned[i]['sourceLpn']}'),
                          ),
                        if (_splitRemainder > 0)
                          ListTile(
                            title: Text(
                                'Remaining stock · $_splitRemainder units'),
                            subtitle: Text(_scannedLabels.last),
                          ),
                        if (_labelCount > 0)
                          TextButton(
                            onPressed: _busy ? null : () => _editSplitLabel(0),
                            child: const Text('Edit labels'),
                          ),
                        FilledButton(
                          onPressed: _busy ? null : _confirm,
                          child: const Text('Confirm Pick'),
                        ),
                      ],
                    ],
                  ],
                  if (_pickedInventory?.isNotEmpty == true ||
                      (!_busy && _pickedInventory == null)) ...[
                    const Divider(),
                    Text('Picked by shipment', style: heading),
                    if (_pickedInventory == null)
                      const Text(
                          'Could not verify picked inventory. Refresh Wave to retry.')
                    else
                      for (final row in _pickedInventory!) _pickedTile(row),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
