import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/workorder/models/rfid_check.dart';
import 'package:cwms_mobile/auth/models/menu.dart';

String epc(int partition, {String company = '123456', int item = 12, int serial = 1}) {
  const widths = [40, 37, 34, 30, 27, 24, 20];
  final value = (BigInt.from(0x30) << 88) | (BigInt.from(partition) << 82) |
      (BigInt.parse(company) << (82 - widths[partition])) |
      (BigInt.from(item) << 38) | BigInt.from(serial);
  return value.toRadixString(16).padLeft(24, '0');
}
void main() {
  test('SGTIN partitions retain leading zeroes and ignore filter/serial', () {
    for (var partition = 0; partition <= 6; partition++) {
      final tag = epc(partition, item: 1);
      final company = '123456'.padLeft(12 - partition, '0');
      final item = '1'.padLeft(partition + 1, '0');
      final body = item[0] + company + item.substring(1);
      expect(sgtin96ToGtin(tag), '$body${gtinCheckDigit(body)}');
      expect(sgtin96ToGtin(epc(partition, item: 1, serial: 999)), sgtin96ToGtin(tag));
    }
  });
  test('Known GTIN check digit and UPC normalization', () {
    expect(gtinCheckDigit('03600029145'), 2);
    expect(normalizeGtin('036000291452'), '00036000291452');
    expect(() => normalizeGtin('036000291453'), throwsFormatException);
    expect(() => normalizeGtin('36O000291452'), throwsFormatException);
  });
  test('Mismatch, duplicates, no reads and multiple tags fail closed', () {
    final tag = epc(6);
    final gtin = sgtin96ToGtin(tag);
    expect(compareRfid(gtin, [tag, tag.toLowerCase()]).outcome, RfidOutcome.pass);
    expect(compareRfid('036000291452', [tag]).outcome, RfidOutcome.mismatch);
    expect(compareRfid(gtin, []).outcome, RfidOutcome.noTag);
    expect(compareRfid(gtin, [tag, epc(6, serial: 2)]).outcome, RfidOutcome.multipleTags);
    expect(compareRfid(gtin, ['ABCD']).outcome, RfidOutcome.unsupported);
  });
  test('Reject unsupported headers, partitions and overflowing decimal fields', () {
    expect(() => sgtin96ToGtin('350000000000000000000000'), throwsFormatException);
    expect(() => sgtin96ToGtin('301C00000000000000000000'), throwsFormatException);
    expect(() => sgtin96ToGtin(epc(0, item: 15)), throwsFormatException);
    expect(() => sgtin96ToGtin(epc(6, company: '1048575')), throwsFormatException);
  });
  test('RFID menu respects Produce access and does not duplicate or mutate menus', () {
    final menus = [Menu()..link = 'work_order_produce'];
    expect(withRfidCheckMenu(menus).length, 3);
    expect(menus.length, 1);
    expect(withRfidCheckMenu(withRfidCheckMenu(menus)).length, 3);
    expect(withRfidCheckMenu([Menu()..link = 'inventory']).length, 1);
  });
}
