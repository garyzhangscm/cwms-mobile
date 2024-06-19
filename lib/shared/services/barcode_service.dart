
import 'dart:convert';

import 'package:cwms_mobile/common/services/system_controlled_number.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/inbound/models/receipt.dart';
import 'package:cwms_mobile/inbound/models/receipt_line.dart';
import 'package:cwms_mobile/inbound/models/receipt_status.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_status.dart';
import 'package:cwms_mobile/inventory/models/item_package_type.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/rf_app_version.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:dio/dio.dart';

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
    if(!barcode.is_2d || barcode.result == null || !barcode.result.containsKey(fieldName)) {
      return barcode.value;
    }
    return barcode.result[fieldName];
  }

  static String getLPN(Barcode barcode) {
    return getValueFrom2DBarcode(barcode, "lpn");
  }



}




