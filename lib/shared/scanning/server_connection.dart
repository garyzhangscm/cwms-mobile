import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import '../global.dart';
import 'rf_inventory_count_query.dart';

enum ServerConnectionState { checking, connected, disconnected, signIn }

class ConnectionProfile {
  const ConnectionProfile(
      this.server, this.warehouse, this.company, this.rf, this.token);
  final String server, rf, token;
  final int warehouse, company;
  String get scope => '$server|$warehouse|$company|$rf|$token';
}

class ServerConnectionMonitor extends ChangeNotifier
    with WidgetsBindingObserver {
  ServerConnectionMonitor(
      {required this.profile,
      required this.probe,
      this.interval = const Duration(seconds: 15),
      DateTime Function()? now})
      : now = now ?? DateTime.now;
  final ConnectionProfile? Function() profile;
  final Future<int> Function(ConnectionProfile) probe;
  final Duration interval;
  final DateTime Function() now;
  DateTime? _lastObservation;
  ServerConnectionState state = ServerConnectionState.checking;
  Timer? _timer;
  int _listeners = 0, _generation = 0, _evidence = 0;
  String? _scope;
  bool _busy = false, _paused = false;

  static ConnectionProfile? _profile() {
    final server = Global.currentServer?.url;
    final warehouse = Global.currentWarehouse?.id;
    final company = Global.lastLoginCompanyId;
    final token = Global.currentUser?.token;
    if (server == null ||
        warehouse == null ||
        company == null ||
        token == null ||
        token.isEmpty) return null;
    return ConnectionProfile(
        server, warehouse, company, Global.getLastLoginRFCode(), token);
  }

  static final shared = ServerConnectionMonitor(
      profile: _profile,
      probe: (p) async {
        final client = Dio(BaseOptions(
            baseUrl: p.server,
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
            sendTimeout: const Duration(seconds: 4),
            validateStatus: (_) => true,
            headers: {
              'Authorization': 'Bearer ${p.token}',
              'warehouseId': p.warehouse,
              'companyId': p.company,
              'rfCode': p.rf,
              'Accept': 'application/json'
            }));
        try {
          final r = await RfInventoryCountQuery.share(
              p.scope,
              () => client.get('inventory/inventories/count', queryParameters: {
                    'warehouseId': p.warehouse,
                    'location': p.rf
                  }));
          return r.statusCode ?? 0;
        } on DioException catch (error) {
          if (error.response != null) return error.response!.statusCode ?? 0;
          rethrow;
        } finally {
          client.close(force: true);
        }
      });

  void attach() {
    if (++_listeners != 1) return;
    WidgetsBinding.instance.addObserver(this);
    _paused = WidgetsBinding.instance.lifecycleState != null &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed;
    scheduleMicrotask(() {
      if (_listeners > 0) {
        _start();
      }
    });
  }

  void detach() {
    if (_listeners == 0 || --_listeners != 0) return;
    _generation++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  void _start({bool force = false}) {
    _timer?.cancel();
    if (_paused || _listeners == 0) return;
    unawaited(check(force: force));
    _timer = Timer.periodic(interval, (_) => unawaited(check(force: false)));
  }

  void _set(ServerConnectionState next) {
    if (state == next) return;
    state = next;
    notifyListeners();
  }

  ServerConnectionState get visibleState {
    final p = profile();
    if (p == null) return ServerConnectionState.signIn;
    return p.scope == _scope ? state : ServerConnectionState.checking;
  }

  void note(String server, int? status,
      {bool transportFailure = false, String? scope}) {
    final p = profile();
    if (p == null || p.server != server || (scope != null && scope != p.scope))
      return;
    _evidence++;
    _lastObservation = now();
    _scope = p.scope;
    if (transportFailure || status == null || status == 0 || status >= 500) {
      _set(ServerConnectionState.disconnected);
    } else if (status == 401) {
      _set(ServerConnectionState.signIn);
    } else {
      _set(ServerConnectionState.connected);
    }
  }

  Future<void> check({bool force = true}) async {
    if (_paused || _listeners == 0) return;
    final p = profile();
    if (p == null) {
      _generation++;
      _scope = null;
      _lastObservation = null;
      _set(ServerConnectionState.signIn);
      return;
    }
    if (_scope != p.scope) {
      _lastObservation = null;
      _scope = p.scope;
      _generation++;
      _set(ServerConnectionState.checking);
    }
    // Queue reads and ordinary business responses already establish reachability.
    // Automatic checks reuse recent evidence; explicit taps still check now.
    if (!force &&
        _lastObservation != null &&
        now().difference(_lastObservation!) < interval) return;
    if (_busy) return;
    _busy = true;
    final generation = _generation;
    final evidence = _evidence;
    try {
      final status = await probe(p);
      if (_listeners > 0 &&
          !_paused &&
          generation == _generation &&
          evidence == _evidence &&
          profile()?.scope == p.scope) note(p.server, status);
    } catch (_) {
      if (_listeners > 0 &&
          !_paused &&
          generation == _generation &&
          evidence == _evidence &&
          profile()?.scope == p.scope)
        note(p.server, null, transportFailure: true);
    } finally {
      _busy = false;
      if (_listeners > 0 && !_paused && generation != _generation)
        unawaited(check());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState value) {
    _paused = value != AppLifecycleState.resumed;
    _generation++;
    _timer?.cancel();
    if (!_paused) _start(force: true);
  }
}
