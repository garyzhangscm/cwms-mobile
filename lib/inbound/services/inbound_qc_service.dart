import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/inventory/models/inventory.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request_item_option.dart';
import 'package:cwms_mobile/inventory/models/qc_rule.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:dio/dio.dart';

class InboundQCRequests {
  const InboundQCRequests(this.requests, {this.recoveredLegacy = false});
  final List<QCInspectionRequest> requests;
  final bool recoveredLegacy;
}

class InboundQCService {
  static Future<InboundQCRequests> loadRequests(Inventory inventory,
      {Dio? client}) async {
    final http = client ?? CWMSHttpClient.getDio();
    final parameters = {
      'warehouseId': Global.currentWarehouse!.id,
      'inventoryId': inventory.id,
    };
    final pending = await http.get('/inventory/qc-inspection-requests/pending',
        queryParameters: parameters);
    final requests =
        _data(pending).map((row) => QCInspectionRequest.fromJson(row)).toList();
    if (requests.isNotEmpty ||
        inventory.inboundQCRequired != true ||
        inventory.lastQCTime != null) {
      await _refreshEmptyRules(requests, http);
      return InboundQCRequests(requests);
    }

    // Some legacy tasks have a PASS header although every checkpoint is still
    // PENDING and no inspection was recorded. Read them without altering the
    // server record; only the user's normal QC submission may save a result.
    final history = await http.get('/inventory/qc-inspection-requests',
        queryParameters: parameters);
    final unfinished = _data(history)
        .where((row) => _isUnfinishedLegacy(row, inventory))
        .map((row) => QCInspectionRequest.fromJson(row)
          ..qcInspectionResult = QCInspectionResult.PENDING)
        .toList();
    await _refreshEmptyRules(unfinished, http);
    return InboundQCRequests(unfinished,
        recoveredLegacy: unfinished.isNotEmpty);
  }

  static Future<void> _refreshEmptyRules(
      List<QCInspectionRequest> requests, Dio http) async {
    final loadedRules = <int, QCRule>{};
    for (final request in requests) {
      if (request.qcInspectionResult != QCInspectionResult.PENDING ||
          request.qcTime != null) continue;
      for (final item in request.qcInspectionRequestItems) {
        final options = item.qcInspectionRequestItemOptions;
        final ruleId = item.qcRule?.id;
        if (ruleId == null ||
            options.any((option) => option.qcRuleItem?.enabled == true) ||
            options.any((option) =>
                option.qcInspectionResult != QCInspectionResult.PENDING))
          continue;
        // Old tasks retain checkpoint IDs from when they were created. If all
        // of those have since been disabled, load the current rule instead of
        // displaying a zero-check form. Changes remain in memory until submit.
        if (!loadedRules.containsKey(ruleId)) {
          final response = await http.get('/inventory/qc-rules/$ruleId',
              queryParameters: {'warehouseId': Global.currentWarehouse!.id});
          final body = _body(response);
          loadedRules[ruleId] =
              QCRule.fromJson(body['data'] as Map<String, dynamic>);
        }
        final rule = loadedRules[ruleId]!;
        item.qcRule = rule;
        final currentItems = {
          for (final ruleItem in rule.qcRuleItems) ruleItem.id: ruleItem
        };
        for (final option in options) {
          final current = currentItems[option.qcRuleItem?.id];
          if (current != null) option.qcRuleItem = current;
        }
        final existingIds =
            options.map((option) => option.qcRuleItem?.id).toSet();
        for (final checkpoint in rule.qcRuleItems) {
          if (checkpoint.enabled == true &&
              !existingIds.contains(checkpoint.id)) {
            options.add(QCInspectionRequestItemOption()
              ..qcRuleItem = checkpoint
              ..qcInspectionResult = QCInspectionResult.PENDING);
          }
        }
      }
    }
  }

  static dynamic _body(Response response) {
    final body = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    if (body['result'] != 0) {
      throw WebAPICallException('${body['result']}:${body['message']}');
    }
    return body;
  }

  static List<Map<String, dynamic>> _data(Response response) {
    final body = _body(response);
    return (body['data'] as List).cast<Map<String, dynamic>>();
  }

  static bool _isUnfinishedLegacy(
      Map<String, dynamic> row, Inventory inventory) {
    if (row['inventory']?['id'] != inventory.id ||
        row['warehouseId'] != Global.currentWarehouse!.id ||
        !['BY_INVENTORY', 'INBOUND_BY_INVENTORY'].contains(row['type']) ||
        row['qcInspectionResult'] != 'PASS' ||
        row['qcTime'] != null ||
        (row['qcUsername'] as String?)?.trim().isNotEmpty == true) {
      return false;
    }
    final items = row['qcInspectionRequestItems'] as List? ?? [];
    return items.isNotEmpty &&
        items.every((item) {
          final options = item['qcInspectionRequestItemOptions'] as List? ?? [];
          return item['qcInspectionResult'] == 'PENDING' &&
              options.isNotEmpty &&
              options
                  .every((option) => option['qcInspectionResult'] == 'PENDING');
        });
  }
}
