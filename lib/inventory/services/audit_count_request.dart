
import 'dart:convert';


import 'package:cwms_mobile/inventory/models/audit_count_request.dart';
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

class AuditCountRequestService {
  // Get all cycle count requests by batch id
  static Future<List<AuditCountRequest>> getOpenAuditCountRequestByBatchId(
      String batchId) async {
    Dio httpClient = CWMSHttpClient.getDio();


    printLongLogMessage("start to get data from /inventory/audit-count-request/batch/$batchId");
    Response response = await httpClient.get(
        "/inventory/audit-count-request/batch/${Global.currentWarehouse.id}/$batchId"
    );

    printLongLogMessage("response from audit count request: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    List<dynamic> responseData = responseString["data"];

    List<AuditCountRequest> auditCountRequests
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : AuditCountRequest.fromJson(e as Map<String, dynamic>))
        ?.toList();

    return auditCountRequests;
  }

  static AuditCountRequest getNextLocationForCount(
      List<AuditCountRequest> auditCountRequests) {

    if (auditCountRequests.isEmpty) {
      return null;
    }
    AuditCountRequest nextAuditCountRequest = auditCountRequests[0];

    auditCountRequests
        .where((auditCountRequest) => auditCountRequest.skippedCount <= nextAuditCountRequest.skippedCount)
        .forEach((auditCountRequest) {
            if (nextAuditCountRequest.skippedCount > auditCountRequest.skippedCount) {
              // the last cycle has more time skipped than the current one, let's use the current one
              return nextAuditCountRequest = auditCountRequest;
            }
            else {
              // printLongLogMessage("Global.getLastActivityLocation(): ${Global.getLastActivityLocation().name}");
              WarehouseLocation nextLocation =
              WarehouseLocationService.getBestLocationForNextCount(
                  Global.getLastActivityLocation(),
                  nextAuditCountRequest.location,
                  auditCountRequest.location);

              if (nextLocation.name == auditCountRequest.location.name) {
                // OK, this location is better than last one, let's assign
                // it as the next best location
                nextAuditCountRequest = auditCountRequest;
              }
            }
    });

    return nextAuditCountRequest;

  }


  static Future<List<AuditCountResult>> getInventorySummariesForAuditCounts(
      AuditCountRequest auditCountRequest) async {

    Dio httpClient = CWMSHttpClient.getDio();



    Response response = await httpClient.get(
      "/inventory/audit-count-result/${auditCountRequest.batchId}/${auditCountRequest.locationId}/inventories",
    );

    printLongLogMessage("response from audit count request / inventory summary: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    List<AuditCountResult> _auditCountResults
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : AuditCountResult.fromJson(e as Map<String, dynamic>))
        ?.toList();
    return _auditCountResults;
  }



  static Future<List<AuditCountResult>> confirmAuditCount(
      AuditCountRequest auditCountRequest,
      List<AuditCountResult> inventories) async {

    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage("start to confirm ${inventories.length} inventory");
    inventories.forEach((element) {
      printLongLogMessage("inventory LPN: ${element.inventory.lpn}, inventory item: ${element.inventory.item.name}, inventory quantity ${element.inventory.quantity}, count quantity ${element.countQuantity}");
    });

    Response response = await httpClient.post(
        "inventory/audit-count-result/${auditCountRequest.batchId}/${auditCountRequest.locationId}/confirm",
        data: inventories
    );

    printLongLogMessage("response from audit count request / inventory summary: $response");

    Map<String, dynamic> responseString = json.decode(response.toString());

    List<AuditCountResult> _auditCountResults
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : AuditCountResult.fromJson(e as Map<String, dynamic>))
        ?.toList();

    return _auditCountResults;
  }


}