import 'package:dio/dio.dart';

/// Shares only an in-flight read. Never caches an inventory count after it ends.
/// Scope includes server, warehouse, company, RF and session token.
class RfInventoryCountQuery {
  static final Map<String, Future<Response<dynamic>>> _pending = {};

  static Future<Response<dynamic>> share(
      String scope, Future<Response<dynamic>> Function() send) {
    return _pending.putIfAbsent(scope, () async {
      try {
        return await send();
      } finally {
        _pending.remove(scope);
      }
    });
  }
}
