import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class PutawaySyncFailure implements Exception {
  PutawaySyncFailure(this.message,
      {this.retryable = false, this.loginRequired = false});
  final String message;
  final bool retryable;
  final bool loginRequired;
}

class PutawaySyncResult {
  PutawaySyncResult(this.quantity, this.itemName, {this.newRfRecords = 0});
  final int quantity;
  final int newRfRecords;
  final String itemName;
}

class PutawayScan {
  PutawayScan(this.lpn,
      {this.state = 'pending',
      this.message = '',
      this.quantity,
      this.itemName = ''});
  final String lpn;
  String state;
  String message;
  int? quantity;
  String itemName;
  Map<String, dynamic> origins = {};
  Map<String, dynamic> toJson() => {
        'lpn': lpn,
        'state': state,
        'message': message,
        'quantity': quantity,
        'itemName': itemName,
        'origins': origins
      };
  factory PutawayScan.fromJson(Map<String, dynamic> json) =>
      PutawayScan(json['lpn'] as String,
          state: (json['state'] == 'syncing' || json['state'] == 'saving')
              ? 'pending'
              : json['state'] as String,
          message: json['message'] as String? ?? '',
          quantity: json['quantity'] as int?,
          itemName: json['itemName'] as String? ?? '')
        ..origins = Map<String, dynamic>.from(json['origins'] as Map? ?? {});
}

/// One persistent, serial worker per login/warehouse/RF scope. UI disposal never clears it.
class PutawaySyncQueue extends ChangeNotifier {
  PutawaySyncQueue(
      {required this.read,
      required this.write,
      required this.sessionMatches,
      required this.probe,
      required this.synchronize,
      this.synchronizeSaved});
  final Future<String?> Function() read;
  final Future<void> Function(String) write;
  final bool Function() sessionMatches;
  final Future<int> Function() probe;
  final Future<PutawaySyncResult> Function(String) synchronize;
  final Future<PutawaySyncResult> Function(
      PutawayScan, Future<void> Function())? synchronizeSaved;
  final List<PutawayScan> entries = [];
  String connection = 'checking';
  int serverInventoryCount = 0;
  bool _busy = false;
  bool _ready = false;
  bool _closed = false;
  Timer? _timer;
  Future<void> _writes = Future.value();
  int get pendingCount =>
      entries.where((e) => e.state == 'pending' || e.state == 'syncing').length;
  Future<void> _save() {
    final value = jsonEncode(entries.map((e) => e.toJson()).toList());
    final next = _writes.catchError((_) {}).then((_) => write(value));
    _writes = next;
    return next;
  }

  Future<void> initialize({bool startTimer = true}) async {
    final value = await read();
    if (value != null && value.isNotEmpty) {
      entries.addAll((jsonDecode(value) as List)
          .map((e) => PutawayScan.fromJson(Map<String, dynamic>.from(e))));
    }
    _ready = true;
    if (startTimer)
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => kick());
    notifyListeners();
  }

  Future<void> add(String value) async {
    final lpn = value.trim();
    if (!_ready || lpn.isEmpty) throw StateError('Scan queue is not ready');
    PutawayScan? old;
    for (final entry in entries) {
      if (entry.lpn == lpn) {
        old = entry;
        break;
      }
    }
    if (old != null) {
      if (old.state == 'failed') {
        old.state = 'pending';
        old.message = '';
        await _save();
        notifyListeners();
      }
      return;
    }
    final scan = PutawayScan(lpn);
    // Do not start synchronization until the scan is durable.
    scan.state = 'saving';
    entries.insert(0, scan);
    try {
      await _save();
      scan.state = 'pending';
      await _save();
    } catch (_) {
      entries.remove(scan);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> clearCompleted() async {
    entries.removeWhere((e) => e.state == 'completed');
    await _save();
    notifyListeners();
  }

  Future<void> kick() async {
    if (!_ready || _busy || _closed) return;
    _busy = true;
    try {
      if (!sessionMatches()) {
        connection = 'login';
        notifyListeners();
        return;
      }
      serverInventoryCount = await probe();
      connection = 'online';
      notifyListeners();
      for (final entry in List<PutawayScan>.of(entries).reversed) {
        if (entry.state != 'pending') continue;
        if (!sessionMatches()) {
          connection = 'login';
          break;
        }
        entry.state = 'syncing';
        entry.message = '';
        await _save();
        notifyListeners();
        try {
          final result = synchronizeSaved == null
              ? await synchronize(entry.lpn)
              : await synchronizeSaved!(entry, _save);
          serverInventoryCount += result.newRfRecords;
          entry.quantity = result.quantity;
          entry.itemName = result.itemName;
          entry.state = 'completed';
          entry.message = '';
        } on PutawaySyncFailure catch (error) {
          entry.message = error.message;
          entry.state =
              error.retryable || error.loginRequired ? 'pending' : 'failed';
          if (error.retryable || error.loginRequired) {
            connection = error.loginRequired ? 'login' : 'offline';
            await _save();
            break;
          }
        }
        await _save();
        notifyListeners();
      }
    } on PutawaySyncFailure catch (error) {
      connection = error.loginRequired
          ? 'login'
          : error.retryable
              ? 'offline'
              : 'error';
    } catch (_) {
      // A storage or unexpected failure must never discard a scanned LPN.
      for (final entry in entries) {
        if (entry.state == 'syncing') entry.state = 'pending';
      }
      connection = 'error';
    } finally {
      _busy = false;
      if (!_closed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _closed = true;
    _timer?.cancel();
    super.dispose();
  }
}
