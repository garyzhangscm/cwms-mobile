
import 'dart:convert';


import 'package:cwms_mobile/inventory/models/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/warehouse_layout/services/warehouse_location.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class CycleCountRequestService {
  // Get all cycle count requests by batch id
  static Future<List<CycleCountRequest>> getCycleCountRequestByBatchId(String batchId) async {
    Dio httpClient = CWMSHttpClient.getDio();


    printLongLogMessage("start to get data from /inventory/cycle-count-request/batch/$batchId/open");
    Response response = await httpClient.get(
        "/inventory/cycle-count-request/batch/${Global.currentWarehouse.id}/$batchId/open"
    );

    printLongLogMessage("reponse from cycle count request: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    List<dynamic> responseData = responseString["data"];

    List<CycleCountRequest> cycleCountRequests
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : CycleCountRequest.fromJson(e as Map<String, dynamic>))
        ?.toList();

    return cycleCountRequests;
  }


  static Future<List<CycleCountResult>> getInventorySummariesForCounts(
      int cycleCountRequestId) async {
    Dio httpClient = CWMSHttpClient.getDio();


    printLongLogMessage("start to get data from /cycle-count-request/$cycleCountRequestId/inventory-summary");
    Response response = await httpClient.get(
        "/inventory/cycle-count-request/$cycleCountRequestId/inventory-summary",
    );

    printLongLogMessage("response from cycle count request / inventory summary: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    List<CycleCountResult> _cycleCountResults
    = (responseString["data"] as List)?.map((e) =>
        e == null ? null : CycleCountResult.fromJson(e as Map<String, dynamic>))
            ?.toList();
    return _cycleCountResults;
  }

  static CycleCountRequest getNextLocationForCount(
      List<CycleCountRequest> cycleCountRequests) {

    if (cycleCountRequests.isEmpty) {
      return null;
    }
    CycleCountRequest nextCycleCountRequest = cycleCountRequests[0];

    cycleCountRequests.forEach((cycleCountRequest) {
      // printLongLogMessage("Global.getLastActivityLocation(): ${Global.getLastActivityLocation().name}");
      WarehouseLocation nextLocation =
          WarehouseLocationService.getBestLocationForNextCount(
              Global.getLastActivityLocation(),
              nextCycleCountRequest.location,
              cycleCountRequest.location);

      if (nextLocation.name == cycleCountRequest.location.name) {
        // OK, this location is better than last one, let's assign
        // it as the next best location
        nextCycleCountRequest = cycleCountRequest;
      }
    });

    return nextCycleCountRequest;

  }

  static Future<List<CycleCountResult>> confirmCycleCount(CycleCountRequest cycleCountRequest,
      List<CycleCountResult> inventorySummaries) async {

    Dio httpClient = CWMSHttpClient.getDio();


    Response response = await httpClient.post(
      "inventory/cycle-count-request/${cycleCountRequest.id}/confirm",
      data: inventorySummaries
    );


    Map<String, dynamic> responseString = json.decode(response.toString());

    List<CycleCountResult> _cycleCountResults
      = (responseString["data"] as List)?.map((e) =>
      e == null ? null : CycleCountResult.fromJson(e as Map<String, dynamic>))
          ?.toList();

    return _cycleCountResults;
  }

  static Future<CycleCountRequest> cancelCycleCount(CycleCountRequest cycleCountRequest) async {

    Dio httpClient = CWMSHttpClient.getDio();


    Response response = await httpClient.post(
        "inventory/cycle-count-request/cancel",
        queryParameters: {"cycleCountRequestIds": cycleCountRequest.id});


    Map<String, dynamic> responseString = json.decode(response.toString());

    List<CycleCountRequest> _cycleCountRequests
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : CycleCountRequest.fromJson(e as Map<String, dynamic>))
          ?.toList();

    // Since we only cancel one request, it should only return one result
    if (_cycleCountRequests.length == 1) {
      return _cycleCountRequests[0];
    }
    else {
      return null;
    }
  }

}