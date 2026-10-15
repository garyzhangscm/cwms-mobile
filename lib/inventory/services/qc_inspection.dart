import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/inventory/models/qc_inspection_request.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:dio/dio.dart';

class QCSubmissionException extends WebAPICallException {
  QCSubmissionException(String message, {this.outcomeUnknown = false})
      : super(message);
  final bool outcomeUnknown;
}

class QCInspectionService {
  static Future<List<QCInspectionRequest>> saveQCInspectionRequest(
    List<QCInspectionRequest> requests, {
    bool failureAcknowledged = false,
    Dio? client,
  }) async {
    return _save(requests,
        failureAcknowledged: failureAcknowledged,
        client: client,
        reviewed: true);
  }

  /// Luggage keeps its existing contract until its backend is upgraded.
  /// Do not use this method for factories with confirmed QC support.
  static Future<List<QCInspectionRequest>> saveLegacyQCInspectionRequest(
    List<QCInspectionRequest> requests, {
    bool failureAcknowledged = false,
    Dio? client,
  }) async {
    if (Global.currentFactory?.id != 'mira-loma-luggage') {
      throw QCSubmissionException(
          'This factory requires the confirmed QC interface.');
    }
    return _save(requests,
        failureAcknowledged: false, client: client, reviewed: false);
  }

  static Future<List<QCInspectionRequest>> _save(
    List<QCInspectionRequest> requests, {
    required bool reviewed,
    required bool failureAcknowledged,
    Dio? client,
  }) async {
    final http = client ?? CWMSHttpClient.getDio();
    final payload = jsonDecode(jsonEncode(requests)) as List;
    if (!reviewed) {
      for (final request in payload) {
        for (final group in request['qcInspectionRequestItems'] ?? []) {
          for (final option in group['qcInspectionRequestItemOptions'] ?? []) {
            option.remove('exceptionNotes');
          }
        }
      }
    }
    try {
      final response = await http.post(
        reviewed
            ? '/inventory/qc-inspection-requests/confirmed'
            : '/inventory/qc-inspection-requests',
        queryParameters: {
          'warehouseId': Global.currentWarehouse!.id,
          if (reviewed) 'failureAcknowledged': failureAcknowledged,
          'rfCode': Global.getLastLoginRFCode(),
        },
        options: Options(
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 40),
        ),
        data: jsonEncode(payload),
      );
      final body = _body(response);
      if (body['data'] is! List)
        throw QCSubmissionException(
          'The server response did not confirm the submission. Check QC status before retrying.',
          outcomeUnknown: true,
        );
      return (body['data'] as List)
          .map((e) => QCInspectionRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if ([404, 405].contains(e.response?.statusCode)) {
        throw QCSubmissionException(
          'This server does not support the updated QC interface yet. Your answers are retained. Contact the administrator.',
        );
      }
      throw QCSubmissionException(
        'The submission could not be confirmed. Your answers and notes are retained. Check submission status before retrying.',
        outcomeUnknown: ![
          400,
          401,
          403,
          409,
          422,
        ].contains(e.response?.statusCode),
      );
    }
  }

  /// Called once on entering an inspection, before any answer can be entered.
  /// The server supplies persisted checkpoint IDs and bounded legacy recovery.
  static Future<QCInspectionRequest> prepareForReview(
    QCInspectionRequest request, {
    Dio? client,
  }) async {
    if (request.id == null)
      throw QCSubmissionException(
        'This inspection has no saved identifier. Reload the task before continuing.',
      );
    final http = client ?? CWMSHttpClient.getDio();
    try {
      final response = await http.post(
        '/inventory/qc-inspection-request/${request.id}/prepare-review',
        queryParameters: {'warehouseId': Global.currentWarehouse!.id},
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );
      return QCInspectionRequest.fromJson(
        _body(response)['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      if ([404, 405].contains(e.response?.statusCode))
        throw QCSubmissionException(
          'The server QC update is not installed yet. Contact the administrator; no result was submitted.',
        );
      throw QCSubmissionException(
        'Could not prepare this inspection. Reload the task when the connection is available.',
      );
    }
  }

  static Future<QCInspectionRequest> getQCInspectionRequest(
    int id, {
    Dio? client,
  }) async {
    final http = client ?? CWMSHttpClient.getDio();
    final response = await http.get(
      '/inventory/qc-inspection-request/$id',
      queryParameters: {'warehouseId': Global.currentWarehouse!.id},
      options: Options(receiveTimeout: const Duration(seconds: 20)),
    );
    return QCInspectionRequest.fromJson(
      _body(response)['data'] as Map<String, dynamic>,
    );
  }

  static Map<String, dynamic> _body(Response response) {
    final raw = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    if (raw is! Map<String, dynamic>)
      throw QCSubmissionException(
        'Invalid QC response. Check submission status before retrying.',
        outcomeUnknown: true,
      );
    if (raw['result']?.toString() != '0')
      throw QCSubmissionException(
        '${raw['result']}: ${raw['message'] ?? 'QC submission was rejected.'}',
      );
    return raw;
  }
}
