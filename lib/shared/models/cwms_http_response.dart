import 'package:cwms_mobile/shared/models/cwms_http_exception.dart';

class CWMSHttpResponse {
    bool ok;
    dynamic data;
    CWMSHttpException error;

    CWMSHttpResponse._internal({this.ok = false});

    CWMSHttpResponse.success(this.data) {
        this.ok = true;
    }

    CWMSHttpResponse.failure({String errorMsg, int errorCode}) {
        this.error = BadRequestException(message: errorMsg, code: errorCode);
        this.ok = false;
    }

    CWMSHttpResponse.failureFormResponse({dynamic data}) {
        this.error = BadResponseException(data);
        this.ok = false;
    }

    CWMSHttpResponse.failureFromError([CWMSHttpException error]) {
        this.error = error ?? UnknownException();
        this.ok = false;
    }
}
