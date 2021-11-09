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
  String get pickByWorkOrder => Intl.message('Pick By Work Order', name: 'pickByWorkOrder');


  String get orderNumber => Intl.message('Order Number', name: 'orderNumber');
  String get inputOrderNumberHint => Intl.message('Please input an order number',
      name: 'inputOrderNumberHint');

  String get workOrderNumber => Intl.message('Work Order Number', name: 'workOrderNumber');
  String get inputWorkOrderNumberHint => Intl.message('Please input a work order number',
      name: 'inputWorkOrderNumberHint');

  String get addOrder => Intl.message('Add Order', name: 'addOrder');
  String get chooseOrder => Intl.message('Choose Order', name: 'chooseOrder');
  String get addWorkOrder => Intl.message('Add WO', name: 'addWorkOrder');
  String get chooseWorkOrder => Intl.message('Choose WO', name: 'chooseWorkOrder');
  String get start => Intl.message('Start', name: 'start');
  String get confirm => Intl.message('Confirm', name: 'confirm');

  String get lpn => Intl.message('LPN', name: 'lpn');
  String get inputLPNHint => Intl.message('Please input an LPN', name: 'inputLPNHint');
  String get chooseLPN => Intl.message('Please choose an LPN', name: 'chooseLPN');

  String get location => Intl.message('location', name: 'location');
  String get inputLocationHint => Intl.message('Please input a Location', name: 'inputLocationHint');

  String get depositInventory => Intl.message('Deposit', name: 'depositInventory');

  String get chooseReceipt => Intl.message('Choose Receipt', name: 'chooseReceipt');
  String get chooseItem => Intl.message('Choose Item', name: 'chooseItem');


  String get addCountBatch => Intl.message('Add Batch', name: 'addCountBatch');
  String get chooseCountBatch => Intl.message('Choose Batch', name: 'chooseCountBatch');

  String get noMoreCycleCountInBatch => Intl.message('No More Cycle Count In this Batch', name: 'noMoreCycleCountInBatch');
  String get noMoreAuditCountInBatch => Intl.message('No More Audit Count In this Batch', name: 'noMoreAuditCountInBatch');

  String get confirmCycleCount => Intl.message('Confirm', name: 'confirmCycleCount');
  String get skipCycleCount => Intl.message('Skip', name: 'skipCycleCount');
  String get cancelCycleCount => Intl.message('Cancel', name: 'cancelCycleCount');

  String get confirmAuditCount => Intl.message('Confirm', name: 'confirmAuditCount');
  String get skipAuditCount => Intl.message('Skip', name: 'skipAuditCount');
  String get cancelAuditCount => Intl.message('Cancel', name: 'cancelAuditCount');

  String get addItem => Intl.message('Add Item', name: 'addItem');
  String get item => Intl.message('Item', name: 'item');

  String get itemPackageType => Intl.message('Item Package Type', name: 'itemPackageType');
  String get inventoryStatus => Intl.message('Inventory Status', name: 'inventoryStatus');

  String get receiving => Intl.message('Receiving', name: 'receiving');

  String get expectedQuantity => Intl.message('Expected Quantity', name: 'expectedQuantity');
  String get receivedQuantity => Intl.message('Received Quantity', name: 'receivedQuantity');
  String get receivingQuantity => Intl.message('Receiving Quantity', name: 'receivingQuantity');
  String get countQuantity => Intl.message('Count Quantity', name: 'countQuantity');
  String get quantity => Intl.message('Quantity', name: 'quantity');

  String get cycleCount => Intl.message('Cycle Count', name: 'cycleCount');
  String get auditCount => Intl.message('Audit Count', name: 'auditCount');
  String get workProfile => Intl.message('Work Profile', name: 'workProfile');
  String get currentLocation => Intl.message('Current Location', name: 'currentLocation');

  String get chooseServer => Intl.message('Choose a Server', name: 'chooseServer');
  String get query => Intl.message('Query', name: 'query');


  String get inputItemHint => Intl.message('Please input an Item or Barcode', name: 'inputItemHint');

  String get noInventoryFound => Intl.message('Cannont find any inventory', name: 'noInventoryFound');
  String get inventory => Intl.message('inventory', name: 'inventory');


  String get highPriority => Intl.message('High Priority', name: 'highPriority');
  String get share => Intl.message('Share', name: 'share');
  String get remove => Intl.message('Remove', name: 'remove');
  String get receiptNumber => Intl.message('Receipt Number', name: 'receiptNumber');

  String get add => Intl.message('Add', name: 'add');
  String get actionComplete => Intl.message('Action Complete', name: 'actionComplete');



  String get productionLine => Intl.message('Production Line', name: 'productionLine');
  String get inputProductionLineHint => Intl.message('Please input a production line name',
      name: 'inputProductionLineHint');
  String get workOrderProduce => Intl.message('Produce', name: 'workOrderProduce');
  String get producedQuantity => Intl.message('Produced Quantity', name: 'producedQuantity');
  String get producingQuantity => Intl.message('Producing Quantity', name: 'producingQuantity');


  String get billOfMaterial => Intl.message('BOM', name: 'billOfMaterial');
  String get workingTeamName => Intl.message('Working Team', name: 'workingTeamName');
  String get kpi => Intl.message('KPI', name: 'kpi');
  String get kpiAmount => Intl.message('Amount', name: 'kpiAmount');
  String get kpiMeasurement => Intl.message('Measurement', name: 'kpiMeasurement');


  String get workingTeamMemberCount => Intl.message('Work Team Member Count', name: 'workingTeamMemberCount');
  String get productionLineCheckIn => Intl.message('Production Line Check In', name: 'productionLineCheckIn');
  String get productionLineCheckOut => Intl.message('Production Line Check Out', name: 'productionLineCheckOut');
  String get transactionTime => Intl.message('Transaction Time', name: 'transactionTime');
  String get  noWorkOrderFoundOnProductionLine => Intl.message('No Work Order Found on This Production Line', name: 'noWorkOrderFoundOnProductionLine');


  String get  pickWrongLPN => Intl.message('lpn is not correct for picking', name: 'pickWrongLPN');
  String get  inventoryAdjust => Intl.message('Inventory Adjust', name: 'inventoryAdjust');

  String get  error => Intl.message('Error', name: 'error');
  String get  warning => Intl.message('Warning', name: 'warning');
  String get skip => Intl.message('Skip', name: 'skip');
  String get inventoryNeedQC => Intl.message('The Inventory Needs QC', name: 'inventoryNeedQC');

  String get workOrderQCNumber => Intl.message('QC Number', name: 'workOrderQCNumber');
  String get workOrderQCSampleNumber => Intl.message('QC Sample Number', name: 'workOrderQCSampleNumber');
  String get workOrderQC => Intl.message('Work Order QC', name: 'workOrderQC');
  String get clear => Intl.message('Clear', name: 'clear');
  String get qcPass => Intl.message('Pass', name: 'qcPass');
  String get qcFail => Intl.message('Fail', name: 'qcFail');
  String get qcCompleted => Intl.message('QC Completed', name: 'qcCompleted');
  String get startQC => Intl.message('Start QC', name: 'startQC');
  String get workOrderNoQCConfig => Intl.message('Cannot find any qc rule setup for this work order & production line', name: 'workOrderNoQCConfig');
  String get inventoryNotQCRequired => Intl.message('The inventory does not need QC', name: 'inventoryNotQCRequired');
  String get nextQCRule => Intl.message('Next QC Rule', name: 'nextQCRule');
  String get pleaseSelect => Intl.message('Please Select', name: 'pleaseSelect');
  String get noCheckInProductionLineFoundForUser => Intl.message('The user has not checked in any production line', name: 'noCheckInProductionLineFoundForUser');
  String get noCheckInUsersFoundForProductionLine => Intl.message("There's no user checked in this production line", name: 'noCheckInUsersFoundForProductionLine');


  String get productionLineCheckOutByUser => Intl.message('By User', name: 'productionLineCheckOutByUser');
  String get productionLineCheckOutByProductionLine => Intl.message('By Production Line', name: 'productionLineCheckOutByProductionLine');
  String get pleaseSelectAUser => Intl.message('Please Select A User', name: 'pleaseSelectAUser');
  String get pleaseSelectAProductionLine => Intl.message('Please Select A Production Line', name: 'pleaseSelectAProductionLine');
  String get appUpgrade => Intl.message('App Upgrade', name: 'appUpgrade');
  String get startDownloadingAppNewVersion => Intl.message('Start Downloading new version', name: 'startDownloadingAppNewVersion');
  String get newReleaseFound => Intl.message('New Release Found', name: 'newReleaseFound');




  String missingField(Object name) {
    return Intl.message(
      '$name is required',
      name: 'missingField',
      desc: '',
      args: [name],
    );
  }

  String incorrectValue(Object name) {
    return Intl.message(
      'incorrect $name',
      name: 'incorrectValue',
      desc: '',
      args: [name],
    );
  }
  String greetingMessage(Object name) {
    return Intl.message(
      'Hi $name, Welcome to CWMS',
      name: 'greetingMessage',
      desc: '',
      args: [name],
    );
  }

  String get menuMobileInbound => Intl.message('Inbound', name: 'menuMobileInbound');
  String get menuMobileOutbound => Intl.message('Outbound', name: 'menuMobileOutbound');
  String get menuMobileInventory => Intl.message('Inventory', name: 'menuMobileInventory');
  String get menuMobileWorkOrder => Intl.message('Work Order', name: 'menuMobileWorkOrder');
  String get menuMobileInboundReceive => Intl.message('Receive', name: 'menuMobileInboundReceive');
  String get menuMobileOutboundPickByOrder => Intl.message('Pick By Order', name: 'menuMobileOutboundPickByOrder');
  String get menuMobileOutboundPickByList => Intl.message('Pick By List', name: 'menuMobileOutboundPickByList');
  String get menuMobileOutboundPickByWorkOrder => Intl.message('Pick By WO', name: 'menuMobileOutboundPickByWorkOrder');
  String get menuMobileOutboundPickByTote => Intl.message('Pick By Tote', name: 'menuMobileOutboundPickByTote');
  String get menuMobileInventoryInventory => Intl.message('Inventory', name: 'menuMobileInventoryInventory');
  String get menuMobileInventoryCount => Intl.message('Cycle Count', name: 'menuMobileInventoryCount');
  String get menuMobileInventoryAuditCount => Intl.message('Audit Count', name: 'menuMobileInventoryAuditCount');
  String get menuMobileWorkOrderProduce => Intl.message('Produce', name: 'menuMobileWorkOrderProduce');
  ///////////////////    动态取得菜单的中文  /////////////////////////////////////////////////
  Map<String, dynamic> _menuMap() {
    return {
      'menu.mobile.inbound': menuMobileInbound,
      'menu.mobile.outbound': menuMobileOutbound,
      'menu.mobile.inventory': menuMobileInventory,
      'menu.mobile.work-order': menuMobileWorkOrder,
      'menu.mobile.inbound.receive': menuMobileInboundReceive,
      'menu.mobile.outbound.pick-by-order': menuMobileOutboundPickByOrder,
      'menu.mobile.outbound.pick-by-list': menuMobileOutboundPickByList,
      'menu.mobile.outbound.pick-by-work-order': menuMobileOutboundPickByWorkOrder,
      'menu.mobile.work-order.pick-by-work-order': menuMobileOutboundPickByWorkOrder,
      'menu.mobile.work-order.produce':menuMobileWorkOrderProduce,
      'menu.mobile.outbound.pick-by-tote': menuMobileOutboundPickByTote,
      'menu.mobile.inventory.inventory': menuMobileInventoryInventory,
      'menu.mobile.inventory.count': menuMobileInventoryCount,
      'menu.mobile.inventory.audit-count':menuMobileInventoryAuditCount,
    };
  }

  String getMenuDisplayText(String menuI18n, String defaultText) {
    var _mapRep = _menuMap();
    if (_mapRep.containsKey(menuI18n)) {
      return _mapRep[menuI18n];
    }
    else {
      return defaultText;
    }
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