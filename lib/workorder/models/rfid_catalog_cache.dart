import 'rfid_pallet.dart';

/// One in-memory login scope; never written to disk. Failed loads are retried.
class RfidCatalogCache {
  RfidCatalogCache(
      {DateTime Function()? now, this.ttl = const Duration(minutes: 2)})
      : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  final Duration ttl;
  String? _scope;
  Object? _generation;
  RfidCatalog? _value;
  DateTime? _expires;
  Future<RfidCatalog>? _pending;

  /// Last successful mapping for this login only, including while refreshing.
  RfidCatalog? peek(String scope) => _scope == scope ? _value : null;

  Future<RfidCatalog> load(String scope, Future<RfidCatalog> Function() fetch,
      {bool forceRefresh = false}) {
    if (_scope != scope) {
      _scope = scope;
      _generation = Object();
      _value = null;
      _expires = null;
      _pending = null;
    }
    // Prefetch and page entry share one request, including manual retries.
    if (_pending != null) return _pending!;
    if (!forceRefresh && _value != null && _now().isBefore(_expires!)) {
      return Future.value(_value!);
    }
    // Keep the last successful mapping visible during refresh or network failure.
    final generation = _generation;
    final request = Future<RfidCatalog>.sync(fetch).then((value) {
      if (!identical(generation, _generation)) {
        throw StateError('Login scope changed');
      }
      _value = value;
      _expires = _now().add(ttl);
      return value;
    }).whenComplete(() {
      if (identical(generation, _generation)) _pending = null;
    });
    _pending = request;
    return request;
  }
}
