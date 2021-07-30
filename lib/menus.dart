

import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/bottom_navigation_bar.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'auth/services/menu_service.dart';
import 'package:cwms_mobile/auth/models/menu_group.dart';



class Menus extends StatefulWidget {
    @override
    _MenusState createState() => new _MenusState();
}

class _MenusState extends State<Menus> {


  MenuGroup _menuGroup;

  @override
  void initState() {
    super.initState();

    // 初始化数据
    _retrieveIcons();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(title: Text(
            "CWMS"
        )),
        body: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, //每行三列
                childAspectRatio: 1.0 //显示区域宽高相等
            ),
            itemCount: _menuGroup == null ? 0 : _menuGroup.menuSubGroups.length,

            itemBuilder: (context, index) {
              return
                Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Icon(IconData(int.parse(_menuGroup.menuSubGroups[index].icon), fontFamily: 'MaterialIcons')),
                      Icon(IconData(int.parse(_menuGroup.menuSubGroups[index].icon), fontFamily: 'MaterialIcons')),
                      RaisedButton(
                        child: Text(
                            CWMSLocalizations.of(context)
                                .getMenuDisplayText(
                                    _menuGroup.menuSubGroups[index].i18n,
                                    _menuGroup.menuSubGroups[index].text)),
                        onPressed: () => _onPressed(index),
                      ),
                    ],
                );



            }
        ),
        // bottomNavigationBar: buildBottomNavigationBar(context)

        endDrawer: MyDrawer(),
    );
  }

  //模拟异步获取数据
  void _retrieveIcons() async {
    MenuService.getAccessibleMenus().then(
        (e) {
          setState(() {
            _menuGroup = e;
          });
        }
    );
  }
  void _onPressed(int index){


    Navigator.of(context).pushNamed("sub_menus_page", arguments: _menuGroup.menuSubGroups[index]);


  }




}
