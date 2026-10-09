import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:cwms_mobile/inventory/models/item.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import '../models/work_order.dart';
import '../models/work_order_status.dart';
import '../models/production_line.dart';
import '../models/production_line_assignment.dart';

bool isActiveDefectiveOrder(WorkOrder order) => const {
      WorkOrderStatus.PENDING,
      WorkOrderStatus.INPROCESS,
      WorkOrderStatus.STAGED,
      WorkOrderStatus.WORK_IN_PROCESS,
    }.contains(order.status);

class DefectiveMachine {
  DefectiveMachine(this.line, this.orders);
  final ProductionLine line;
  final List<WorkOrder> orders;
}

List<DefectiveMachine> groupDefectiveMachines(List<WorkOrder> orders) {
  final grouped = <int, DefectiveMachine>{};
  for (final order in orders) {
    if (!isActiveDefectiveOrder(order) || order.id == null) continue;
    for (final assignment in order.productionLineAssignments) {
      final line = assignment.productionLine;
      if (line?.id == null || (line?.name ?? '').trim().isEmpty) continue;
      final machine =
          grouped.putIfAbsent(line!.id!, () => DefectiveMachine(line, []));
      if (!machine.orders.any((value) => value.id == order.id))
        machine.orders.add(order);
    }
  }
  final machines = grouped.values.toList()
    ..sort((a, b) => (a.line.name ?? '').compareTo(b.line.name ?? ''));
  return machines;
}

class DefectiveMachineService {
  static final _summaryUnavailableUntil = Expando<DateTime>();
  static dynamic _data(dynamic response) {
    final data = response is Response ? response.data : response;
    final value =
        (data is String ? json.decode(data) : data) as Map<String, dynamic>;
    if (value['result'] != 0)
      throw Exception(value['message'] ?? 'Request failed');
    return value['data'];
  }

  static Future<List<WorkOrder>> _assignedOrders(
      {int? lineId, Dio? client, int? warehouseId}) async {
    final timing = Stopwatch()..start();
    client ??= CWMSHttpClient.getDio();
    final query = {
      'warehouseId': warehouseId ?? Global.currentWarehouse!.id,
      if (lineId != null) 'productionLineId': lineId
    };
    Response response;
    var summary = true;
    final unavailableUntil = _summaryUnavailableUntil[client];
    if (unavailableUntil != null && DateTime.now().isBefore(unavailableUntil)) {
      summary = false;
      response = await client.get(
          'workorder/production-line-assignments/assigned-work-orders',
          queryParameters: query);
    } else {
      try {
        response = await client.get(
            'workorder/production-line-assignments/active-machine-summaries',
            queryParameters: query);
      } on DioException catch (error) {
        // Only an absent endpoint triggers compatibility fallback. Authentication,
        // timeout and server failures must remain visible instead of doubling load.
        if (error.response?.statusCode != 404) rethrow;
        _summaryUnavailableUntil[client] =
            DateTime.now().add(const Duration(minutes: 5));
        summary = false;
        response = await client.get(
            'workorder/production-line-assignments/assigned-work-orders',
            queryParameters: query);
      }
    }
    debugPrint(
        '[Defective timing] assigned work orders HTTP: ${timing.elapsedMilliseconds} ms');
    timing.reset();
    if (summary) {
      final byOrder = <int, Map<String, dynamic>>{};
      for (final entry in _data(response) as List) {
        final row = Map<String, dynamic>.from(entry as Map);
        final id = row['workOrderId'] as int;
        final raw = byOrder.putIfAbsent(
            id,
            () => {
                  'id': id,
                  'number': row['workOrderNumber'],
                  'itemId': row['itemId'],
                  'warehouseId': row['warehouseId'],
                  'status': row['status'],
                  'expectedQuantity': row['expectedQuantity'],
                  'producedQuantity': row['producedQuantity'],
                  'productionLineAssignments': <Map<String, dynamic>>[],
                });
        final assignments = raw['productionLineAssignments'] as List;
        if (!assignments
            .any((a) => a['productionLine']['id'] == row['productionLineId'])) {
          assignments.add({
            'productionLine': {
              'id': row['productionLineId'],
              'name': row['productionLineName'],
            }
          });
        }
      }
      final orders = byOrder.values
          .map((raw) {
            final assignments = raw.remove('productionLineAssignments') as List;
            final order = WorkOrder.fromJson(raw);
            order.productionLineAssignments = assignments
                .map((a) => ProductionLineAssignment()
                  ..productionLine = ProductionLine.fromJson(
                      Map<String, dynamic>.from(a['productionLine'])))
                .toList();
            return order;
          })
          .where(isActiveDefectiveOrder)
          .toList();
      debugPrint('[Defective timing] machine summary local decode: '
          '${timing.elapsedMilliseconds} ms; orders=${orders.length}');
      return orders;
    }
    final seen = <int>{};
    final orders = <WorkOrder>[];
    for (final entry in _data(response) as List) {
      final raw = Map<String, dynamic>.from(entry as Map);
      final id = raw['id'];
      if (id is! int || !seen.add(id)) continue;
      if (!const {'PENDING', 'INPROCESS', 'STAGED', 'WORK_IN_PROCESS'}
          .contains(raw['status'])) continue;
      // Discard historical assignments even if an older server includes them.
      raw['productionLineAssignments'] =
          (raw['productionLineAssignments'] as List? ?? [])
              .where((a) => a['deassigned'] != true)
              .toList();
      orders.add(WorkOrder.fromJson(raw));
    }
    debugPrint(
        '[Defective timing] assigned work orders local decode: ${timing.elapsedMilliseconds} ms; orders=${orders.length}');
    return orders;
  }

  static String get _scope =>
      '${Global.currentServer?.url}|${Global.currentWarehouse?.id}|${Global.lastLoginCompanyId}|${Global.currentUser?.username}|${Global.currentUser?.token}';
  static String? _cacheScope;
  static Future<List<DefectiveMachine>>? _inflight;
  static List<DefectiveMachine>? _cached;
  static DateTime? _loadedAt;

  static List<DefectiveMachine>? _partial;
  static final _listeners = <void Function(List<DefectiveMachine>)>[];

  static List<DefectiveMachine> get preview {
    if (_cacheScope != _scope) return [];
    if (_partial != null && _inflight != null) return _partial!;
    if (_cached != null &&
        _loadedAt != null &&
        DateTime.now().difference(_loadedAt!) < const Duration(minutes: 5))
      return _cached!;
    return [];
  }

  static bool get previewIsFresh =>
      _cacheScope == _scope &&
      ((_partial != null && _inflight != null) ||
          (_loadedAt != null &&
              DateTime.now().difference(_loadedAt!) <
                  const Duration(seconds: 30)));

  static Future<List<DefectiveMachine>> load(
      {Dio? client,
      int? warehouseId,
      bool forceRefresh = false,
      void Function(List<DefectiveMachine>)? onProgress}) async {
    if (client != null || warehouseId != null) {
      return _loadSummary(
          client: client, warehouseId: warehouseId, onProgress: onProgress);
    }
    final scope = _scope;
    if (_cacheScope != scope) {
      _cacheScope = scope;
      _cached = null;
      _loadedAt = null;
      _inflight = null;
      _partial = null;
      _listeners.clear();
    }
    if (onProgress != null) _listeners.add(onProgress);
    try {
      if (_inflight != null) return await _inflight!;
      if (!forceRefresh &&
          _cached != null &&
          _loadedAt != null &&
          DateTime.now().difference(_loadedAt!) < const Duration(seconds: 30)) {
        debugPrint('[Defective timing] list: session cache hit');
        return _cached!;
      }
      final request = _loadSummary(onProgress: (machines) {
        if (_cacheScope != scope) return;
        _partial = machines;
        for (final callback in List.of(_listeners)) {
          callback(machines);
        }
      });
      _inflight = request;
      try {
        final machines = await request;
        if (_cacheScope == scope && identical(_inflight, request)) {
          _cached = machines;
          _loadedAt = DateTime.now();
          _partial = null;
        }
        return machines;
      } finally {
        if (identical(_inflight, request)) _inflight = null;
      }
    } finally {
      if (onProgress != null) _listeners.remove(onProgress);
    }
  }

  static Future<void> prefetch() async {
    if (Global.currentWarehouse?.id == null ||
        Global.currentServer?.url == null ||
        Global.currentUser?.token == null) return;
    try {
      await load();
    } catch (_) {/* Opening the page provides retry UI. */}
  }

  static Future<List<DefectiveMachine>> _loadSummary(
      {Dio? client,
      int? warehouseId,
      void Function(List<DefectiveMachine>)? onProgress}) async {
    client ??= CWMSHttpClient.getDio();
    warehouseId ??= Global.currentWarehouse!.id;
    final timer = Stopwatch()..start();
    final machines = groupDefectiveMachines(
        await _assignedOrders(client: client, warehouseId: warehouseId));
    debugPrint(
        '[Defective timing] assignments + decode: ${timer.elapsedMilliseconds} ms');
    onProgress?.call(machines);
    timer.reset();
    final orders = <int, WorkOrder>{};
    for (final machine in machines) {
      for (final order in machine.orders) {
        orders[order.id!] = order;
      }
    }
    final ids = orders.values
        .where(
            (order) => order.item == null || (order.item!.name ?? "").isEmpty)
        .map((order) => order.itemId)
        .whereType<int>()
        .toSet()
        .toList();
    final items = <int, Item>{};
    // Batch unique items rather than making one request per machine.
    for (var start = 0; start < ids.length; start += 40) {
      final end = start + 40 < ids.length ? start + 40 : ids.length;
      final response = await client.get('inventory/items', queryParameters: {
        'warehouseId': warehouseId ?? Global.currentWarehouse!.id,
        'itemIdList': ids.sublist(start, end).join(','),
        'loadDetails': false
      });
      for (final raw in _data(response) as List) {
        final item = Item.fromJson(Map<String, dynamic>.from(raw as Map));
        if (item.id != null) items[item.id!] = item;
      }
    }
    for (final machine in machines) {
      for (final order in machine.orders) {
        // A user can select a machine while names are loading. Do not overwrite
        // full reporting details that prepareOrder has already supplied.
        if (items.containsKey(order.itemId) &&
            (order.item == null || (order.item!.name ?? '').isEmpty)) {
          order.item = items[order.itemId];
        }
      }
    }
    debugPrint(
        '[Defective timing] item names + decode: ${timer.elapsedMilliseconds} ms; machines=${machines.length}');
    return machines;
  }

  static Future<void> prepareOrder(WorkOrder order,
      {Dio? client, int? warehouseId}) async {
    final id = order.itemId ?? order.item?.id;
    if (id == null) throw Exception('Item id unavailable');
    final timer = Stopwatch()..start();
    final response = await (client ?? CWMSHttpClient.getDio())
        .get('inventory/items', queryParameters: {
      'warehouseId': warehouseId ?? Global.currentWarehouse!.id,
      'itemIdList': '$id',
      'loadDetails': true
    });
    final items = (_data(response) as List)
        .map((raw) => Item.fromJson(Map<String, dynamic>.from(raw as Map)))
        .where((item) => item.id == id)
        .toList();
    if (items.length != 1 || items.single.itemPackageTypes.isEmpty) {
      throw Exception('Item or package details unavailable');
    }
    order.item = items.single;
    debugPrint(
        '[Defective timing] selected item details + decode: ${timer.elapsedMilliseconds} ms');
  }

  static Future<bool> isStillAssigned(WorkOrder order, ProductionLine line,
      {Dio? client, int? warehouseId}) async {
    if (order.id == null || line.id == null) return false;
    final fresh = await _assignedOrders(
        lineId: line.id, client: client, warehouseId: warehouseId);
    return fresh.any((value) =>
        value.id == order.id &&
        isActiveDefectiveOrder(value) &&
        value.productionLineAssignments
            .any((a) => a.productionLine?.id == line.id));
  }
}
