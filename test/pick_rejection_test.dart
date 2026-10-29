import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/outbound/models/pick_rejection.dart';

void main() {
  test('verified rejection decodes through legacy exception prefix', () {
    final r = PickRejection.parse(
        'Order Operation Exception-PICK_REJECTION_V1:${jsonEncode({
          'title': 'Pallet unavailable for picking',
          'lpn': 'L0000281044',
          'location': 'TRANS_SHIPPING',
          'reason': 'Already in transfer shipping.',
          'nextAction': 'Scan another pallet.'
        })}');
    expect(r?.location, 'TRANS_SHIPPING');
    expect(r?.lpn, 'L0000281044');
  });
  test(
      'generic, malformed or incomplete failures never imply transfer shipping',
      () {
    for (final text in [
      'LPN is not pickable',
      'timeout',
      'PICK_REJECTION_V1:{',
      'PICK_REJECTION_V1:{}'
    ]) {
      expect(PickRejection.parse(text), isNull);
    }
  });
}
