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

    "orderNumber" : MessageLookupByLibrary.simpleMessage("Order Number"),
    "inputOrderNumberHint" : MessageLookupByLibrary.simpleMessage(
        "Please input an order number"),

    "addOrder" : MessageLookupByLibrary.simpleMessage("Add Order"),
    "chooseOrder" : MessageLookupByLibrary.simpleMessage("Choose Order"),
    "start" : MessageLookupByLibrary.simpleMessage("Start"),
    "confirm" : MessageLookupByLibrary.simpleMessage("Confirm"),

    "lpn" : MessageLookupByLibrary.simpleMessage("lpn"),
    "inputLPNHint" : MessageLookupByLibrary.simpleMessage("Please input an LPN"),
    "chooseLPN" : MessageLookupByLibrary.simpleMessage("Please choose an LPN"),

    "location" : MessageLookupByLibrary.simpleMessage("location"),
    "inputLocationHint" : MessageLookupByLibrary.simpleMessage("Please input a Location"),

    "depositInventory" : MessageLookupByLibrary.simpleMessage("Deposit"),


    'greetingMessage':greetingMessage,

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
