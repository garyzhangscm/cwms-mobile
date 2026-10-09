import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/global.dart';
import '../models/inventory.dart';
import '../../warehouse_layout/models/warehouse_location.dart';
import 'putaway_sync_queue.dart';

class PutawaySyncGateway {
  PutawaySyncGateway(
      this.server, this.companyId, this.warehouseId, this.rfCode, this.username,
      {this.clientFactory});
  final String server, rfCode, username;
  final int companyId, warehouseId;
  final Dio Function(BaseOptions)? clientFactory;
  static final Map<String, Future<PutawaySyncQueue>> _queues = {};
  String get key => 'putaway_queue_v1:${jsonEncode([
            server,
            companyId,
            warehouseId,
            rfCode,
            username
          ])}';
  bool get sessionMatches =>
      Global.currentServer?.url == server &&
      Global.lastLoginCompanyId == companyId &&
      Global.currentWarehouse?.id == warehouseId &&
      Global.getLastLoginRFCode() == rfCode &&
      Global.currentUser?.username == username &&
      (Global.currentUser?.token?.isNotEmpty ?? false);
  static Future<PutawaySyncQueue> currentQueue() {
    final server = Global.currentServer?.url;
    final company = Global.lastLoginCompanyId;
    final warehouse = Global.currentWarehouse?.id;
    final rf = Global.getLastLoginRFCode();
    final user = Global.currentUser?.username;
    if (server == null ||
        company == null ||
        warehouse == null ||
        rf.isEmpty ||
        user == null) {
      throw StateError(
          'Please sign in and select your warehouse and RF device.');
    }
    final gateway = PutawaySyncGateway(server, company, warehouse, rf, user);
    return _queues.putIfAbsent(gateway.key, () async {
      final prefs = await SharedPreferences.getInstance();
      final queue = PutawaySyncQueue(
          read: () async => prefs.getString(gateway.key),
          write: (value) async {
            if (!await prefs.setString(gateway.key, value))
              throw StateError('Could not save scanned LPNs');
          },
          sessionMatches: () => gateway.sessionMatches,
          probe: gateway.probe,
          synchronize: gateway.synchronize,
          synchronizeSaved: (entry, save) => gateway.synchronize(entry.lpn,
              scan: entry, saveCheckpoint: save));
      await queue.initialize();
      return queue;
    });
  }

  Future<dynamic> request(String method, String path,
      {Map<String, dynamic>? query, dynamic data}) async {
    if (!sessionMatches)
      throw PutawaySyncFailure('Sign in again to continue synchronization.',
          loginRequired: true);
    // Queue requests handle expiration without logging out or deleting their page/records.
    final options = BaseOptions(
        baseUrl: server,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Authorization': 'Bearer ${Global.currentUser!.token}',
          'warehouseId': warehouseId,
          'companyId': companyId,
          'rfCode': rfCode,
          'Accept': 'application/json'
        });
    final dio = clientFactory?.call(options) ?? Dio(options);
    try {
      final response = await dio.request(path,
          queryParameters: query, data: data, options: Options(method: method));
      final obj =
          response.data is String ? jsonDecode(response.data) : response.data;
      if (obj is! Map || obj['result'] != 0 || obj['data'] == null) {
        throw PutawaySyncFailure(obj is Map
            ? (obj['message']?.toString() ??
                'Server returned invalid inventory data')
            : 'Server returned invalid inventory data');
      }
      return obj['data'];
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401)
        throw PutawaySyncFailure(
            'Login expired. Sign in again to continue synchronization.',
            loginRequired: true);
      if (status == 403)
        throw PutawaySyncFailure(
            'You do not have permission for this operation.');
      if (error.type != DioExceptionType.badResponse ||
          status != null && status >= 500) {
        throw PutawaySyncFailure(
            'Waiting for the Colton server. Your scan is saved.',
            retryable: true);
      }
      throw PutawaySyncFailure('Server rejected this request (HTTP $status).');
    } finally {
      dio.close();
    }
  }

  Future<int> probe() async {
    final count = await request('GET', '/inventory/inventories/count',
        query: {'warehouseId': warehouseId, 'location': rfCode});
    final value = int.tryParse(count.toString());
    if (value == null || value < 0)
      throw PutawaySyncFailure('Invalid RF inventory count.');
    return value;
  }

  Future<PutawaySyncResult> synchronize(String lpn,
      {PutawayScan? scan, Future<void> Function()? saveCheckpoint}) async {
    final data = await request('GET', '/inventory/inventories', query: {
      'warehouseId': warehouseId,
      'lpn': lpn,
      'includeDetails': false
    });
    if (data is! List || data.isEmpty)
      throw PutawaySyncFailure(
          'No inventory found for LPN $lpn. Check and scan again to retry.');
    if (data.any((row) =>
        row is! Map ||
        row['id'] is! int ||
        row['id'] <= 0 ||
        row['quantity'] is! int ||
        row['quantity'] < 0 ||
        row['lpn'] != lpn)) {
      throw PutawaySyncFailure(
          'The server returned invalid inventory data for this LPN. Please check it before retrying.');
    }
    final inventories = data
        .map((e) => Inventory.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    for (final inventory in inventories) {
      if (inventory.id == null ||
          inventory.quantity == null ||
          inventory.quantity! < 0) {
        throw PutawaySyncFailure(
            'Inventory ID or quantity is missing. Please check this LPN.');
      }
    }
    final locations = await request('GET', '/layout/locations',
        query: {'warehouseId': warehouseId, 'name': rfCode});
    if (locations is! List || locations.length != 1)
      throw PutawaySyncFailure('Cannot find RF location $rfCode.');
    final location =
        WarehouseLocation.fromJson(Map<String, dynamic>.from(locations.single));
    if (location.id == null)
      throw PutawaySyncFailure('RF location ID is missing.');
    if (scan != null) {
      if (scan.origins.isEmpty) {
        scan.origins = {
          for (final inventory in inventories)
            inventory.id.toString():
                inventory.locationId ?? inventory.location?.id
        };
        if (saveCheckpoint != null) await saveCheckpoint();
      }
      final ids =
          inventories.map((inventory) => inventory.id.toString()).toSet();
      if (ids.length != scan.origins.length ||
          !ids.containsAll(scan.origins.keys)) {
        throw PutawaySyncFailure(
            'Inventory records changed while this scan was pending. Please verify the LPN before retrying.');
      }
      for (final inventory in inventories) {
        final current = inventory.locationId ?? inventory.location?.id;
        if (current != location.id &&
            current != scan.origins[inventory.id.toString()]) {
          throw PutawaySyncFailure(
              'This LPN has moved to another location. Please verify it before retrying.');
        }
      }
    }
    var newRfRecords = 0;
    for (final inventory in inventories) {
      // Reconcile uncertain writes after reconnect: already on this RF means no second move.
      if ((inventory.locationId ?? inventory.location?.id) == location.id)
        continue;
      await request('POST', '/inventory/inventory/move',
          query: {
            'warehouseId': warehouseId,
            'inventoryId': inventory.id,
            'immediateMove': true
          },
          data: location.toJson());
      newRfRecords++;
    }
    final names =
        inventories.map((e) => e.item?.name).whereType<String>().toSet();
    return PutawaySyncResult(
        inventories.fold<int>(0, (sum, e) => sum + e.quantity!),
        names.isEmpty ? '—' : names.join(', '),
        newRfRecords: newRfRecords);
  }
}
