import 'dart:convert';
import '../../shared/global.dart';
import '../../shared/http_client.dart';
import '../models/rfid_pallet.dart';
import '../models/rfid_check.dart';

class RfidCatalogService {
  static String? _scope;
  static final Map<String, List<RfidItem>> _items = {};
  static final Map<String, DateTime> _expires = {};
  static String scope() =>
      '${Global.currentFactory?.id}|${identityHashCode(Global.currentUser)}|${Global.currentServer?.url}|${Global.lastLoginCompanyId}|${Global.currentWarehouse?.id}|${Global.currentUser?.username ?? Global.currentUser?.login}';

  static Future<RfidCatalog> load(Iterable<String> upcs,
      {bool forceRefresh = false}) async {
    final before = scope();
    if (_scope != before) {
      _scope = before;
      _items.clear();
      _expires.clear();
    }
    final requested = upcs.map(normalizeGtin).toSet();
    final missing = requested
        .where((code) =>
            forceRefresh ||
            !_expires.containsKey(code) ||
            DateTime.now().isAfter(_expires[code]!))
        .toList();
    final company = Global.lastLoginCompanyId;
    final warehouse = Global.currentWarehouse?.id;
    if (company == null || warehouse == null)
      throw StateError('Warehouse login required');
    for (var start = 0; start < missing.length; start += 50) {
      final batch = missing.skip(start).take(50).toList();
      final timer = Stopwatch()..start();
      final response = await CWMSHttpClient.getDio()
          .get('/inventory/items-query/rfid-upcs', queryParameters: {
        'companyId': company,
        'warehouseId': warehouse,
        'upcs': batch.join(',')
      });
      if (scope() != before || _scope != before)
        throw StateError('Login scope changed');
      final requestMs = timer.elapsedMilliseconds;
      final parsed = parseBatch(response.data);
      final indexed = RfidCatalog(parsed);
      for (final code in batch) {
        _items[code] = indexed.matches(code);
        _expires[code] = DateTime.now().add(const Duration(minutes: 2));
      }
      print(
          'RfidCatalogTiming batchSize=${batch.length} requestMs=$requestMs parseMs=${timer.elapsedMilliseconds - requestMs}');
    }
    if (scope() != before) throw StateError('Login scope changed');
    return RfidCatalog(
        requested.expand((code) => _items[code] ?? <RfidItem>[]));
  }

  static List<RfidItem> parseBatch(Object? data) {
    final body = data is String ? jsonDecode(data) : data;
    if (body is! Map || body['result'] != 0 || body['data'] is! List) {
      throw StateError('Unable to load item names');
    }
    return (body['data'] as List).map((row) {
      if (row is! Map || row['id'] is! num)
        throw const FormatException('Invalid item');
      return RfidItem(
          id: (row['id'] as num).toInt(),
          name: row['name']?.toString() ?? '',
          description: row['description']?.toString() ?? '',
          upc: row['upc']?.toString() ?? '');
    }).toList();
  }
}
