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
    final http = client ?? CWMSHttpClient.getDio();
    try {
      final response = await http.post(
        '/inventory/qc-inspection-requests/confirmed',
        queryParameters: {
          'warehouseId': Global.currentWarehouse!.id,
          'failureAcknowledged': failureAcknowledged,
          'rfCode': Global.getLastLoginRFCode(),
        },
        options: Options(
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 40),
        ),
        data: jsonEncode(requests),
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
