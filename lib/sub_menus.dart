

import 'package:cwms_mobile/auth/models/menu_sub_group.dart';
import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:cwms_mobile/shared/MyDrawer.dart';
import 'package:cwms_mobile/shared/bottom_navigation_bar.dart';
import 'package:cwms_mobile/shared/global.dart';
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


  MenuSubGroup _menuSubGroup;

  @override
  void initState() {
    super.initState();
    print("sub menu state init!");
    // _retrieveIcons();
    // 初始化数据
  }

  @override
  Widget build(BuildContext context) {

    _menuSubGroup = ModalRoute.of(context).settings.arguments;

    return Scaffold(
        appBar: AppBar(title: Text("CWMS - ${_menuSubGroup.text}")),
        /**
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
**/
        body: Stack(
          children:  [
            Container(
              child: Column(
                children: <Widget>[
                  menuItems
                ],
              ),
            )
          ],
        ),
        // bottomNavigationBar: buildBottomNavigationBar(context)
        endDrawer: MyDrawer(),
    );
  }


  get menuItems => Expanded(
    child: Container(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: GridView.count(
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        crossAxisCount: 2,
        childAspectRatio: .90,
        children: List.generate(
            _menuSubGroup == null ? 0 : _menuSubGroup.menus.length,
                (index) {
              return Card(
                child: InkWell(
                  onTap: () {
                    _onPressed(_menuSubGroup.menus[index]);
                  },
                  child:
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // FlutterLogo(),
                        Image(
                          image: NetworkImage(
                              Global.currentServer.url + "/resource/assets/images/mobile/" + _menuSubGroup.menus[index].icon),
                              // Global.currentServer.url + "/resource/assets/images/image_missing.png"),
                          //  "http://k8s-staging-zuulserv-707034e5d3-1316291729.us-west-1.elb.amazonaws.com/api/resource/assets/images/mobile/menu_outbound.jpg"),
                          width: 100.0,
                        ),
                        Text(CWMSLocalizations.of(context)
                            .getMenuDisplayText(
                            _menuSubGroup.menus[index].i18n,
                            _menuSubGroup.menus[index].text))],
                    ),
                  ),
                ),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)
                ),
              );
            }),
      ),
    ),
  );


  void _onPressed(Menu menu){

    print("will flow to menu: ${menu.link}");

    Navigator.of(context).pushNamed(menu.link);
  }




}
