
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

class QRCodeService {

  static Map<String, String> parseQRCode(String qrCode)  {

    Map<String, String> result = new Map();

    if (!validateQRCode(qrCode)) {

      throw new Exception("Can't parse the qr code " + qrCode);
    }

    // qc code should be in the format of
    // qcCode:foo=bar;x=y;
    qrCode = qrCode.substring(7);
    var parameters = qrCode.split(";");
    parameters.forEach((parameter) {
      var keyValue = parameter.split("=");

      if (keyValue.length == 2) {
        result[keyValue[0]] = keyValue[1];
      }
    });

    printLongLogMessage("get result after parse the qrCode ${qrCode} \n ${result}");

    return result;




  }

  static bool validateQRCode(String qrCode) {

    // qc code should be in the format of
    // qcCode:foo=bar;x=y;
    printLongLogMessage("qrCode.length <= 7? ${qrCode.length <= 7}");
    printLongLogMessage("qrCode.substring(0, 7): ${qrCode.substring(0, 7)}");
    printLongLogMessage("qrCode.substring(0, 7).compareTo(qrcode) ${qrCode.substring(0, 7).toLowerCase().compareTo("qrcode:")}");
    if (qrCode.length <= 7 || qrCode.substring(0, 7).toLowerCase().compareTo("qrcode:") != 0) {
      return false;
    }
    return true;
  }




}




