class CWMSHttpException implements Exception {
    final String _message;

    String get message => _message ?? this.runtimeType.toString();

    final int _code;

    int get code => _code ?? -1;

    CWMSHttpException([this._message, this._code]);

    String toString() {
        return "code:$code--message=$message";
    }
}

/// 客户端请求错误
class BadRequestException extends CWMSHttpException {
    BadRequestException({String message, int code}) : super(message, code);
}
/// 服务端响应错误
class BadServiceException extends CWMSHttpException {
    BadServiceException({String message, int code}) : super(message, code);
}



class UnknownException extends CWMSHttpException {
    UnknownException([String message]) : super(message);
}

class CancelException extends CWMSHttpException {
    CancelException([String message]) : super(message);
}

class NetworkException extends CWMSHttpException {
    NetworkException({String message, int code}) : super(message, code);
}

/// 401
class UnauthorisedException extends CWMSHttpException {
    UnauthorisedException({String message, int code = 401}) : super(message);
}

class BadResponseException extends CWMSHttpException {
    dynamic data;

    BadResponseException([this.data]) : super();
}

