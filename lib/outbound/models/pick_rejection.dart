import 'dart:convert';

class PickRejection {
  PickRejection(
      this.title, this.lpn, this.location, this.reason, this.nextAction);
  final String title, lpn, location, reason, nextAction;
  static PickRejection itemMismatch(String lpn, List<String> scanned, List<String> required) => PickRejection(
      'Item does not match this order', lpn, 'Unavailable',
      'This pallet contains an item that is not required by this order.\n\nScanned Item:\n${scanned.isEmpty ? "Item details unavailable" : scanned.toSet().join("\n")}\n\nThis order requires:\n${required.isEmpty ? "Reload the order to view required items." : required.toSet().join("\n")}',
      'Please scan a pallet containing an item required by this order.');

  static PickRejection notFound(String lpn) => PickRejection(
      'LPN not found', lpn, 'Unavailable',
      'LPN $lpn was not found in this warehouse.',
      'Check the label or scan another pallet.');

  /// Current inventory linkage is required; historical queue rows alone are insufficient.
  static PickRejection? occupied(String lpn, String orderNumber,
      List<Map<String, dynamic>> stock, Map<int, Map<String, dynamic>> picks,
      List<Map<String, dynamic>> tasks) {
    final rows = stock.where((r) => r['lpn'] == lpn &&
        (r['quantity'] as num? ?? 0) > 0).toList();
    if (rows.isEmpty) return null;
    // A split pallet can have an unassigned remainder; do not label it already picked.
    if (rows.any((r) => r['pickId'] == null && r['allocatedByPickId'] == null)) return null;
    final linked = <Map<String, dynamic>>[];
    for (final row in rows) {
      final id = ((row['pickId'] ?? row['allocatedByPickId']) as num?)?.toInt();
      final pick = picks[id];
      if (pick == null || pick['status'] == 'CANCELLED') return null;
      linked.add(pick);
    }
    final owners = linked.map((p) => p['orderNumber']?.toString().trim() ?? '').toSet();
    if (owners.contains('') || owners.length != 1) return null;
    final owner = owners.single;
    final location = rows.first['location'] is Map
        ? rows.first['location']['name']?.toString() ?? 'Unavailable'
        : 'Unavailable';
    if (owner != orderNumber) {
      return PickRejection('LPN assigned to another order', lpn, location,
          'This pallet is already assigned to order $owner and cannot be picked for order $orderNumber.',
          'Scan the next pallet. Ask your supervisor if this assignment needs to be changed.');
    }
    final ids = linked.map((p) => p['id']).toSet();
    final pending = tasks.any((t) => ids.contains(t['pickId']) && t['state'] == 'QUEUED');
    final review = tasks.any((t) => ids.contains(t['pickId']) && t['state'] == 'NEEDS_REVIEW');
    if (review) return PickRejection('LPN needs review', lpn, location,
        'The previous Pick for this pallet needs review. Do not submit it again.',
        'Review the saved task before continuing.');
    final picked = !pending && rows.every((r) => r['pickId'] != null) &&
        linked.every((p) => (p['pickedQuantity'] as num? ?? 0) > 0);
    return PickRejection(picked ? 'LPN already picked' : pending ? 'LPN is being processed' : 'LPN already submitted', lpn, location,
        picked ? 'This pallet has already been picked for order $orderNumber.' :
        'This pallet is already assigned to a Pick for order $orderNumber. Confirmation may still be processing; do not submit it again.',
        'Please scan the next pallet.');
  }

  static PickRejection? parse(String message) {
    const marker = 'PICK_REJECTION_V1:';
    final start = message.indexOf(marker);
    if (start < 0) return null;
    try {
      final raw = jsonDecode(message.substring(start + marker.length));
      if (raw is! Map ||
          [
            'title',
            'lpn',
            'location',
            'reason',
            'nextAction'
          ].any((k) => raw[k] is! String || (raw[k] as String).trim().isEmpty))
        return null;
      return PickRejection(raw['title'], raw['lpn'], raw['location'],
          raw['reason'], raw['nextAction']);
    } catch (_) {
      return null;
    }
  }
}
