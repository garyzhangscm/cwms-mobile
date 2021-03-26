import 'package:cwms_mobile/i18n/localization_intl.dart';
import 'package:flutter/material.dart';


Widget buildBottomNavigationBar(BuildContext context) {

  List<String> urls= ["menus_page", "account"];

  return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          // icon: Icon(Icons.home, color: Colors.blue),
            icon: new Image.asset("assets/images/icon-bottom-nav-home.png", height: 25),
            label:  CWMSLocalizations.of(context).home,
        ),
        BottomNavigationBarItem(
          //   icon: Icon(Icons.account_circle, color: Colors.blue),
            icon: new Image.asset("assets/images/icon-bottom-nav-me.png", height: 25),
            label:   CWMSLocalizations.of(context).account,
        )
      ],
      currentIndex: 0,
      onTap: (int index) {


        Navigator.of(context).pushNamed(urls[index]);
      }
  );

}