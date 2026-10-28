import 'package:flutter_test/flutter_test.dart';
import 'package:cwms_mobile/workorder/models/rfid_label_ocr.dart';

void main() {
  test('Reads the supplied label UPC and ignores its product description', () {
    expect(labelUpcCandidates(['618842526307', '2GAL WATERING CAN GREEN']),
        ['618842526307']);
  });
  test('Does not repair OCR letters, check digits or trim long numbers', () {
    expect(
        labelUpcCandidates([
          '6188425263O7',
          '618842526308',
          '16188425263077',
          'ABC618842526307XYZ'
        ]),
        isEmpty);
  });
  test('Handles printed spacing and preserves multiple candidates', () {
    expect(
        labelUpcCandidates(
            ['UPC: 6 18842 52630 7', '036000291452', '00618842526307']),
        ['618842526307', '036000291452']);
  });
  test('Never joins separate lines into a code', () {
    expect(labelUpcCandidates(['618842', '526307']), isEmpty);
  });
}
