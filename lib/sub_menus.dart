

import 'package:cwms_mobile/auth/models/menu_sub_group.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'auth/models/menu.dart';
import 'auth/services/menu_service.dart';
import 'package:cwms_mobile/auth/models/menu_group.dart';



class SubMenus extends StatefulWidget {
    @override
    _SubMenusState createState() => new _SubMenusState();
}

class _SubMenusState extends State<SubMenus> {


  MenuGroup _menuGroup;

  @override
  void initState() {
    super.initState();
    print("sub menu state init!");
    // _retrieveIcons();
    // 初始化数据
  }

  @override
  Widget build(BuildContext context) {

    MenuSubGroup _menuSubGroup = ModalRoute.of(context).settings.arguments;

    return Scaffold(
        appBar: AppBar(title: Text("CWMS - ${_menuSubGroup.text}")),
        body: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, //每行三列
                childAspectRatio: 1.0 //显示区域宽高相等
            ),
            itemCount: _menuSubGroup.menus.length,

            itemBuilder: (context, index) {
              return
                Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Icon(IconData(int.parse(_menuSubGroup.menus[index].icon), fontFamily: 'MaterialIcons')),
                      RaisedButton(
                        child: Text(
                            CWMSLocalizations.of(context)
                                .getMenuDisplayText(
                                    _menuSubGroup.menus[index].i18n,
                                    _menuSubGroup.menus[index].text)),
                        onPressed: () => _onPressed(_menuSubGroup.menus[index]),
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
    print("_retrieveIcons!");
    MenuService.getAccessibleMenus().then(
        (e) {
          setState(() {
            _menuGroup = e;
          });
        }
    );
    /***
    Future.delayed(Duration(milliseconds: 200)).then((e) {
      setState(() {
        _icons.addAll([
          Icons.ac_unit,
          Icons.airport_shuttle,
          Icons.all_inclusive,
          Icons.beach_access, Icons.cake,
          Icons.free_breakfast
        ]);
      });
    });
        **/
  }
  void _onPressed(Menu menu){

    print("will flow to menu: ${menu.link}");

    Navigator.of(context).pushNamed(menu.link);
  }




}
