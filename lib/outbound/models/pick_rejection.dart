import 'dart:convert';

class PickRejection {
  PickRejection(
      this.title, this.lpn, this.location, this.reason, this.nextAction);
  final String title, lpn, location, reason, nextAction;
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
