import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/global.dart';
import '../models/material-consume-timing.dart';
import 'package:cwms_mobile/workorder/models/bill_of_material.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:dio/dio.dart';

class BillOfMaterialService {
  // Read the effective server configuration only when the order has no override.
  // Unknown/failed configuration must not be interpreted as "do not consume".
  static Future<bool> consumesAtReporting(WorkOrder order,
      {Dio? client, int? companyId, int? warehouseId}) async {
    final http = client ?? CWMSHttpClient.getDio();
    var timing = order.materialConsumeTiming;
    if (timing == null) {
      final response = await http.get('workorder/work-orders/${order.id}');
      final data = _responseData(response);
      final raw = data['materialConsumeTiming'];
      if (raw != null) timing = materialConsumeTimingFromString(raw as String);
    }
    if (timing == null) {
      final company = companyId ?? Global.lastLoginCompanyId;
      final warehouse =
          warehouseId ?? order.warehouseId ?? Global.currentWarehouse?.id;
      if (company == null || warehouse == null) {
        throw StateError(
            'Company and warehouse are required for consumption configuration');
      }
      final response = await http.get('workorder/work-order-configuration',
          queryParameters: {'companyId': company, 'warehouseId': warehouse});
      timing = materialConsumeTimingFromString(
          _responseData(response)['materialConsumeTiming'] as String);
    }
    return timing == MaterialConsumeTiming.BY_TRANSACTION;
  }

  static Map<String, dynamic> _responseData(Response response) {
    final raw =
        response.data is String ? jsonDecode(response.data) : response.data;
    if (raw is! Map || raw['result'] != 0 || raw['data'] is! Map) {
      throw StateError('Unable to read consumption configuration');
    }
    return Map<String, dynamic>.from(raw['data'] as Map);
  }

  static Future<BillOfMaterial?> loadForReporting(WorkOrder order) async {
    if (!await consumesAtReporting(order)) return null;
    return order.consumeByBom ?? await findMatchedBillOfMaterial(order);
  }

  // Find the BOM only for transactions configured to consume at reporting.
  static Future<BillOfMaterial?> findMatchedBillOfMaterial(
      WorkOrder workOrder) async {
    Dio httpClient = CWMSHttpClient.getDio();
    printLongLogMessage(
        "findMatchedBillOfMaterial by work order id ${workOrder.id}");

    Response response = await httpClient.get(
        "workorder/bill-of-materials/matched-with-work-order",
        queryParameters: {"workOrderId": workOrder.id});

    print("response from findMatchedBillOfMaterial: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage(
          "findMatchedBillOfMaterial / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() +
          ":" +
          responseString["message"]);
    }

    if (responseString["data"] != null) {
      return BillOfMaterial.fromJson(
          responseString["data"] as Map<String, dynamic>);
    } else {
      return null;
    }
  }
}
