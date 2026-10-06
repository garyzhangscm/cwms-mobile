import 'package:flutter/material.dart';

import '../auth/models/menu_sub_group.dart';

// Server menus can include operations that this mobile build does not support.
// Use the actual route table so unsupported links never become visible tiles.
bool hasRegisteredMenuRoute(BuildContext context, String? link) {
  if (link == null || link.isEmpty) return false;
  return context
          .findAncestorWidgetOfExactType<MaterialApp>()
          ?.routes
          ?.containsKey(link) ==
      true;
}

bool hasAvailableMenuGroup(BuildContext context, MenuSubGroup group) {
  if (group.link?.isNotEmpty == true) {
    return hasRegisteredMenuRoute(context, group.link);
  }
  return group.menus.any((menu) => hasRegisteredMenuRoute(context, menu.link));
}
