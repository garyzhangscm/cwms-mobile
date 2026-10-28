import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/workorder/models/rfid_check.dart';
import 'package:cwms_mobile/workorder/models/rfid_pallet.dart';
import 'package:cwms_mobile/workorder/services/rfid_catalog.dart';

String tag(int serial, {int item = 123}) => ((BigInt.from(0x30) << 88) |
        (BigInt.from(6) << 82) |
        (BigInt.from(12345) << 62) |
        (BigInt.from(item) << 38) |
        BigInt.from(serial))
    .toRadixString(16)
    .padLeft(24, '0');
void main() {
  test(
      '325 serials of one UPC count as 325 items across pauses and duplicate reads',
      () {
    final pallet = RfidPallet();
    final first = List.generate(325, (i) => tag(i));
    expect(pallet.add(first), 325);
    expect(pallet.add(first.map((s) => s.toLowerCase())), 0);
    expect(pallet.itemsRead, 325);
    expect(pallet.counts, {sgtin96ToGtin(first.first): 325});
    expect(pallet.add([tag(500)]), 1);
    expect(pallet.itemsRead, 326);
  });
  test('Mixed products and unknown encoding are not merged into main count',
      () {
    final p = RfidPallet();
    p.add([tag(1), tag(2), tag(3, item: 456), 'ABCD', 'abcd', '']);
    expect(p.itemsRead, 3);
    expect(p.counts.values.toList()..sort(), [1, 2]);
    expect(p.unsupported, 1);
    expect(p.uniqueTags, 4);
    expect(RfidPallet().uniqueTags, 0);
  });
  test(
      'Catalog normalizes UPC/GTIN and exposes duplicates rather than choosing',
      () {
    final gtin = sgtin96ToGtin(tag(1));
    expect(gtin.startsWith('00'), true);
    final c = RfidCatalog([
      RfidItem(
          id: 1, name: 'A', description: 'Product A', upc: gtin.substring(2)),
      RfidItem(id: 2, name: 'B', description: 'Product B', upc: gtin),
      const RfidItem(id: 3, name: 'C', description: '', upc: 'not-a-upc'),
    ]);
    expect(c.matches(gtin).map((i) => i.name), ['A', 'B']);
    expect(c.matches(sgtin96ToGtin(tag(1, item: 222))), isEmpty);
  });
  test('Batch response maps compact UPC fields and rejects failed response',
      () {
    final gtin = sgtin96ToGtin(tag(1));
    final c = RfidCatalog(RfidCatalogService.parseBatch({
      'result': 0,
      'data': [
        {'id': 1, 'name': 'A', 'description': 'Product', 'upc': gtin},
        {'id': 2, 'name': 'B', 'upc': gtin}
      ]
    }));
    expect(c.matches(gtin).map((i) => i.id), [1, 2]);
    expect(() => RfidCatalogService.parseBatch({'result': 1, 'data': []}),
        throwsStateError);
    expect(() => RfidCatalogService.parseBatch({'result': 0, 'data': 'bad'}),
        throwsStateError);
  });
}
