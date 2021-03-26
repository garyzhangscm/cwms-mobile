
import 'dart:convert';


import 'package:cwms_mobile/inventory/models/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:dio/dio.dart';

class CycleCountRequestService {
  // Get all cycle count requests by batch id
  static Future<List<CycleCountRequest>> getCycleCountRequestByBatchId(String batchId) async {
    Dio httpClient = CWMSHttpClient.getDio();


    print("start to get data from /inventory/cycle-count-request/batch/$batchId/open");
    Response response = await httpClient.get(
        "/inventory/cycle-count-request/batch/$batchId/open"
    );

    print("reponse from cycle count request: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    List<dynamic> responseData = responseString["data"];

    List<CycleCountRequest> cycleCountRequests
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : CycleCountRequest.fromJson(e as Map<String, dynamic>))
        ?.toList();

    return cycleCountRequests;
  }


  static Future<List<CycleCountResult>> getInventorySummariesForCounts(int cycleCountRequestId) async {
    Dio httpClient = CWMSHttpClient.getDio();


    print("start to get data from /cycle-count-request/$cycleCountRequestId/inventory-summary");
    Response response = await httpClient.get(
        "/inventory/cycle-count-request/$cycleCountRequestId/inventory-summary",
    );

    print("response from cycle count request / inventory summary: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    List<CycleCountResult> _cycleCountResults
    = (responseString["data"] as List)?.map((e) =>
        e == null ? null : CycleCountResult.fromJson(e as Map<String, dynamic>))
            ?.toList();
    return _cycleCountResults;
  }
}