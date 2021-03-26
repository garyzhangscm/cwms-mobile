import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'messages_all.dart'; //1

class CWMSLocalizations {
  static Future<CWMSLocalizations> load(Locale locale) {
    final String name = locale.countryCode.isEmpty ? locale.languageCode : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);
    //2
    return initializeMessages(localeName).then((b) {
      Intl.defaultLocale = localeName;
      return new CWMSLocalizations();
    });
  }

  static CWMSLocalizations of(BuildContext context) {
    return Localizations.of<CWMSLocalizations>(context, CWMSLocalizations);
  }

  String get title {
    return Intl.message(
      'CWMS',
      name: 'title',
      desc: 'CWMS',
    );
  }
  String get home => Intl.message('Home', name: 'home');

  String get language => Intl.message('Language', name: 'language');

  String get login => Intl.message('Login', name: 'login');

  String get account => Intl.message('Account', name: 'account');

  String get accountDisplay => Intl.message('Account Display', name: 'accountDisplay');

  String get personalInfo => Intl.message('Personal Info', name: 'personalInfo');

  String get firstName => Intl.message('First Name', name: 'firstName');

  String get lastName => Intl.message('Last Name', name: 'lastName');

  String get firstNameRequired => Intl.message('First Name Required', name: 'firstNameRequired');

  String get lastNameRequired => Intl.message('Last Name Required', name: 'lastNameRequired');

  String get save => Intl.message('Save', name: 'save');


  String get result => Intl.message('Result', name: 'result');
  String get dataSaved => Intl.message('Data Saved', name: 'dataSaved');




  String get notification => Intl.message('Notification', name: 'notification');
  String get notificationHistory => Intl.message('Notification History', name: 'notificationHistory');

  String get password => Intl.message('Password', name: 'password');

  String get nextStep => Intl.message('Next Step', name: 'nextStep');


  String get pickByOrder => Intl.message('Pick By Order', name: 'pickByOrder');


  String get orderNumber => Intl.message('Order Number', name: 'orderNumber');
  String get inputOrderNumberHint => Intl.message('Please input an order number',
      name: 'inputOrderNumberHint');

  String get addOrder => Intl.message('Add Order', name: 'addOrder');
  String get chooseOrder => Intl.message('Choose Order', name: 'chooseOrder');
  String get start => Intl.message('Start', name: 'start');

  String greetingMessage(Object name) {
    return Intl.message(
      'Hi $name, Welcome to CWMS',
      name: 'greetingMessage',
      desc: '',
      args: [name],
    );
  }

  ///////////////////////////////////////////////////////////////////////////////

  String get auto => Intl.message('Auto', name: 'auto');

  String get setting => Intl.message('Setting', name: 'setting');

  String get theme => Intl.message('Theme', name: 'theme');

  String get noDescription =>
      Intl.message('No description yet !', name: 'noDescription');

  String get userName => Intl.message('User Name', name: 'userName');
  String get userNameRequired => Intl.message("User name required!" , name: 'userNameRequired');
  String get passwordRequired => Intl.message('Password required!', name: 'passwordRequired');
  String get userNameOrPasswordWrong=>Intl.message('User name or password is not correct!', name: 'userNameOrPasswordWrong');
  String get logout => Intl.message('logout', name: 'logout');
  String get logoutTip => Intl.message('Are you sure you want to quit your current account?', name: 'logoutTip');
  String get yes => Intl.message('yes', name: 'yes');
  String get cancel => Intl.message('cancel', name: 'cancel');
}

//Locale代理类
class CWMSLocalizationsDelegate extends LocalizationsDelegate<CWMSLocalizations> {
  const CWMSLocalizationsDelegate();

  //是否支持某个Local
  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  // Flutter会调用此类加载相应的Locale资源类
  @override
  Future<CWMSLocalizations> load(Locale locale) {
    //3
    return  CWMSLocalizations.load(locale);
  }

  // 当Localizations Widget重新build时，是否调用load重新加载Locale资源.
  @override
  bool shouldReload(CWMSLocalizationsDelegate old) => false;
}