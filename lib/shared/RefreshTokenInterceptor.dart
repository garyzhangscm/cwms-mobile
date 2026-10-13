import 'package:dio/dio.dart';

import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/services/navigation_service.dart';

import 'package:flutter/widgets.dart';

//
//https://medium.com/@chehansivaruban/implementing-token-refresh-in-flutter-with-dio-interceptor-88d14181d68b
class RefreshTokenInterceptor extends Interceptor {
  RefreshTokenInterceptor();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      Global.logout();
      NavigationService.navigatorKey.currentState
          ?.popUntil(ModalRoute.withName('login_page'));
    }
    // Every error must reach the awaiting business action, including 401/403.
    handler.next(err);
  }
}
