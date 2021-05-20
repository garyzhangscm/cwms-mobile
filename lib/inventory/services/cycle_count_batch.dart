
import 'dart:convert';


import 'package:cwms_mobile/inventory/models/cycle_count_batch.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_request.dart';
import 'package:cwms_mobile/inventory/models/cycle_count_result.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:dio/dio.dart';

class CycleCountBatchService {
  // Get all cycle count requests by batch id
  static Future<List<CycleCountBatch>> getCycleCountBatchesWithOpenCycleCount() async {
    Dio httpClient = CWMSHttpClient.getDio();

   Response response = await httpClient.get(
        "/inventory/cycle-count-batches/open-with-cycle-count"
    );

    printLongLogMessage("response from open cycle count batch: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());


    List<CycleCountBatch> cycleCountBatches
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : CycleCountBatch.fromJson(e as Map<String, dynamic>))
        ?.toList();

    return cycleCountBatches;
  }


  static Future<List<CycleCountBatch>> getCycleCountBatchesWithOpenAuditCount() async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/inventory/cycle-count-batches/open-with-audit-count"
    );

    printLongLogMessage("response from open audit count batch: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());


    List<CycleCountBatch> cycleCountBatches
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : CycleCountBatch.fromJson(e as Map<String, dynamic>))
        ?.toList();

    return cycleCountBatches;
  }

  static Future<List<CycleCountBatch>> getOpenCycleCountBatches() async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/inventory/cycle-count-batches/open"
    );

    printLongLogMessage("reponse from open audit count batch: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());


    List<CycleCountBatch> cycleCountBatches
    = (responseString["data"] as List)?.map((e) =>
        e == null ? null : CycleCountBatch.fromJson(e as Map<String, dynamic>))
            ?.toList();

    return cycleCountBatches;
  }



  static Future<CycleCountBatch> getCycleCountBatchByBatchId(String batchId) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/inventory/cycle-count-batches",
        queryParameters: {"batchId": batchId,
          "warehouseId": Global.currentWarehouse.id}
    );

    printLongLogMessage("response from getCycleCountBatchByBatchId: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());


    List<CycleCountBatch> cycleCountBatches
    = (responseString["data"] as List)?.map((e) =>
        e == null ? null : CycleCountBatch.fromJson(e as Map<String, dynamic>))
            ?.toList();
    if (cycleCountBatches.length == 1) {
      return cycleCountBatches[0];
    }
    else {
      return null;
    }

  }


}