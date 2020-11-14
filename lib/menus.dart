

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
        appBar: AppBar(title: Text("CWMS - Menu")),
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
                      Icon(IconData(int.parse(_menuGroup.menuSubGroups[index].icon), fontFamily: 'MaterialIcons')),
                      RaisedButton(
                        child: Text(_menuGroup.menuSubGroups[index].text),
                        onPressed: () => _onPressed(index),
                      ),
                    ],
                );



            }
        )
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
