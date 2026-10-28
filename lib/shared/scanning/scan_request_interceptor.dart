import 'package:dio/dio.dart';
import 'scan_feedback.dart';
import 'server_connection.dart';

class ScanRequestInterceptor extends Interceptor {
  static const _attemptKey = 'cwms.scanAttempt';
  static const _scopeKey = 'cwms.connectionScope';
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_scopeKey] = ServerConnectionMonitor.shared.profile()?.scope;
    final attempt = ScanFeedback.current;
    if (attempt != null) {
      options.extra[_attemptKey] = attempt;
      options.connectTimeout ??= const Duration(seconds: 8);
      options.sendTimeout ??= const Duration(seconds: 15);
      options.receiveTimeout ??= const Duration(seconds: 45);
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final status = response.statusCode ?? 0;
    if (status == 401 || status == 408 || status >= 500) {
      final attempt =
          response.requestOptions.extra[_attemptKey] as ScanAttempt?;
      if (attempt != null && !attempt.completed) attempt.uncertain = true;
    }
    ServerConnectionMonitor.shared.note(
        response.requestOptions.baseUrl, response.statusCode,
        scope: response.requestOptions.extra[_scopeKey] as String?);
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    if (ScanFeedback.isUncertain(error)) {
      final attempt = error.requestOptions.extra[_attemptKey] as ScanAttempt?;
      if (attempt != null && !attempt.completed) attempt.uncertain = true;
    }
    if (error.type != DioExceptionType.cancel) {
      ServerConnectionMonitor.shared.note(
          error.requestOptions.baseUrl, error.response?.statusCode,
          transportFailure: error.response == null,
          scope: error.requestOptions.extra[_scopeKey] as String?);
    }
    handler.next(error);
  }
}
