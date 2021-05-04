// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh_CN locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

// ignore: unnecessary_new
final messages = new MessageLookup();

// ignore: unused_element
final _keepAnalysisHappy = Intl.defaultLocale;

// ignore: non_constant_identifier_names
typedef MessageIfAbsent(String message_str, List args);

class MessageLookup extends MessageLookupByLibrary {
  get localeName => 'zh_CN';

  static greetingMessage(name) => "Hi ${name}, 欢迎";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "home" : MessageLookupByLibrary.simpleMessage("首页"),
    "account" : MessageLookupByLibrary.simpleMessage("我"),
    "accountDisplay" : MessageLookupByLibrary.simpleMessage("账户信息"),
    "login" : MessageLookupByLibrary.simpleMessage("登录"),
    "personalInfo" : MessageLookupByLibrary.simpleMessage("个人信息"),
    "firstName" : MessageLookupByLibrary.simpleMessage("名"),
    "lastName" : MessageLookupByLibrary.simpleMessage("姓"),
    "firstNameRequired" : MessageLookupByLibrary.simpleMessage("请输入名字"),
    "lastNameRequired" : MessageLookupByLibrary.simpleMessage("请输入姓"),

    "save" : MessageLookupByLibrary.simpleMessage("保存"),
    "result" : MessageLookupByLibrary.simpleMessage("结果"),
    "dataSaved" : MessageLookupByLibrary.simpleMessage("修改成功"),



    'notification': MessageLookupByLibrary.simpleMessage("通知"),
    'notificationHistory': MessageLookupByLibrary.simpleMessage("历史通知"),

    "password" : MessageLookupByLibrary.simpleMessage("密码"),
    "nextStep" : MessageLookupByLibrary.simpleMessage("下一步"),

    "pickByOrder" : MessageLookupByLibrary.simpleMessage("按订单拣选"),

    "orderNumber" : MessageLookupByLibrary.simpleMessage("订单号"),
    "inputOrderNumberHint" : MessageLookupByLibrary.simpleMessage(
        "请输入订单号"),

    "addOrder" : MessageLookupByLibrary.simpleMessage("添加订单"),
    "chooseOrder": MessageLookupByLibrary.simpleMessage("选择订单"),
    "start" : MessageLookupByLibrary.simpleMessage("开始"),
    "confirm" : MessageLookupByLibrary.simpleMessage("确认"),


    'greetingMessage':greetingMessage,
////////////////////////////////////////////////////
    "auto" : MessageLookupByLibrary.simpleMessage("跟随系统"),
    "cancel" : MessageLookupByLibrary.simpleMessage("取消"),
    "language" : MessageLookupByLibrary.simpleMessage("语言"),
    "logout" : MessageLookupByLibrary.simpleMessage("注销"),
    "logoutTip" : MessageLookupByLibrary.simpleMessage("确定要退出当前账号吗?"),
    "noDescription" : MessageLookupByLibrary.simpleMessage("暂无描述!"),
    "passwordRequired" : MessageLookupByLibrary.simpleMessage("密码不能为空"),
    "setting" : MessageLookupByLibrary.simpleMessage("设置"),
    "theme" : MessageLookupByLibrary.simpleMessage("换肤"),
    "title" : MessageLookupByLibrary.simpleMessage("Github客户端"),
    "userName" : MessageLookupByLibrary.simpleMessage("用户名"),
    "userNameOrPasswordWrong" : MessageLookupByLibrary.simpleMessage("用户名或密码不正确"),
    "userNameRequired" : MessageLookupByLibrary.simpleMessage("用户名不能为空"),
    "yes" : MessageLookupByLibrary.simpleMessage("确定")
  };
}
