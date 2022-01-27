

import 'package:dio/dio.dart';

import 'cwms_http_response.dart';

/// Response 解析
abstract class CWMSHttpTransformer {
    CWMSHttpResponse parse(Response response);
}

