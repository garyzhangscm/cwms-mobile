import 'package:flutter/material.dart';
import 'auth/models/menu_group.dart';
import 'auth/services/menu_service.dart';
import 'i18n/localization_intl.dart';
import 'shared/MyDrawer.dart';
import 'shared/workspace_ui.dart';

class Menus extends StatefulWidget {
  @override
  State<Menus> createState() => _MenusState();
}

class _MenusState extends State<Menus> {
  MenuGroup? _menuGroup;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _retrieveMenus();
  }

  Future<void> _retrieveMenus() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final group = await MenuService.getAccessibleMenus();
      if (!mounted) return;
      setState(() {
        _menuGroup = group;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final zh = workspaceIsChinese(context);
    final groups = _menuGroup?.menuSubGroups ?? [];
    String title(int index) => CWMSLocalizations.of(context).getMenuDisplayText(
        groups[index].i18n ?? '',
        groups[index].text ?? groups[index].name ?? '');
    final visible = List.generate(groups.length, (i) => i);
    return Scaffold(
      backgroundColor: workspaceBackground,
      appBar: AppBar(
          title: Text(zh ? '工作台' : 'Workspace'),
          backgroundColor: workspaceBackground,
          foregroundColor: workspaceNavy,
          elevation: 0,
          scrolledUnderElevation: 0),
      endDrawer: MyDrawer(),
      body: SafeArea(
          child: RefreshIndicator(
        onRefresh: _retrieveMenus,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        WorkspaceHeader(
                            title: zh
                                ? '让每一步作业，更有序。'
                                : 'Ready for the work ahead.',
                            subtitle: zh
                                ? '从收货到生产，在这里开启你的工作。'
                                : 'Your operations, connected. Choose a module to get started.'),
                        const SizedBox(height: 28),
                        Row(children: [
                          Text(zh ? '全部应用' : 'All applications',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: workspaceNavy)),
                          const Spacer(),
                          if (!_loading && !_failed)
                            Text('${groups.length}',
                                style:
                                    const TextStyle(color: Color(0xFF748297)))
                        ]),
                        const SizedBox(height: 16),
                        if (_loading)
                          const Padding(
                              padding: EdgeInsets.all(48),
                              child: Center(child: CircularProgressIndicator()))
                        else if (_failed)
                          Center(
                              child: Column(children: [
                            const SizedBox(height: 28),
                            Text(zh
                                ? '暂时无法加载应用'
                                : 'Unable to load applications'),
                            TextButton.icon(
                                onPressed: _retrieveMenus,
                                icon: const Icon(Icons.refresh),
                                label: Text(zh ? '重新加载' : 'Try again'))
                          ]))
                        else if (visible.isEmpty)
                          Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                  zh ? '暂无可用应用' : 'No applications available',
                                  style: const TextStyle(
                                      color: Color(0xFF748297))))
                        else
                          WorkspaceGrid(
                              children: visible
                                  .map((i) => WorkspaceTile(
                                      title: title(i),
                                      identity:
                                          '${groups[i].name} ${groups[i].link}',
                                      index: i,
                                      onTap: () {
                                        final group = groups[i];
                                        if (group.link?.isNotEmpty == true) {
                                          Navigator.of(context)
                                              .pushNamed(group.link!);
                                        } else {
                                          Navigator.of(context).pushNamed(
                                              'sub_menus_page',
                                              arguments: group);
                                        }
                                      }))
                                  .toList()),
                      ]))),
        ),
      )),
    );
  }
}
