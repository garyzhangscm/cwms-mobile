
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/states/profile_change_notifier.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../warehouse_layout/services/warehouse_location.dart';
import 'global.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      //移除顶部padding
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeader(), //构建抽屉菜单头部
            Expanded(child: _buildMenus()), //构建功能菜单
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<UserModel>(
      builder: (BuildContext context, UserModel value, Widget? child) {

        return GestureDetector(
          child: Container(
            color: Theme.of(context).primaryColor,
            padding: EdgeInsets.only(top: 80, bottom: 20),
            child: Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipOval(
                    child:  Image.asset(
                        "assets/images/avatar.png",
                        width: 80,
                      ),
                  ),
                ),
                Text(
                  Global.currentUser!.username!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              ],
            ),
          ),
          onTap: () {
            if (!value.isLogin) Navigator.of(context).pushNamed("login");
          },
        );
      },
    );
  }

  // 构建菜单项
  Widget _buildMenus() {
    return Consumer<UserModel>(
      builder: (BuildContext context, UserModel userModel, Widget? child) {
        var gm = CWMSLocalizations.of(context);
        return ListView(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(gm.language),
              onTap: () => Navigator.pushNamed(context, "language"),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_ind),
              title: Text(gm.workProfile),
              onTap: () => Navigator.pushNamed(context, "work_profile"),
            ),
            ListTile(
              leading: const Icon(Icons.power_settings_new),
              title: Text(gm.logout),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) {
                    //退出账号前先弹二次确认窗
                    return AlertDialog(
                      content: Text(gm.logoutTip),
                      actions: <Widget>[
                        ElevatedButton(
                          child: Text(gm.cancel),
                          onPressed: () => Navigator.pop(context),
                        ),
                        ElevatedButton(
                          child: Text(gm.yes),
                          onPressed: () {
                            //该赋值语句会触发MaterialApp rebuild
                            Global.logout();
                            Navigator.popUntil(context, ModalRoute.withName('login_page'));
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              title: Text(CWMSLocalizations.of(context).version + ": " + (Global.currentAPPVersion ?? "")),
            ),
            ListTile(
              title: Text(CWMSLocalizations.of(context)!.warehouse + ": " + (Global.currentWarehouse!.name ?? "")),
            ),
            ListTile(
              title: Text(CWMSLocalizations.of(context)!.rfCode + ": " + Global.getLastLoginRFCode()),
            ),
            ListTile(
              title: Text(CWMSLocalizations.of(context)!.currentLocation + ": " + (Global.getLastLoginRF().currentLocationName ?? "" )),
            ),
          ],
        );
      },
    );

  }

}