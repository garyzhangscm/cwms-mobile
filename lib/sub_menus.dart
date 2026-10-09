import 'package:flutter/material.dart';
import 'auth/models/menu_sub_group.dart';
import 'i18n/localization_intl.dart';
import 'shared/MyDrawer.dart';
import 'shared/menu_navigation.dart';
import 'shared/workspace_ui.dart';
import 'workorder/models/defective_production.dart';
import 'workorder/services/defective_machines.dart';

class SubMenus extends StatefulWidget {
  @override
  State<SubMenus> createState() => _SubMenusState();
}

class _SubMenusState extends State<SubMenus> {
  bool _prefetchScheduled = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefetchScheduled) return;
    _prefetchScheduled = true;
    final group = ModalRoute.of(context)?.settings.arguments as MenuSubGroup?;
    if (withDefectiveProductionMenu(group?.menus ?? [])
            .any((menu) => menu.link == 'work_order_defective') &&
        hasRegisteredMenuRoute(context, 'work_order_defective')) {
      DefectiveMachineService.prefetch();
    }
  }

  String _inventoryOperationTitle(String title) {
    final normalized = title.trim().toLowerCase();
    if (normalized == 'inventory lost and found') return 'Lost & Found';
    if (normalized == 'partial inventory move') return 'Partial Move';
    if (normalized == 'inventory putaway') return 'Putaway';
    if (normalized == 'inventory qc') return 'QC';
    return title;
  }

  @override
  Widget build(BuildContext context) {
    final group = ModalRoute.of(context)!.settings.arguments as MenuSubGroup;
    final menus = withDefectiveProductionMenu(group.menus)
        .where((menu) => hasRegisteredMenuRoute(context, menu.link))
        .toList();
    if (menus.any((menu) => menu.link == 'work_order_produce')) {
      // Pair related operations in the order used on the shop floor.
      const order = [
        'work_order_produce',
        'work_order_reverse_production',
        'work_order_qc_sampling',
        'work_order_qc',
        'production_line_check_in',
        'production_line_check_out',
        'pick_by_work_order',
        'work_order_manual_pick',
        'work_order_defective',
      ];
      final originalOrder = List.of(menus);
      int rank(String? link) {
        final index = order.indexOf(link ?? '');
        return index < 0 ? order.length : index;
      }

      menus.sort((a, b) {
        final comparison = rank(a.link).compareTo(rank(b.link));
        return comparison != 0
            ? comparison
            : originalOrder.indexOf(a).compareTo(originalOrder.indexOf(b));
      });
    }
    final zh = workspaceIsChinese(context);
    final title = CWMSLocalizations.of(context)
        .getMenuDisplayText(group.i18n ?? '', group.text ?? group.name ?? '');
    final isInventoryPage = title.trim().toLowerCase() == 'inventory' ||
        group.name?.trim().toLowerCase() == 'inventory';
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
          child: WorkspaceNavigation(
              title: title,
              destinations: [
                ListTile(
                    selected: true,
                    leading: Icon(workspaceIcon(group.name ?? title)),
                    title: Text(title))
              ],
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
                              if (menus.isEmpty)
                                Text(zh ? '暂无可用作业' : 'No operations available'),
                              WorkspaceGrid(
                                  children:
                                      List.generate(menus.length, (index) {
                                final menu = menus[index];
                                final menuTitle =
                                    menu.link == 'work_order_defective'
                                        ? (zh ? '废品报产' : 'Defective')
                                        : CWMSLocalizations.of(context)
                                            .getMenuDisplayText(menu.i18n ?? '',
                                                menu.text ?? menu.name ?? '');
                                return WorkspaceTile(
                                    title: isInventoryPage
                                        ? _inventoryOperationTitle(menuTitle)
                                        : menuTitle,
                                    identity: '${menu.name} ${menu.link}',
                                    index: index,
                                    onTap: () => Navigator.of(context)
                                        .pushNamed(menu.link!));
                              })),
                            ]))),
              ))),
    );
  }
}
