

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:flutter/services.dart';

import 'package:cwms_mobile/shared/functions.dart';
import 'package:printing/printing.dart';


class PrinterService {

  static Future<void> getDefaultBluetoothPrinter3() async {
    printLongLogMessage("getDefaultBluetoothPrinter3: start to get printers");
    Printing.listPrinters().then((printers) {
      printLongLogMessage("got ${printers.length} printers");
      printers.forEach((printer) {
        printLongLogMessage("# ${printer.name}");
      });
    });

  }
  static Future<void> getDefaultBluetoothPrinter2() async {
    PrinterBluetoothManager printerManager = PrinterBluetoothManager();

    printLongLogMessage("start to get printers");

    printerManager.scanResults.listen((printers) async {
      // store found printers
      printLongLogMessage("get ${printers.length} printers");
      printers.forEach((printer) {
        printLongLogMessage("> ${printer.name}");
      });
    });

    printerManager.startScan(Duration(seconds: 4));

  }
  // get connected bluetooth printer
  static Future<BluetoothDevice> getDefaultBluetoothPrinter() async {
    BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
            print("bluetooth device state: connected");
          break;
        case BlueThermalPrinter.DISCONNECTED:
            print("bluetooth device state: disconnected");
          break;
        case BlueThermalPrinter.DISCONNECT_REQUESTED:
            print("bluetooth device state: disconnect requested");
          break;
        case BlueThermalPrinter.STATE_TURNING_OFF:
            print("bluetooth device state: bluetooth turning off");
          break;
        case BlueThermalPrinter.STATE_OFF:
            print("bluetooth device state: bluetooth off");
          break;
        case BlueThermalPrinter.STATE_ON:
            print("bluetooth device state: bluetooth on");
          break;
        case BlueThermalPrinter.STATE_TURNING_ON:
            print("bluetooth device state: bluetooth turning on");
          break;
        case BlueThermalPrinter.ERROR:
            print("bluetooth device state: error");
          break;
        default:
          print(state);
          break;
      }
    });

    printLongLogMessage("start to get blue tooth printer");

    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException catch(ex) {
      printLongLogMessage("Error while get bluetooth printer \n ${ex.message}");
      return null;
    }

    if (devices.isEmpty) {
      printLongLogMessage("there's no bluetooth connected");
      return null;
    }
    BluetoothDevice defaultPrinter = devices[0];

    bool isConnected = await bluetooth.isConnected;
    printLongLogMessage("bluetooth is connect? $isConnected ");
    if (isConnected) {
      return defaultPrinter;
    }

    try {
      printLongLogMessage("start to connect to the default printer");
      await bluetooth.connect(defaultPrinter);
    }
    on Exception catch(ex) {
      printLongLogMessage("fail to connect to the default printer, \n${ex.toString()}");
      return null;

    }



  }



}




