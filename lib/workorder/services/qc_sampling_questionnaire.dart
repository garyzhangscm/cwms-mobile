import 'dart:math';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_result.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_rule_configuration.dart';
import 'package:cwms_mobile/workorder/models/work_order_qc_sample.dart';
import 'package:cwms_mobile/workorder/services/work_order_qc.dart';

/// One registration followed by one standard QC questionnaire. Keep this object
/// when navigating back from an unfinished inspection or recovering a timeout.
class QCSamplingQuestionnaire {
  QCSamplingQuestionnaire({
    bool Function()? isCurrentScope,
    Future<WorkOrderQCSample> Function(WorkOrderQCSample)? save,
    Future<List<WorkOrderQCRuleConfiguration>> Function(int)? configurations,
    Future<List<QCInspectionRequest>> Function(String)? inspections,
    Future<QCInspectionRequest> Function(int, String, int)? create,
  })  : _isCurrentScope = isCurrentScope ?? (() => true),
        _save = save ?? WorkOrderQCService.addWorkOrderQCSample,
        _configurations = configurations ??
            WorkOrderQCService.getMatchedWorkOrderQCRuleConfiguration,
        _inspections =
            inspections ?? WorkOrderQCService.getSampleInspectionRequests,
        _create = create ?? WorkOrderQCService.getWorkOrderQCInspectionRequest;

  final bool Function() _isCurrentScope;
  void _checkScope() {
    if (!_isCurrentScope())
      throw WebAPICallException(
          'The factory or user changed. Reopen QC Sampling.');
  }

  final Future<WorkOrderQCSample> Function(WorkOrderQCSample) _save;
  final Future<List<WorkOrderQCRuleConfiguration>> Function(int)
      _configurations;
  final Future<List<QCInspectionRequest>> Function(String) _inspections;
  final Future<QCInspectionRequest> Function(int, String, int) _create;
  WorkOrderQCSample? savedSample;
  QCInspectionRequest? request;
  bool registrationUncertain = false;
  bool _creationUncertain = false;
  bool _busy = false;

  Future<QCInspectionRequest> open(WorkOrderQCSample sample) async {
    if (_busy) throw StateError('QC Sampling is already processing.');
    _busy = true;
    try {
      _checkScope();
      if (registrationUncertain) {
        throw WebAPICallException(
            'Registration could not be confirmed. Check this sample number in Work Order QC before continuing. Do not register it again.');
      }
      if (savedSample == null) {
        try {
          savedSample = await _save(sample);
          if (savedSample!.id == null ||
              savedSample!.number != sample.number ||
              savedSample!.warehouseId != sample.warehouseId) {
            savedSample = null;
            throw StateError('Invalid sample registration response.');
          }
        } catch (_) {
          registrationUncertain = true;
          throw WebAPICallException(
              'Registration could not be confirmed. Check this sample number in Work Order QC before continuing. Do not register it again.');
        }
      }
      _checkScope();
      final stored = savedSample!;
      stored.productionLineAssignment ??= sample.productionLineAssignment;
      if (request != null) return request!;
      // Also recovers a request created on this device before a lost response.
      final pending = (await _inspections(stored.number!))
          .where((r) =>
              r.workOrderQCSampleId == stored.id &&
              r.warehouseId == stored.warehouseId &&
              r.type == 'BY_WORK_ORDER_SAMPLING' &&
              r.qcInspectionResult == QCInspectionResult.PENDING &&
              r.id != null)
          .toList();
      _checkScope();
      if (pending.length > 1) {
        throw WebAPICallException(
            'This sample has multiple pending inspections. Select the correct task in Inspection.');
      }
      if (pending.length == 1) return request = pending.single;
      if (_creationUncertain) {
        throw WebAPICallException(
            'The questionnaire could not be confirmed. Check Inspection before starting another task.');
      }
      final configurations = await _configurations(stored.id!);
      _checkScope();
      final ids = configurations
          .expand((c) => c.workOrderQCRuleConfigurationRules)
          .map((r) => r.qcRuleId)
          .whereType<int>()
          .toSet()
          .toList()
        ..sort();
      if (configurations.isEmpty || ids.isEmpty) {
        throw WebAPICallException(
            'Sample registered. No QC questionnaire is configured for this work order and production line.');
      }
      if (configurations
          .any((c) => c.qcQuantity == null || c.qcQuantity! < 0)) {
        throw WebAPICallException(
            'Sample registered. Check the QC quantity in QC Rule Configuration before continuing.');
      }
      final quantity = configurations.map((c) => c.qcQuantity!).reduce(max);
      try {
        final created = await _create(stored.id!, ids.join(','), quantity);
        if (created.id == null ||
            created.workOrderQCSampleId != stored.id ||
            created.warehouseId != stored.warehouseId ||
            created.qcInspectionResult != QCInspectionResult.PENDING) {
          throw StateError('Invalid questionnaire response.');
        }
        return request = created;
      } catch (_) {
        _creationUncertain = true;
        throw WebAPICallException(
            'The questionnaire could not be confirmed. Tap Continue questionnaire to check for the saved task before retrying.');
      }
    } finally {
      _busy = false;
    }
  }
}
