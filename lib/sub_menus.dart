import 'package:flutter/material.dart';
import 'auth/models/menu_sub_group.dart';
import 'i18n/localization_intl.dart';
import 'shared/MyDrawer.dart';
import 'shared/workspace_ui.dart';

class SubMenus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final group = ModalRoute.of(context)!.settings.arguments as MenuSubGroup;
    final zh = workspaceIsChinese(context);
    final title = CWMSLocalizations.of(context)
        .getMenuDisplayText(group.i18n ?? '', group.text ?? group.name ?? '');
    return Scaffold(
      backgroundColor: workspaceBackground,
      appBar: AppBar(
          title: Text(title),
          backgroundColor: workspaceBackground,
          foregroundColor: workspaceNavy,
          elevation: 0,
          scrolledUnderElevation: 0),
      endDrawer: MyDrawer(),
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WorkspaceHeader(
                          title: title,
                          subtitle: zh
                              ? '选择作业，开始处理。'
                              : 'Choose an operation to get started.'),
                      const SizedBox(height: 28),
                      Text(zh ? '作业功能' : 'Operations',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: workspaceNavy)),
                      const SizedBox(height: 16),
                      if (group.menus.isEmpty)
                        Text(zh ? '暂无可用作业' : 'No operations available'),
                      WorkspaceGrid(
                          children: List.generate(group.menus.length, (index) {
                        final menu = group.menus[index];
                        return WorkspaceTile(
                            title: CWMSLocalizations.of(context)
                                .getMenuDisplayText(menu.i18n ?? '',
                                    menu.text ?? menu.name ?? ''),
                            identity: '${menu.name} ${menu.link}',
                            index: index,
                            onTap: menu.link?.isNotEmpty == true
                                ? () =>
                                    Navigator.of(context).pushNamed(menu.link!)
                                : null);
                      })),
                    ]))),
      )),
    );
  }
}
