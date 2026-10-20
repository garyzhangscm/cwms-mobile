import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_result.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_rule_configuration.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_sample.dart';
import 'package:dio/dio.dart';

class WorkOrderQCService {
  // Get all cycle count requests by batch id
  static Future<WorkOrderQCSample?> getWorkOrderQCSampleByNumber(
      String workOrderQCSampleNumber) async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage(
        "Start to get work order sample by ${workOrderQCSampleNumber}");
    Response response = await httpClient.get("workorder/qc-samples",
        queryParameters: {
          "number": workOrderQCSampleNumber,
          "warehouseId": Global.currentWarehouse!.id
        });

    // printLongLogMessage("response from getWorkOrderQCSampleByNumber: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage(
          "getWorkOrderQCSampleByNumber / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() +
          ":" +
          responseString["message"]);
    }

    List<WorkOrderQCSample> workOrderQCSamples =
        (responseString["data"] as List)
            .map((e) => WorkOrderQCSample.fromJson(e as Map<String, dynamic>))
            .toList();

    printLongLogMessage("get QC samples: ${workOrderQCSamples.length}");
    // Sort the picks according to the current location. We
    // will assign the closed pick to the user
    if (workOrderQCSamples.length > 0) {
      return workOrderQCSamples.first;
    } else {
      return null;
    }
  }

  static Future<WorkOrderQCSample?>
      getWorkOrderQCSampleByProductionLineAssignment(
          int productionLineAssignmentId) async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage(
        "Start to get work order sample by production line assignment id: ${productionLineAssignmentId}");
    Response response =
        await httpClient.get("workorder/qc-samples", queryParameters: {
      "productionLineAssignmentId": productionLineAssignmentId,
      "warehouseId": Global.currentWarehouse!.id
    });

    // printLongLogMessage("response from getWorkOrderQCSampleByProductionLineAssignment: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage(
          "getWorkOrderQCSampleByProductionLineAssignment / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() +
          ":" +
          responseString["message"]);
    }

    List<WorkOrderQCSample> workOrderQCSamples =
        (responseString["data"] as List)
            .map((e) => WorkOrderQCSample.fromJson(e as Map<String, dynamic>))
            .toList();

    printLongLogMessage("get QC samples: ${workOrderQCSamples.length}");
    // Sort the picks according to the current location. We
    // will assign the closed pick to the user
    if (workOrderQCSamples.length > 0) {
      return workOrderQCSamples.first;
    } else {
      return null;
    }
  }

  static Future<WorkOrderQCResult> recordWorkOrderQCResult(
      WorkOrderQCResult workOrderQCResult) async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage(
        "Start to record work order result: ${workOrderQCResult.toJson()}");
    Response response = await httpClient.put("workorder/qc-results",
        data: jsonEncode(workOrderQCResult));

    // printLongLogMessage("response from recordWorkOrderQCResult: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage(
          "recordWorkOrderQCResult / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() +
          ":" +
          responseString["message"]);
    }

    return WorkOrderQCResult.fromJson(
        responseString["data"] as Map<String, dynamic>);
  }

  static Future<QCInspectionRequest> getWorkOrderQCInspectionRequest(
      int workOrderQCSampleId, String ruleIds, int qcQuantity) async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage(
        "Start to get work order inspection request by sampel id ${workOrderQCSampleId}, rule ids: ${ruleIds}");
    Response response = await httpClient
        .put("inventory/qc-inspection-requests/work-order", queryParameters: {
      "workOrderQCSampleId": workOrderQCSampleId,
      "ruleIds": ruleIds,
      "qcQuantity": qcQuantity,
      "warehouseId": Global.currentWarehouse!.id
    });

    // printLongLogMessage("response from getWorkOrderQCInspectionRequest: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage(
          "getWorkOrderQCInspectionRequest / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() +
          ":" +
          responseString["message"]);
    }

    return QCInspectionRequest.fromJson(
        responseString["data"] as Map<String, dynamic>);
  }

  static Future<List<WorkOrderQCRuleConfiguration>>
      getMatchedWorkOrderQCRuleConfiguration(int workOrderQCSampleId) async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage(
        "Start to get matched qc rule for work order by sample id ${workOrderQCSampleId}");
    Response response = await httpClient.get(
      "workorder/qc-rule-configuration/qc-samples/${workOrderQCSampleId}/matched",
    );

    // printLongLogMessage("response from getWorkOrderQCRules: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage(
          "getMatchedWorkOrderQCRuleConfiguration / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() +
          ":" +
          responseString["message"]);
    }

    List<WorkOrderQCRuleConfiguration> workOrderQCRuleConfigurationList =
        (responseString["data"] as List)
            .map((e) => WorkOrderQCRuleConfiguration.fromJson(
                e as Map<String, dynamic>))
            .toList();

    printLongLogMessage(
        "get ${workOrderQCRuleConfigurationList.length} configuration ");
    for (var workOrderQCRuleConfiguration in workOrderQCRuleConfigurationList) {
      printLongLogMessage(
          "workOrderQCRuleConfiguration id ${workOrderQCRuleConfiguration.id} has ${workOrderQCRuleConfiguration.workOrderQCRuleConfigurationRules.length} rules");
    }
    return workOrderQCRuleConfigurationList;
  }

  /// Read before starting/recovering a Sampling questionnaire. This never creates
  /// a request; the work-order PUT is not idempotent and must not be retried.
  static Future<List<QCInspectionRequest>> getSampleInspectionRequests(
      String sampleNumber) async {
    final response = await CWMSHttpClient.getDio().get(
      'inventory/qc-inspection-requests',
      queryParameters: {
        'warehouseId': Global.currentWarehouse!.id,
        'workOrderQCSampleNumber': sampleNumber,
        'type': 'BY_WORK_ORDER_SAMPLING',
      },
    );
    final body = json.decode(response.toString()) as Map<String, dynamic>;
    if (body['result'] != 0 || body['data'] is! List) {
      throw WebAPICallException(
          body['message']?.toString() ?? 'Could not load sample inspections.');
    }
    return (body['data'] as List)
        .map((e) => QCInspectionRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<WorkOrderQCSample> addWorkOrderQCSample(
      WorkOrderQCSample workOrderQCSample,
      {Dio? client}) async {
    final registrant = Global.currentUser?.username?.trim();
    if (registrant == null || registrant.isEmpty) {
      throw WebAPICallException(
          'Please sign in again before registering a QC sample.');
    }
    final httpClient = client ?? CWMSHttpClient.getDio();

    printLongLogMessage(
        "Start to add work order sample by number ${workOrderQCSample.number}");
    Response response = await httpClient.put("workorder/qc-samples",
        queryParameters: {"warehouseId": Global.currentWarehouse!.id},
        // The backend records the gateway user in the existing creation audit.
        // Resolve this per submission so an RF reused by another user is correct.
        options: Options(headers: {'username': registrant}),
        data: jsonEncode(workOrderQCSample));

    // printLongLogMessage("response from addWorkOrderQCSample: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage(
          "addWorkOrderQCSample / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() +
          ":" +
          responseString["message"]);
    }

    return WorkOrderQCSample.fromJson(
        responseString["data"] as Map<String, dynamic>);
  }
}
