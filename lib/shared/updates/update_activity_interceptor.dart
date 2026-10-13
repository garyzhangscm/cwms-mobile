import 'package:dio/dio.dart';
import 'update_activity.dart';

/// Also protects non-production pages and requests between business steps.
class UpdateActivityInterceptor extends Interceptor {
  final _requests = <RequestOptions>{};
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_requests.add(options)) UpdateActivity.instance.begin();
    handler.next(options);
  }

  void _finish(RequestOptions options) {
    if (_requests.remove(options)) UpdateActivity.instance.end();
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _finish(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    _finish(error.requestOptions);
    handler.next(error);
  }
}
