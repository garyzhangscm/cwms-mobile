
import 'dart:convert';


import 'package:cwms_mobile/inventory/models/audit_count_result.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class AuditCountResultService {
  // Get all cycle count requests by batch id
  static Future<List<AuditCountResult>> getEmptyAuditCountResultDetails(
      String batchId, int locationId) async {

    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage("start to get data from /inventory/cycle-count-request/batch/$batchId/open");
    Response response = await httpClient.get(
        "/inventory/audit-count-result/$batchId/$locationId/inventories"
    );

    printLongLogMessage("reponse from cycle count request: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    List<dynamic> responseData = responseString["data"];

    List<AuditCountResult> auditCountResults
    = (responseString["data"] as List).map((e) => AuditCountResult.fromJson(e as Map<String, dynamic>))
        .toList();

    return auditCountResults;
  }





}