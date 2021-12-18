
import 'dart:convert';


import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/inventory_deposit_request.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:dio/dio.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

class QCInspectionService {
  // Get inventory that on the current RF
  static Future<List<QCInspectionRequest>> saveQCInspectionRequest(List<QCInspectionRequest> qcInspectionRequests) async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage("will save qc inspection request");

    Response response = await httpClient.post(
        "/inventory/qc-inspection-requests",
      queryParameters: {'warehouseId': Global.lastLoginCompanyId,
          'rfCode': Global.getLastLoginRFCode()},
        data: qcInspectionRequests
    );


    Map<String, dynamic> responseString = json.decode(response.toString());
    printLongLogMessage("response from saveQCInspectionRequest: ${responseString} ");

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"] + ":" + responseString["message"]);
    }

    return (responseString["data"] as List)?.map((e) =>
            e == null ? null : QCInspectionRequest.fromJson(e as Map<String, dynamic>))
              ?.toList();


  }



}