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

  static missingField(name) => "$name 不可为空";

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


    "lpn" : MessageLookupByLibrary.simpleMessage("LPN"),
    "inputLPNHint" : MessageLookupByLibrary.simpleMessage("请输入LPN"),
    "chooseLPN" : MessageLookupByLibrary.simpleMessage("请选择LPN"),

    "location" : MessageLookupByLibrary.simpleMessage("库位"),
    "inputLocationHint" : MessageLookupByLibrary.simpleMessage("请输入库位"),

    "depositInventory" : MessageLookupByLibrary.simpleMessage("放置"),


    "chooseReceipt" : MessageLookupByLibrary.simpleMessage("选择入库单"),
    "chooseItem" : MessageLookupByLibrary.simpleMessage("选择商品"),

    "addCountBatch" : MessageLookupByLibrary.simpleMessage("添加盘点单"),
    "chooseCountBatch": MessageLookupByLibrary.simpleMessage("选择盘点单"),

    "noMoreCycleCountInBatch" : MessageLookupByLibrary.simpleMessage("当前盘点单已没有盘点任务"),
    "noMoreAuditCountInBatch" : MessageLookupByLibrary.simpleMessage("当前盘点单已没有复盘任务"),

    "confirmCycleCount" : MessageLookupByLibrary.simpleMessage("确认"),
    "skipCycleCount" : MessageLookupByLibrary.simpleMessage("跳过"),
    "cancelCycleCount" : MessageLookupByLibrary.simpleMessage("取消"),

    "confirmAuditCount" : MessageLookupByLibrary.simpleMessage("确认"),
    "skipAuditCount" : MessageLookupByLibrary.simpleMessage("跳过"),
    "cancelAuditCount" : MessageLookupByLibrary.simpleMessage("取消"),

    "addItem" : MessageLookupByLibrary.simpleMessage("添加商品"),
    "item" : MessageLookupByLibrary.simpleMessage("商品"),
    "itemPackageType" : MessageLookupByLibrary.simpleMessage("包装规格"),
    "inventoryStatus" : MessageLookupByLibrary.simpleMessage("库存状态"),


    "expectedQuantity" : MessageLookupByLibrary.simpleMessage("预期数量"),
    "receivedQuantity" : MessageLookupByLibrary.simpleMessage("收货数量"),
    "countQuantity" : MessageLookupByLibrary.simpleMessage("盘点数量"),
    "quantity" : MessageLookupByLibrary.simpleMessage("数量"),


    "cycleCount" : MessageLookupByLibrary.simpleMessage("盘点"),
    "auditCount" : MessageLookupByLibrary.simpleMessage("复盘"),
    "workProfile" : MessageLookupByLibrary.simpleMessage("工作信息"),
    "currentLocation" : MessageLookupByLibrary.simpleMessage("当前库位"),


    "menuMobileInbound" : MessageLookupByLibrary.simpleMessage("入库"),
    "menuMobileOutbound" : MessageLookupByLibrary.simpleMessage("出库"),
    "menuMobileInventory" : MessageLookupByLibrary.simpleMessage("库存管理"),
    "menuMobileInboundReceive" : MessageLookupByLibrary.simpleMessage("收货"),
    "menuMobileOutboundPickByOrder" : MessageLookupByLibrary.simpleMessage("按单拣选"),
    "menuMobileOutboundPickByList" : MessageLookupByLibrary.simpleMessage("列表拣货"),
    "menuMobileOutboundPickByWorkOrder" : MessageLookupByLibrary.simpleMessage("加工拣货"),
    "menuMobileOutboundPickByTote" : MessageLookupByLibrary.simpleMessage("装箱拣货"),
    "menuMobileInventoryInventory" : MessageLookupByLibrary.simpleMessage("库存显示"),
    "menuMobileInventoryCount" : MessageLookupByLibrary.simpleMessage("盘点"),
    "menuMobileInventoryAuditCount" : MessageLookupByLibrary.simpleMessage("复盘"),

    "chooseServer" : MessageLookupByLibrary.simpleMessage("选择服务器"),
    "query" : MessageLookupByLibrary.simpleMessage("查询"),


    "inputItemHint" : MessageLookupByLibrary.simpleMessage("请输入商品或者条码"),
    "noInventoryFound" : MessageLookupByLibrary.simpleMessage("没有找到任何库存"),
    "inventory" : MessageLookupByLibrary.simpleMessage("库存"),

    'greetingMessage':greetingMessage,
    'missingField':missingField,
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
