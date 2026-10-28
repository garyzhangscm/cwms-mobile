import 'rfid_check.dart';

class RfidItem {
  const RfidItem(
      {required this.id,
      required this.name,
      required this.description,
      required this.upc});
  final int id;
  final String name, description, upc;
}

/// Page-local catalog, obtained using the authenticated company/warehouse API.
class RfidCatalog {
  final Map<String, List<RfidItem>> _byGtin = {};
  RfidCatalog(Iterable<RfidItem> items) {
    final ids = <int>{};
    for (final item in items) {
      if (!ids.add(item.id)) continue;
      try {
        final gtin = normalizeGtin(item.upc);
        (_byGtin[gtin] ??= []).add(item);
      } on FormatException {/* Empty/non-UPC attribute values cannot match. */}
    }
  }
  List<RfidItem> matches(String gtin) =>
      List.unmodifiable(_byGtin[gtin] ?? <RfidItem>[]);
}

class RfidPallet {
  static const maximumTags = 50000;
  final Set<String> _epcs = {};
  final Map<String, int> _counts = {};
  int unsupported = 0;
  bool atCapacity = false;
  int get uniqueTags => _epcs.length;
  int get itemsRead => uniqueTags - unsupported;
  Map<String, int> get counts => Map.unmodifiable(_counts);

  /// Deduplicate the entire EPC across pause/resume, not just the product UPC.
  int add(Iterable<String> reads) {
    var added = 0;
    for (final value in reads) {
      final epc = value.trim().toUpperCase();
      if (epc.isEmpty || _epcs.contains(epc)) continue;
      if (_epcs.length >= maximumTags) {
        atCapacity = true;
        break;
      }
      _epcs.add(epc);
      added++;
      try {
        final gtin = sgtin96ToGtin(epc);
        _counts.update(gtin, (n) => n + 1, ifAbsent: () => 1);
      } on FormatException {
        unsupported++;
      }
    }
    return added;
  }
}
