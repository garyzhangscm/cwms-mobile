// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a messages locale. All the
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
  get localeName => 'messages';

  static greetingMessage(name) => "Hi ${name}, Jesus Loves You";

  static missingField(name) => "$name is required";
  static incorrectValue(name) => "incorrect $name";


  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "home" : MessageLookupByLibrary.simpleMessage("Home"),
    "account" : MessageLookupByLibrary.simpleMessage("Me"),
    "accountDisplay" : MessageLookupByLibrary.simpleMessage("Account Display"),
    "login" : MessageLookupByLibrary.simpleMessage("Login"),
    "personalInfo" : MessageLookupByLibrary.simpleMessage("Personal Information"),
    "firstName" : MessageLookupByLibrary.simpleMessage("First Name"),
    "lastName" : MessageLookupByLibrary.simpleMessage("Last Name"),
    "firstNameRequired" : MessageLookupByLibrary.simpleMessage("First Name is Required"),
    "lastNameRequired" : MessageLookupByLibrary.simpleMessage("Last Name is Required"),


    "save" : MessageLookupByLibrary.simpleMessage("Save"),

    "result" : MessageLookupByLibrary.simpleMessage("result"),
    "dataSaved" : MessageLookupByLibrary.simpleMessage("Data Saved"),


    'notification': MessageLookupByLibrary.simpleMessage("Notification"),
    'notificationHistory': MessageLookupByLibrary.simpleMessage("Notification History"),


    "password" : MessageLookupByLibrary.simpleMessage("Password"),
    "nextStep" : MessageLookupByLibrary.simpleMessage("Next Step"),

    "pickByOrder" : MessageLookupByLibrary.simpleMessage("Pick By Order"),
    "pickByWorkOrder" : MessageLookupByLibrary.simpleMessage("Pick By Work Order"),

    "orderNumber" : MessageLookupByLibrary.simpleMessage("Order Number"),
    "inputOrderNumberHint" : MessageLookupByLibrary.simpleMessage(
        "Please input an order number"),

    "workOrderNumber" : MessageLookupByLibrary.simpleMessage("Work Order Number"),
    "inputWorkOrderNumberHint" : MessageLookupByLibrary.simpleMessage(
        "Please input an work order number"),

    "addOrder" : MessageLookupByLibrary.simpleMessage("Add Order"),
    "chooseOrder" : MessageLookupByLibrary.simpleMessage("Choose Order"),

    "addWorkOrder" : MessageLookupByLibrary.simpleMessage("Add WO"),
    "chooseWorkOrder" : MessageLookupByLibrary.simpleMessage("Choose WO"),

    "start" : MessageLookupByLibrary.simpleMessage("Start"),
    "confirm" : MessageLookupByLibrary.simpleMessage("Confirm"),

    "lpn" : MessageLookupByLibrary.simpleMessage("LPN"),
    "inputLPNHint" : MessageLookupByLibrary.simpleMessage("Please input an LPN"),
    "chooseLPN" : MessageLookupByLibrary.simpleMessage("Please choose an LPN"),

    "location" : MessageLookupByLibrary.simpleMessage("location"),
    "inputLocationHint" : MessageLookupByLibrary.simpleMessage("Please input a Location"),

    "depositInventory" : MessageLookupByLibrary.simpleMessage("Deposit"),

    "chooseReceipt" : MessageLookupByLibrary.simpleMessage("Choose Receipt"),
    "chooseItem" : MessageLookupByLibrary.simpleMessage("Choose Item"),

    "addCountBatch" : MessageLookupByLibrary.simpleMessage("Add Batch"),
    "chooseCountBatch" : MessageLookupByLibrary.simpleMessage("Choose Batch"),

    "noMoreCycleCountInBatch" : MessageLookupByLibrary.simpleMessage("No More Cycle Count in this Batch"),
    "noMoreAuditCountInBatch" : MessageLookupByLibrary.simpleMessage("No More Audit Count in this Batch"),

    "confirmCycleCount" : MessageLookupByLibrary.simpleMessage("Confirm"),
    "skipCycleCount" : MessageLookupByLibrary.simpleMessage("Skip"),
    "cancelCycleCount" : MessageLookupByLibrary.simpleMessage("Cancel"),

    "confirmAuditCount" : MessageLookupByLibrary.simpleMessage("Confirm"),
    "skipAuditCount" : MessageLookupByLibrary.simpleMessage("Skip"),
    "cancelAuditCount" : MessageLookupByLibrary.simpleMessage("Cancel"),

    "addItem" : MessageLookupByLibrary.simpleMessage("Add Item"),
    "item" : MessageLookupByLibrary.simpleMessage("Item"),
    "itemPackageType" : MessageLookupByLibrary.simpleMessage("Item Package Type"),

    "inventoryStatus" : MessageLookupByLibrary.simpleMessage("Inventory Status"),

    "expectedQuantity" : MessageLookupByLibrary.simpleMessage("Expected Quantity"),
    "receivedQuantity" : MessageLookupByLibrary.simpleMessage("Received Quantity"),
    "countQuantity" : MessageLookupByLibrary.simpleMessage("Count Quantity"),
    "quantity" : MessageLookupByLibrary.simpleMessage("Quantity"),

    "cycleCount" : MessageLookupByLibrary.simpleMessage("Cycle Count"),
    "auditCount" : MessageLookupByLibrary.simpleMessage("Audit Count"),

    "workProfile" : MessageLookupByLibrary.simpleMessage("Work Profile"),

    "currentLocation" : MessageLookupByLibrary.simpleMessage("Current Location"),

    "menuMobileInbound" : MessageLookupByLibrary.simpleMessage("Inbound"),
    "menuMobileOutbound" : MessageLookupByLibrary.simpleMessage("Outbound"),
    "menuMobileInventory" : MessageLookupByLibrary.simpleMessage("Inventory"),
    "menuMobileWorkOrder" : MessageLookupByLibrary.simpleMessage("Work Order"),
    "menuMobileInboundReceive" : MessageLookupByLibrary.simpleMessage("Receive"),
    "menuMobileOutboundPickByOrder" : MessageLookupByLibrary.simpleMessage("Pick By Order"),
    "menuMobileOutboundPickByList" : MessageLookupByLibrary.simpleMessage("Pick By List"),
    "menuMobileOutboundPickByWorkOrder" : MessageLookupByLibrary.simpleMessage("Pick By WO"),
    "menuMobileOutboundPickByTote" : MessageLookupByLibrary.simpleMessage("Pick By Tote"),
    "menuMobileInventoryInventory" : MessageLookupByLibrary.simpleMessage("Inventory"),
    "menuMobileInventoryCount" : MessageLookupByLibrary.simpleMessage("Cycle Count"),
    "menuMobileInventoryAuditCount" : MessageLookupByLibrary.simpleMessage("Audit Count"),
    "menuMobileWorkOrderProduce" : MessageLookupByLibrary.simpleMessage("Produce"),

    "chooseServer" : MessageLookupByLibrary.simpleMessage("Choose Server"),
    "query" : MessageLookupByLibrary.simpleMessage("Query"),

    "inputItemHint" : MessageLookupByLibrary.simpleMessage("Please input an Item or Barcode"),
    "noInventoryFound" : MessageLookupByLibrary.simpleMessage("Cannot find any inventory"),
    "inventory" : MessageLookupByLibrary.simpleMessage("Inventory"),
    "highPriority" : MessageLookupByLibrary.simpleMessage("High Priority"),
    "share" : MessageLookupByLibrary.simpleMessage("Share"),
    "remove" : MessageLookupByLibrary.simpleMessage("Remove"),
    "receiving" : MessageLookupByLibrary.simpleMessage("Receiving"),
    "receiptNumber" : MessageLookupByLibrary.simpleMessage("Receipt Number"),
    "receivingQuantity" : MessageLookupByLibrary.simpleMessage("Receiving Quantity"),

    "add" : MessageLookupByLibrary.simpleMessage("Add"),

    "actionComplete" : MessageLookupByLibrary.simpleMessage("Action Complete"),

    "productionLine" : MessageLookupByLibrary.simpleMessage("Production Line"),
    "inputProductionLineHint" : MessageLookupByLibrary.simpleMessage(
        "Please input a production line"),

    "workOrderProduce" : MessageLookupByLibrary.simpleMessage("Produce"),
    "producedQuantity" : MessageLookupByLibrary.simpleMessage("Produced Quantity"),
    "producingQuantity" : MessageLookupByLibrary.simpleMessage("Producing Quantity"),
    "billOfMaterial" : MessageLookupByLibrary.simpleMessage("BOM"),
     "workingTeamName": MessageLookupByLibrary.simpleMessage("Working Team"),

    "kpi": MessageLookupByLibrary.simpleMessage("KPI"),

    "kpiAmount": MessageLookupByLibrary.simpleMessage("Amount"),
    "kpiMeasurement": MessageLookupByLibrary.simpleMessage("Measurement"),

    "workingTeamMemberCount": MessageLookupByLibrary.simpleMessage("Work Team Member Count"),
    "productionLineCheckIn": MessageLookupByLibrary.simpleMessage("Production Line Check In"),
    "productionLineCheckOut": MessageLookupByLibrary.simpleMessage("Production Line Check Out"),
    "transactionTime": MessageLookupByLibrary.simpleMessage("Transaction Time"),
    "noWorkOrderFoundOnProductionLine": MessageLookupByLibrary.simpleMessage("No Work Order Found on This Production Line"),


    "pickWrongLPN": MessageLookupByLibrary.simpleMessage("lpn is not correct for picking"),
    "inventoryAdjust": MessageLookupByLibrary.simpleMessage("Inventory Adjust"),


    "error": MessageLookupByLibrary.simpleMessage("Error"),
    "warning": MessageLookupByLibrary.simpleMessage("Warning"),
    "skip" : MessageLookupByLibrary.simpleMessage("Skip"),
    "inventoryNeedQC" : MessageLookupByLibrary.simpleMessage("The Inventory Needs QC"),
    "workOrderQCNumber" : MessageLookupByLibrary.simpleMessage("QC Number"),
    "workOrderQCSampleNumber" : MessageLookupByLibrary.simpleMessage("QC Sample Number"),
    "workOrderQC" : MessageLookupByLibrary.simpleMessage("Work Order QC"),
    "clear" : MessageLookupByLibrary.simpleMessage("Clear"),
    "qcPass" : MessageLookupByLibrary.simpleMessage("Pass"),
    "qcFail" : MessageLookupByLibrary.simpleMessage("Fail"),
    "qcCompleted" : MessageLookupByLibrary.simpleMessage("QC Completed"),
    "startQC" : MessageLookupByLibrary.simpleMessage("Start QC"),
    "workOrderNoQCConfig" : MessageLookupByLibrary.simpleMessage("Cannot find any qc rule setup for this work order & production line"),
    "nextQCRule" : MessageLookupByLibrary.simpleMessage("Next QC Rule"),
    "inventoryNotQCRequired" : MessageLookupByLibrary.simpleMessage("The inventory does not need QC"),
    "pleaseSelect" : MessageLookupByLibrary.simpleMessage("Please select"),
    "noCheckInProductionLineFoundForUser" : MessageLookupByLibrary.simpleMessage("The user has not checked in any production line"),
    "noCheckInUsersFoundForProductionLine" : MessageLookupByLibrary.simpleMessage("There's no user checked in this production line"),


    "productionLineCheckOutByUser" : MessageLookupByLibrary.simpleMessage("By User"),
    "productionLineCheckOutByProductionLine" : MessageLookupByLibrary.simpleMessage("By Production Line"),

    "pleaseSelectAUser" : MessageLookupByLibrary.simpleMessage("Please Select A User"),
    "pleaseSelectAProductionLine" : MessageLookupByLibrary.simpleMessage("Please Select A Production Line"),
    "appUpgrade" : MessageLookupByLibrary.simpleMessage("App Upgrade"),
    "startDownloadingAppNewVersion" : MessageLookupByLibrary.simpleMessage("Start Downloading new version"),
    "newReleaseFound" : MessageLookupByLibrary.simpleMessage("New Release Found"),
    "qcQuantity" : MessageLookupByLibrary.simpleMessage("QC Quantity"),
    "lpnUnitOfMeasure" : MessageLookupByLibrary.simpleMessage("LPN UOM"),
    "enoughLPNCaptured" : MessageLookupByLibrary.simpleMessage("We already captured enough LPN"),
    "requestedLPNQuantity" : MessageLookupByLibrary.simpleMessage("Requested LPN Quantity"),
    "capturedLPNQuantity" : MessageLookupByLibrary.simpleMessage("Captured LPN Quantity"),
    "captureLPN" : MessageLookupByLibrary.simpleMessage("Captured LPN"),
    "receivingMultipleLpns" : MessageLookupByLibrary.simpleMessage("Receive Multiple LPNs"),
    "receivingCurrentLpn" : MessageLookupByLibrary.simpleMessage("Receiving Current LPN"),
    "addSample" : MessageLookupByLibrary.simpleMessage("Add Sample"),
    "noAssignmentByProductionLine" : MessageLookupByLibrary.simpleMessage("No Assignment Found by Production Line:"),
    "addImage" : MessageLookupByLibrary.simpleMessage("Add Image"),
    "takePhoto" : MessageLookupByLibrary.simpleMessage("Take Photo"),
    "qcSampleAdded" : MessageLookupByLibrary.simpleMessage("QC Sample Added"),
    "qcSampleNumberAlreadyExists" : MessageLookupByLibrary.simpleMessage("QC Sample With The Same Name Already Exists"),
    "noQCSampleExists" : MessageLookupByLibrary.simpleMessage("Cannot find the qc samples"),




    'greetingMessage':greetingMessage,
    'missingField':missingField,
    'incorrectValue':incorrectValue,

    ////////////////////////////////////////////////
    "auto" : MessageLookupByLibrary.simpleMessage("Auto"),
    "cancel" : MessageLookupByLibrary.simpleMessage("cancel"),
    "language" : MessageLookupByLibrary.simpleMessage("Language"),
    "logout" : MessageLookupByLibrary.simpleMessage("logout"),
    "logoutTip" : MessageLookupByLibrary.simpleMessage("Are you sure you want to quit your current account?"),
    "noDescription" : MessageLookupByLibrary.simpleMessage("No description yet !"),
    "passwordRequired" : MessageLookupByLibrary.simpleMessage("Password required!"),
    "setting" : MessageLookupByLibrary.simpleMessage("Setting"),
    "theme" : MessageLookupByLibrary.simpleMessage("Theme"),
    "title" : MessageLookupByLibrary.simpleMessage("Flutter APP"),
    "userName" : MessageLookupByLibrary.simpleMessage("User Name"),
    "userNameOrPasswordWrong" : MessageLookupByLibrary.simpleMessage("User name or password is not correct!"),
    "userNameRequired" : MessageLookupByLibrary.simpleMessage("User name required!"),
    "yes" : MessageLookupByLibrary.simpleMessage("yes")
  };
}
