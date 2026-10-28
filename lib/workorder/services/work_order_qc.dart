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
import 'package:flutter/foundation.dart';

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

  static final _latestUnavailableUntil = Expando<DateTime>();

  static Future<WorkOrderQCSample?>
      getWorkOrderQCSampleByProductionLineAssignment(
          int productionLineAssignmentId,
          {Dio? client,
          int? warehouseId}) async {
    final http = client ?? CWMSHttpClient.getDio();
    final warehouse = warehouseId ?? Global.currentWarehouse!.id;
    if (warehouse == null ||
        warehouse <= 0 ||
        productionLineAssignmentId <= 0) {
      throw ArgumentError(
          'Valid warehouse and production line assignment required');
    }
    final query = {
      'productionLineAssignmentId': productionLineAssignmentId,
      'warehouseId': warehouse
    };
    final timer = Stopwatch()..start();
    final unavailableUntil = _latestUnavailableUntil[http];
    var legacy =
        unavailableUntil != null && DateTime.now().isBefore(unavailableUntil);
    Response response;
    if (legacy) {
      response = await http.get('workorder/qc-samples', queryParameters: query);
    } else {
      try {
        response = await http.get('workorder/qc-samples/assignment/latest',
            queryParameters: query);
      } on DioException catch (error) {
        // Compatibility for servers that have not received the new endpoint.
        // Never double a timed-out, unauthorized or failing request.
        if (error.response?.statusCode != 404) rethrow;
        legacy = true;
        _latestUnavailableUntil[http] =
            DateTime.now().add(const Duration(minutes: 5));
        response =
            await http.get('workorder/qc-samples', queryParameters: query);
      }
    }
    debugPrint(
        '[QC Sampling timing] latest sample HTTP: ${timer.elapsedMilliseconds} ms; legacy=$legacy');
    timer.reset();
    final body = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    if (body is! Map || body['result'] != 0) {
      throw WebAPICallException(body is Map
          ? '${body['message'] ?? "QC sample lookup failed"}'
          : 'Invalid QC sample response');
    }
    final rows = body['data'];
    if (rows is! List || (!legacy && rows.length > 1)) {
      throw WebAPICallException('Invalid latest QC sample response');
    }
    // Even on an older server, deserialize only the selected latest record.
    final sample = rows.isEmpty
        ? null
        : WorkOrderQCSample.fromJson(
            Map<String, dynamic>.from(rows.first as Map));
    debugPrint(
        '[QC Sampling timing] latest sample decode: ${timer.elapsedMilliseconds} ms; returned=${rows.length}');
    return sample;
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
      getMatchedWorkOrderQCRuleConfiguration(int workOrderQCSampleId,
          {bool samplingSummaryOnly = false}) async {
    Dio httpClient = CWMSHttpClient.getDio();

    printLongLogMessage(
        "Start to get matched qc rule for work order by sample id ${workOrderQCSampleId}");
    Response response = await httpClient.get(
      "workorder/qc-rule-configuration/qc-samples/${workOrderQCSampleId}/matched",
    );

    // printLongLogMessage("response from getWorkOrderQCRules: $response");
    Map<String, dynamic> responseString =
        samplingSummaryOnly && response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage(
          "getMatchedWorkOrderQCRuleConfiguration / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() +
          ":" +
          responseString["message"]);
    }

    final rows = responseString['data'] as List;
    if (samplingSummaryOnly) return parseSamplingConfigurations(rows);

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

  /// Sampling needs the matched rule identifiers and quantity, not nested
  /// question text, work orders or production-line detail. The server still
  /// performs the same matching and the inspection page loads trusted questions.
  static List<WorkOrderQCRuleConfiguration> parseSamplingConfigurations(
          List rows) =>
      rows.map((value) {
        final row = value as Map<String, dynamic>;
        return WorkOrderQCRuleConfiguration.fromJson({
          'id': row['id'],
          'warehouseId': row['warehouseId'],
          'qcQuantity': row['qcQuantity'],
          'workOrderQCRuleConfigurationRules':
              (row['workOrderQCRuleConfigurationRules'] as List?)?.map((value) {
            final rule = value as Map<String, dynamic>;
            return {'id': rule['id'], 'qcRuleId': rule['qcRuleId']};
          }).toList(),
        });
      }).toList();

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
        'qcInspectionResult': 'PENDING',
      },
    );
    final body = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : json.decode(response.toString()) as Map<String, dynamic>;
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
