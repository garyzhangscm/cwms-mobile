import '../models/pick_rejection.dart';
import 'package:dio/dio.dart';
import '../../shared/scanning/scan_feedback.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';

class PreprintedManualPickService {
  static String get _key =>
      'manual-pick-pending:${Global.currentServer?.url}:${Global.currentWarehouse?.id}:${Global.currentUser?.username}';
  static Map<String, dynamic> _data(dynamic value) {
    final map = value is Map
        ? Map<String, dynamic>.from(value)
        : jsonDecode(value.toString()) as Map<String, dynamic>;
    if (map['result'] != 0)
      throw WebAPICallException(
          map['message']?.toString() ?? 'Unable to process manual pick');
    return Map<String, dynamic>.from(map['data'] as Map);
  }

  static Future<T> _timed<T>(
      String phase, Future<T> Function() operation) async {
    final timer = Stopwatch()..start();
    try {
      return await operation();
    } finally {
      debugPrint('[PERF] manual-pick $phase=${timer.elapsedMilliseconds}ms');
    }
  }

  /// Diagnostic reads run only after rejection, never on the successful scanning path.
  static Future<PickRejection?> explainRejectedLpn(int orderId, String orderNumber, String lpn, {Set<int> orderItemIds = const {}, List<String> requiredItems = const []}) async {
    final warehouse = Global.currentWarehouse?.id;
    if (warehouse == null || lpn.trim().isEmpty) return null;
    final client = CWMSHttpClient.getDio();
    try {
      final rows = _listData((await client.get('inventory/inventories',
          queryParameters: {'warehouseId': warehouse, 'lpn': lpn, 'includeDetails': false},
          options: Options(receiveTimeout: const Duration(seconds: 3)))
          .timeout(const Duration(seconds: 4))).data)
          .where((r) => r['lpn'] == lpn).toList();
      if (Global.currentWarehouse?.id != warehouse) return null;
      if (rows.isEmpty) return PickRejection.notFound(lpn);
      if (rows.any((r) => (r['quantity'] as num? ?? 0) <= 0)) return null;
      if (rows.any((r) => r['pickId'] == null && r['allocatedByPickId'] == null)) {
        final ids = rows.map((r) => (r['itemId'] ?? (r['item'] is Map ? r['item']['id'] : null)) as num?).toList();
        // Do not infer a mismatch from missing metadata, exhausted demand or a mixed matching pallet.
        if (orderItemIds.isEmpty || ids.any((id) => id == null || orderItemIds.contains(id.toInt()))) return null;
        final itemIds = ids.map((id) => id!.toInt()).toSet();
        if (itemIds.length > 8) return null;
        final labels = await Future.wait(itemIds.map((id) async {
          try {
            final embedded = rows.where((r) => r['item'] is Map && r['item']['id'] == id && r['item']['name'] is String).toList();
            final item = embedded.isNotEmpty ? Map<String, dynamic>.from(embedded.first['item']) : _data((await client.get(
                'inventory/items/$id', queryParameters: {'warehouseId': warehouse},
                options: Options(receiveTimeout: const Duration(seconds: 3)))
                .timeout(const Duration(seconds: 4))).data);
            if (item['id'] != id || (item['warehouseId'] != null && item['warehouseId'] != warehouse)) return '';
            final name = item['name']?.toString().trim() ?? '';
            final description = item['description']?.toString().trim() ?? '';
            return name.isEmpty ? '' : '$name${description.isEmpty ? "" : " — $description"}';
          } catch (_) { return ''; }
        }));
        if (Global.currentWarehouse?.id != warehouse) return null;
        return PickRejection.itemMismatch(lpn, labels.where((label) => label.isNotEmpty).toList(), requiredItems);
      }
      final ids = rows.map((r) => ((r['pickId'] ?? r['allocatedByPickId']) as num).toInt()).toSet();
      if (ids.length > 8) return null;
      final values = await Future.wait(ids.map((id) async => _data((await client.get(
          'outbound/picks/$id', options: Options(receiveTimeout: const Duration(seconds: 3)))
          .timeout(const Duration(seconds: 4))).data)));
      final picks = <int, Map<String, dynamic>>{};
      for (final p in values) {
        if (p['warehouseId'] != warehouse) return null;
        picks[(p['id'] as num).toInt()] = p;
      }
      // Queue lookup failure must not be interpreted as a completed operation.
      final tasks = await queue(orderId).timeout(const Duration(seconds: 4));
      if (Global.currentWarehouse?.id != warehouse) return null;
      return PickRejection.occupied(lpn, orderNumber, rows, picks, tasks);
    } catch (_) {
      return null; // Retain the original error when live state cannot be verified.
    }
  }

  static Future<Map<String, dynamic>> preview(int orderId, String lpn) =>
      _timed(
          'preview',
          () async => _data((await CWMSHttpClient.getDio().get(
                      'outbound/orders/$orderId/preprinted-manual-pick',
                      queryParameters: {
                    'warehouseId': Global.currentWarehouse!.id,
                    'sourceLpn': lpn.trim()
                  }))
                  .data));
  static Future<Map<String, dynamic>?> pending() async {
    final key = _key;
    final text = (await SharedPreferences.getInstance()).getString(key);
    return text == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(text) as Map);
  }

  static Future<Map<String, dynamic>?> lastQueuedOrder() async {
    final text =
        (await SharedPreferences.getInstance()).getString('$_key:queue-order');
    return text == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(text) as Map);
  }

  static Future<void> forgetQueuedOrder() async {
    await (await SharedPreferences.getInstance()).remove('$_key:queue-order');
  }

  static String _uuid() {
    final b = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final h = b.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  static Future<bool> cancelUnstarted() async {
    final key = _key;
    final warehouseId = Global.currentWarehouse!.id;
    final client = CWMSHttpClient.getDio();
    final saved = await pending();
    if (saved == null) return true;
    if (_key != key)
      throw WebAPICallException(
          'Work profile changed. Return to the original warehouse.');
    final response = _data((await client.post(
            'outbound/orders/${saved['orderId']}/preprinted-manual-pick/cancel-unstarted',
            queryParameters: {
          'warehouseId': warehouseId,
          'requestId': saved['requestId']
        }))
        .data);
    if (response['cancelled'] == true || response['completed'] == true) {
      if (!await (await SharedPreferences.getInstance()).remove(key)) {
        throw WebAPICallException(
            'Could not clear the pending record. Retry this same operation.');
      }
      return true;
    }
    return false;
  }

  static Future<bool> queueEnabled() async {
    try {
      final value = _data((await CWMSHttpClient.getDio()
              .get('outbound/manual-pick-queue/capabilities'))
          .data);
      return value['schema'] == 'manual-pick-queue-v1' &&
          value['enabled'] == true;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return false;
      rethrow; // A timeout or permission failure must not silently change the picking mode.
    }
  }

  static Future<List<Map<String, dynamic>>> queue(int orderId) async {
    final raw = (await CWMSHttpClient.getDio().get(
            'outbound/orders/$orderId/manual-pick-queue',
            queryParameters: {'warehouseId': Global.currentWarehouse!.id}))
        .data;
    final value = raw is Map ? raw : jsonDecode(raw.toString()) as Map;
    if (value['result'] != 0)
      throw WebAPICallException(
          value['message']?.toString() ?? 'Could not load Pick tasks');
    final tasks = (value['data'] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    return tasks;
  }

  static Future<List<Map<String, dynamic>>> currentPicks(int orderId) async {
    final raw = (await CWMSHttpClient.getDio().get('outbound/picks',
        queryParameters: {
          'warehouseId': Global.currentWarehouse!.id,
          'orderId': orderId,
          'includeCompletedPick': true,
          'loadDetails': false,
        })).data;
    return _listData(raw);
  }

  static Future<List<Map<String, dynamic>>> pickedPallets(int orderId) async {
    final picks = await currentPicks(orderId);
    final ids = picks.where((r) =>
        r['id'] != null && (r['pickedQuantity'] as num? ?? 0) > 0)
        .map((r) => r['id'].toString()).toSet().toList();
    // An empty pickIds filter would query unrelated inventory.
    if (ids.isEmpty) return [];
    final rows = <Map<String, dynamic>>[];
    for (var offset = 0; offset < ids.length; offset += 100) {
      final batch = ids.skip(offset).take(100).toSet();
      final raw = (await CWMSHttpClient.getDio().get('inventory/inventories',
          queryParameters: {
            'warehouseId': Global.currentWarehouse!.id,
            'pickIds': batch.join(','),
            'includeDetails': false,
          })).data;
      rows.addAll(_listData(raw).where((row) =>
          batch.contains('${row['pickId']}') &&
          (row['quantity'] as num? ?? 0) > 0));
    }
    return rows;
  }

  static List<Map<String, dynamic>> _listData(dynamic raw) {
    final value = raw is Map ? raw : jsonDecode(raw.toString()) as Map;
    if (value['result'] != 0 || value['data'] is! List) {
      throw WebAPICallException('Could not verify current Picks');
    }
    return (value['data'] as List)
        .map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  static Future<void> retryQueued(int orderId, String id) async {
    _data((await CWMSHttpClient.getDio().post(
            'outbound/orders/$orderId/manual-pick-queue/$id/retry',
            queryParameters: {'warehouseId': Global.currentWarehouse!.id}))
        .data);
  }

  static Future<void>? _sending;
  static Future<void> submit(Map<String, dynamic> details) {
    if (_sending != null) return _sending!;
    final current = _timed('submit', () => _submit(details));
    _sending = current.whenComplete(() => _sending = null);
    return _sending!;
  }

  static Future<void> _submit(Map<String, dynamic> details) async {
    final key = _key;
    final warehouseId = Global.currentWarehouse!.id;
    final client = CWMSHttpClient.getDio();
    final prefs = await SharedPreferences.getInstance();
    final text = prefs.getString(key);
    final saved = text == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(text) as Map);
    final request = saved ?? {...details, 'requestId': _uuid()};
    // Write before sending. An uncertain response always reuses this exact request.
    if (saved == null && !await prefs.setString(key, jsonEncode(request))) {
      throw WebAPICallException(
          'Could not save this pick safely. Please try again.');
    }
    if (_key != key)
      throw WebAPICallException(
          'Work profile changed. Return to the original warehouse to resume this pick.');
    final params = {...request}
      ..remove('orderId')
      ..remove('orderNumber')
      ..remove('queued');
    final result = _data((await client.post(
            "outbound/orders/${request['orderId']}/${request['queued'] == true ? 'manual-pick-queue' : 'preprinted-manual-pick'}",
            queryParameters: {...params, 'warehouseId': warehouseId}))
        .data);
    final accepted = request['queued'] == true &&
        result['requestId'] == request['requestId'] &&
        ['QUEUED', 'COMPLETED', 'NEEDS_REVIEW'].contains(result['state']);
    if (!accepted && result['completed'] != true) {
      ScanFeedback.current?.uncertain = true;
      throw WebAPICallException(
          'Pick is awaiting confirmation. Retry this same pick.');
    }
    if (request['queued'] == true &&
        !await prefs.setString(
            '$key:queue-order',
            jsonEncode({
              'orderId': request['orderId'],
              'orderNumber': request['orderNumber']
            }))) {
      throw WebAPICallException(
          'The task was accepted but could not be saved on this phone. Resume the same request to recover.');
    }
    if (!await prefs.remove(key)) {
      ScanFeedback.current?.uncertain = true;
      throw WebAPICallException(
          'Pick confirmed, but the pending record could not be cleared. Retry the same operation to recover.');
    }
  }
}
