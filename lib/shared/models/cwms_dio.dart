

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'cwms_http_config.dart';

class CWMSDio with DioMixin implements Dio {
    CWMSDio({BaseOptions? options, CWMSHttpConfig? dioConfig}) {
        options ??= BaseOptions(
            baseUrl: dioConfig?.baseUrl ?? "",
            contentType: 'application/json',
            connectTimeout: Duration(milliseconds: dioConfig?.connectTimeout ?? 0),
            sendTimeout: Duration(milliseconds: dioConfig?.sendTimeout ?? 0),
            receiveTimeout: Duration(milliseconds: dioConfig?.receiveTimeout ?? 0),
            headers: dioConfig?.headers
        );
        this.options = options;

        // DioCacheManager
        // NOT SUPPORTED IN CURRENT DIO VERSION
        /***
        final cacheOptions = CacheOptions(
            // A default store is required for interceptor.
            store: MemCacheStore(),
            // Optional. Returns a cached response on error but for statuses 401 & 403.
            hitCacheOnErrorExcept: [401, 403],
            // Optional. Overrides any HTTP directive to delete entry past this duration.
            maxStale: const Duration(days: 7),
        );
        interceptors.add(DioCacheInterceptor(options: cacheOptions));
            ***/
        // Cookie管理
        // NOT SUPPORTED IN CURRENT DIO VERSION
        /**
        if (dioConfig?.cookiesPath?.isNotEmpty ?? false) {
            interceptors.add(CookieManager(
                PersistCookieJar(storage: FileStorage(dioConfig!.cookiesPath))));
        }
            **/

        // add log to each http call
        interceptors.add(LogInterceptor(
                responseBody: true,
                error: true,
                requestHeader: false,
                responseHeader: false,
                request: false,
                requestBody: true));

        if (dioConfig?.interceptors?.isNotEmpty ?? false) {
            interceptors.addAll(interceptors);
        }
        httpClientAdapter = IOHttpClientAdapter();
    }

}


