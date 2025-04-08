
import 'dart:io';

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/models/cwms_default_http_transformer.dart';
import 'package:cwms_mobile/shared/services/navigation_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../../main.dart';
import 'cwms_dio.dart';
import 'cwms_http_config.dart';
import 'cwms_http_exception.dart';
import 'cwms_http_response.dart';
import 'cwms_http_transformer.dart';

class CWMSHttpClientAdapter {
    CWMSDio _dio;

    CWMSHttpClientAdapter({BaseOptions? options, CWMSHttpConfig? dioConfig})
        : _dio = CWMSDio(options: options, dioConfig: dioConfig);

    Future<CWMSHttpResponse> get(String uri,
        {Map<String, dynamic>? queryParameters,
            Options? options,
            CancelToken? cancelToken,
            ProgressCallback? onReceiveProgress,
            CWMSHttpTransformer? httpTransformer}) async {
            var response = await _dio.get(
                uri,
                queryParameters: queryParameters,
                options: options,
                cancelToken: cancelToken,
                onReceiveProgress: onReceiveProgress,
            );
            return handleResponse(response, httpTransformer: httpTransformer);
    }

    Future<CWMSHttpResponse?> post(String uri,
        {data,
            Map<String, dynamic>? queryParameters,
            Options? options,
            CancelToken? cancelToken,
            ProgressCallback? onSendProgress,
            ProgressCallback? onReceiveProgress,
            CWMSHttpTransformer? httpTransformer}) async {

        try{

          var response = await _dio.post(
            uri,
            data: data,
            queryParameters: queryParameters,
            options: options,
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
          );
          return handleResponse(response, httpTransformer: httpTransformer);
        }
        on DioError catch(ex) {
          printLongLogMessage("get DioError while call http post");
          printLongLogMessage("message: ${ex.message}");
          printLongLogMessage("response: ${ex.response}");
          printLongLogMessage("response.statusCode: ${ex.response?.statusCode}");
          printLongLogMessage("response.statusMessage: ${ex.response?.statusMessage}");
          printLongLogMessage("response.extra: ${ex.response?.extra}");
          printLongLogMessage("response.data: ${ex.response?.data}");
          printLongLogMessage("type: ${ex.type}");
          printLongLogMessage("error: ${ex.error}");

          if (ex.response?.statusCode == 401) {
            showYesNoDialog(NavigationService.navigatorKey.currentContext!,
                "User Not Login", "User is not login, please click Yes to go back to the login page and login",
                  () => Navigator.popUntil(NavigationService.navigatorKey.currentContext!, ModalRoute.withName('login_page')),
                  () {});
          }
          else {
            throw ex;
          }
        }

    }

    Future<CWMSHttpResponse> patch(String uri,
        {data,
            required Map<String, dynamic> queryParameters,
          required Options options,
          required CancelToken cancelToken,
          required ProgressCallback onSendProgress,
          required ProgressCallback onReceiveProgress,
          required CWMSHttpTransformer httpTransformer}) async {

            var response = await _dio.patch(
                uri,
                data: data,
                queryParameters: queryParameters,
                options: options,
                cancelToken: cancelToken,
                onSendProgress: onSendProgress,
                onReceiveProgress: onReceiveProgress,
            );
            return handleResponse(response, httpTransformer: httpTransformer);

    }

    Future<CWMSHttpResponse> delete(String uri,
        {data,
          required Map<String, dynamic> queryParameters,
          required Options options,
          required CancelToken cancelToken,
          required CWMSHttpTransformer httpTransformer}) async {

            var response = await _dio.delete(
                uri,
                data: data,
                queryParameters: queryParameters,
                options: options,
                cancelToken: cancelToken,
            );
            return handleResponse(response, httpTransformer: httpTransformer);

    }

    Future<CWMSHttpResponse> put(String uri,
        {data,
          Map<String, dynamic>? queryParameters,
          Options? options,
          CancelToken? cancelToken,
          CWMSHttpTransformer? httpTransformer}) async {

            var response = await _dio.put(
                uri,
                data: data,
                queryParameters: queryParameters,
                options: options,
                cancelToken: cancelToken,
            );
            return handleResponse(response, httpTransformer: httpTransformer);

    }

    Future<Response> download(String urlPath, savePath,
        {required ProgressCallback onReceiveProgress,
          required Map<String, dynamic> queryParameters,
          required CancelToken cancelToken,
            bool deleteOnError = true,
            String lengthHeader = Headers.contentLengthHeader,
            data,
          required Options options,
          required CWMSHttpTransformer httpTransformer}) async {

            var response = await _dio.download(
                urlPath,
                savePath,
                onReceiveProgress: onReceiveProgress,
                queryParameters: queryParameters,
                cancelToken: cancelToken,
                deleteOnError: deleteOnError,
                lengthHeader: lengthHeader,
                data: data,
                options: data,
            );
            return response;

    }
    CWMSHttpResponse handleResponse(Response response,
        {CWMSHttpTransformer? httpTransformer}) {
        httpTransformer ??= CWMSDefaultHttpTransformer.getInstance();

        CWMSHttpResponse cwmsHttpResponse = parseResponse(response, httpTransformer: httpTransformer);

        if (cwmsHttpResponse.ok != true) {

            BadRequestException ex = BadRequestException(
                message: cwmsHttpResponse.error?.message,
                code: cwmsHttpResponse.error?.code);


            throw ex;
        }
        else {
            return cwmsHttpResponse;
        }

    }
    CWMSHttpResponse parseResponse(Response response,
        {required CWMSHttpTransformer httpTransformer}) {
        httpTransformer ??= CWMSDefaultHttpTransformer.getInstance();

        // 返回值异常
        if (response == null) {
            return CWMSHttpResponse.failureFromError();
        }

        // token失效
        printLongLogMessage("response.statusCode: ${response.statusCode}");
        if (_isTokenTimeout(response.statusCode!)) {

            return CWMSHttpResponse.failureFromError(
                UnauthorisedException(message: "Not Auth", code: response.statusCode!));

        }
        // 接口调用成功
        if (_isRequestSuccess(response.statusCode!)) {

            return httpTransformer.parse(response);
        } else {
            // 接口调用失败
            return  CWMSHttpResponse.failure(
                errorMsg: response.statusMessage!, errorCode: response.statusCode!);


        }
    }

    CWMSHttpResponse handleException(Exception exception) {
        var parseException = _parseException(exception);
        return CWMSHttpResponse.failureFromError(parseException);
    }

    /// 鉴权失败
    bool _isTokenTimeout(int code) {
        return code == 401;
    }

    /// 请求成功
    bool _isRequestSuccess(int statusCode) {
        return (statusCode != null && statusCode >= 200 && statusCode < 300);
    }

    CWMSHttpException _parseException(Exception error) {
        if (error is DioException) {
            switch (error.type) {
                case DioExceptionType.connectionTimeout:
                case DioExceptionType.receiveTimeout:
                case DioExceptionType.sendTimeout:
                    return NetworkException(message: error.message);
                case DioExceptionType.cancel:
                    return CancelException(error.message);
                case DioExceptionType.badResponse:
                    try {
                        int errCode = error.response!.statusCode!;
                        switch (errCode) {
                            case 400:
                                return BadRequestException(
                                    message: CWMSLocalizations.of(MyApp.navigatorKey.currentContext!).httpError400,
                                    code: errCode);
                            case 401:
                                return UnauthorisedException(
                                    message: CWMSLocalizations.of(MyApp.navigatorKey.currentContext!).httpError401,
                                    code: errCode);
                            case 403:
                                return BadRequestException(
                                    message: CWMSLocalizations.of(MyApp.navigatorKey.currentContext!).httpError403,
                                    code: errCode);
                            case 404:
                                return BadRequestException(
                                    message: CWMSLocalizations.of(MyApp.navigatorKey.currentContext!).httpError404,
                                    code: errCode);
                            case 405:
                                return BadRequestException(
                                    message: CWMSLocalizations.of(MyApp.navigatorKey.currentContext!).httpError405,
                                    code: errCode);
                            case 500:
                                return BadServiceException(
                                    message: CWMSLocalizations.of(MyApp.navigatorKey.currentContext!).httpError500,
                                    code: errCode);
                            case 502:
                                return BadServiceException(
                                    message: CWMSLocalizations.of(MyApp.navigatorKey.currentContext!).httpError502,
                                    code: errCode);
                            case 503:
                                return BadServiceException(
                                    message: CWMSLocalizations.of(MyApp.navigatorKey.currentContext!).httpError503,
                                    code: errCode);
                            case 505:
                                return UnauthorisedException(
                                    message: CWMSLocalizations.of(MyApp.navigatorKey.currentContext!).httpError505,
                                    code: errCode);
                            default:
                                return UnknownException(error.message);
                        }
                    } on Exception catch (_) {
                        return UnknownException(error.message);
                    }
                    break;
                case DioExceptionType.unknown:
                    if (error.error is SocketException) {
                        return NetworkException(message: error.message);
                    } else {
                        return UnknownException(error.message);
                    }
                    break;
                default:
                    return UnknownException(error.message);
            }
        } else {
            return UnknownException(error.toString());
        }
    }


}
