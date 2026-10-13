import 'package:flutter/material.dart';
import 'update_activity.dart';

class UpdateRouteObserver extends NavigatorObserver {
  final _popups = <Route<dynamic>>{};
  void _add(Route<dynamic>? route) {
    if (route is PopupRoute && _popups.add(route))
      UpdateActivity.instance.begin();
  }

  void _remove(Route<dynamic>? route) {
    if (_popups.remove(route)) UpdateActivity.instance.end();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _add(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _remove(route);
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _remove(route);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _remove(oldRoute);
    _add(newRoute);
  }
}
