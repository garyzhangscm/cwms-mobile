

import 'package:cwms_mobile/shared/functions.dart';

import '../models/barcode.dart';

class BarcodeService {


  /**
   * Parse 1-d or 2-d barcode
   */
  static Barcode parseBarcode(String barcodeValue)  {

    Map<String, String> result = new Map();

    if (!is2DBarcode(barcodeValue)) {
        return Barcode(false, null, barcodeValue);
    }

    // qc code should be in the format of
    // qcCode:foo=bar;x=y;
    barcodeValue = barcodeValue.substring(7);
    var parameters = barcodeValue.split(";");
    parameters.forEach((parameter) {
      var keyValue = parameter.split("=");

      if (keyValue.length == 2) {
        result[keyValue[0]] = keyValue[1];
      }
    });

    printLongLogMessage("get result after parse the qrCode ${barcodeValue} \n ${result}");

    return Barcode(true, result, barcodeValue);




  }

  static bool is2DBarcode(String barcode) {

    // qc code should be in the format of
    // qcCode:foo=bar;x=y;
    // printLongLogMessage("qrCode.length <= 7? ${qrCode.length <= 7}");
    // printLongLogMessage("qrCode.substring(0, 7): ${qrCode.substring(0, 7)}");
    // printLongLogMessage("qrCode.substring(0, 7).compareTo(qrcode) ${qrCode.substring(0, 7).toLowerCase().compareTo("qrcode:")}");
    if (barcode.length <= 7 || barcode.substring(0, 7).toLowerCase().compareTo("qrcode:") != 0) {
      return false;
    }
    return true;
  }

  static String getValueFrom2DBarcode(Barcode barcode, String fieldName) {

    // for non 2d barcode, let's get just the value
    // which is the value that the user scan in
    if(barcode.is_2d == false || barcode.result == null || !barcode.result!.containsKey(fieldName)) {
      return barcode.value!;
    }
    return barcode.result![fieldName]!;
  }

  static String getLPN(Barcode barcode) {
    return getValueFrom2DBarcode(barcode, "lpn");
  }



}




