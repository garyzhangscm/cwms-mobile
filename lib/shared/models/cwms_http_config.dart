import 'package:dio/dio.dart';

class CWMSHttpConfig {
    final String baseUrl;
    final String proxy;
    final String cookiesPath;
    final List<Interceptor> interceptors;
    final int connectTimeout;
    final int sendTimeout;
    final int receiveTimeout;
    final Map<String, dynamic> headers;

    CWMSHttpConfig({
        this.baseUrl,
        this.proxy,
        this.cookiesPath,
        this.interceptors,
        this.connectTimeout = Duration.millisecondsPerMinute,
        this.sendTimeout = Duration.millisecondsPerMinute,
        this.receiveTimeout = Duration.millisecondsPerMinute,
        this.headers,
    });

}