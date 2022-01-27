

import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/models/cwms_http_response.dart';
import 'package:dio/dio.dart';

import 'cwms_http_transformer.dart';

class CWMSDefaultHttpTransformer extends CWMSHttpTransformer {
// 假设接口返回类型
//   {
//     "result": 0,
//     "data": {},
//     "message": "success"
// }
    @override
    CWMSHttpResponse parse(Response response) {
        if (response.data["result"] == 0) {
           return CWMSHttpResponse.success(response.data["data"]);
        } else {
            printLongLogMessage("errorMsg:${response.data['message']}");
            printLongLogMessage("errorCode:${response.data['result']}");
           return CWMSHttpResponse.failure(errorMsg:response.data["message"],errorCode: response.data["result"]);
        }
        // return CWMSHttpResponse.success(response.data["data"]);
    }

    /// 单例对象
    static CWMSDefaultHttpTransformer _instance = CWMSDefaultHttpTransformer._internal();

    /// 内部构造方法，可避免外部暴露构造函数，进行实例化
    CWMSDefaultHttpTransformer._internal();

    /// 工厂构造方法，这里使用命名构造函数方式进行声明
    factory CWMSDefaultHttpTransformer.getInstance() => _instance;
}
