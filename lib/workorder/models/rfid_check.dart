import '../../auth/models/menu.dart';

List<Menu> withRfidCheckMenu(List<Menu> menus) {
  final result = List<Menu>.of(menus);
  if (menus.any((m) => m.link == 'work_order_produce') &&
      !menus.any((m) => m.link == 'work_order_rfid_check')) {
    result.add(Menu()
      ..name = 'RFID Label Check'
      ..text = 'RFID Label Check'
      ..link = 'work_order_rfid_check');
  }
  if (menus.any((m) => m.link == 'work_order_produce') &&
      !menus.any((m) => m.link == 'work_order_rfid_pallet')) {
    result.add(Menu()
      ..name = 'RFID Pallet Scan'
      ..text = 'RFID Pallet Scan'
      ..link = 'work_order_rfid_pallet');
  }
  return result;
}

int gtinCheckDigit(String digits) {
  var total = 0;
  for (var i = 0; i < digits.length; i++) {
    total += int.parse(digits[digits.length - 1 - i]) * (i.isEven ? 3 : 1);
  }
  return (10 - total % 10) % 10;
}

String normalizeGtin(String input) {
  final value = input.trim();
  if (!RegExp(r'^(\d{12}|\d{13}|\d{14})$').hasMatch(value) ||
      gtinCheckDigit(value.substring(0, value.length - 1)) !=
          int.parse(value[value.length - 1])) {
    throw const FormatException('Invalid UPC / GTIN');
  }
  return value.padLeft(14, '0');
}

/// GS1 SGTIN-96: header, filter, partition, company prefix, item reference,
/// serial. Serial identifies the individual tag and is not part of the GTIN.
String sgtin96ToGtin(String epc) {
  final hex = epc.trim();
  if (!RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(hex)) {
    throw const FormatException('Unsupported EPC');
  }
  final bits = BigInt.parse(hex, radix: 16);
  if ((bits >> 88).toInt() != 0x30) {
    throw const FormatException('Unsupported EPC');
  }
  final partition = ((bits >> 82) & BigInt.from(7)).toInt();
  if (partition > 6) throw const FormatException('Invalid partition');
  const companyBits = [40, 37, 34, 30, 27, 24, 20];
  final itemBits = 44 - companyBits[partition];
  final company = ((bits >> (38 + itemBits)) &
          ((BigInt.one << companyBits[partition]) - BigInt.one))
      .toString();
  final item =
      ((bits >> 38) & ((BigInt.one << itemBits) - BigInt.one)).toString();
  final companyDigits = 12 - partition;
  final itemDigits = 1 + partition;
  if (company.length > companyDigits || item.length > itemDigits) {
    throw const FormatException('Invalid decimal encoding');
  }
  final ref = item.padLeft(itemDigits, '0');
  final body = ref[0] + company.padLeft(companyDigits, '0') + ref.substring(1);
  return '$body${gtinCheckDigit(body)}';
}

enum RfidOutcome { pass, mismatch, noTag, multipleTags, unsupported }

class RfidComparison {
  final RfidOutcome outcome;
  final String? gtin;
  const RfidComparison(this.outcome, [this.gtin]);
}

RfidComparison compareRfid(String expected, Iterable<String> reads) {
  final target = normalizeGtin(expected);
  final tags = reads
      .map((e) => e.trim().toUpperCase())
      .where((e) => e.isNotEmpty)
      .toSet();
  if (tags.isEmpty) return const RfidComparison(RfidOutcome.noTag);
  if (tags.length != 1) return const RfidComparison(RfidOutcome.multipleTags);
  try {
    final gtin = sgtin96ToGtin(tags.single);
    return RfidComparison(
        gtin == target ? RfidOutcome.pass : RfidOutcome.mismatch, gtin);
  } on FormatException {
    return const RfidComparison(RfidOutcome.unsupported);
  }
}
