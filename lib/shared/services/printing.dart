
import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/printing_strategy.dart';
import 'package:dio/dio.dart';

import '../models/report_history.dart';

class PrintingService {

  static Future<void> printFile(ReportHistory reportHistory, String printerName) async {
    if (Global.warehouseConfiguration.printingStrategy == null) {
      throw new WebAPICallException(
          "printing strategy is not setup. Please config it in the warehouse configuration page");
    }

    switch (Global.warehouseConfiguration.printingStrategy) {
      case PrintingStrategy.LOCAL_PRINTER_LOCAL_DATA:
        throw new WebAPICallException(
            "printing directly from device is not support");
        break;
      case PrintingStrategy.LOCAL_PRINTER_SERVER_DATA:
        await _printingFileFromLocalPrinterServerData(reportHistory, printerName);
        break;
      default:
        await _printingFileFromServerPrinterServerData(reportHistory, printerName);
        break;
    }
  }

  // for printing strategy LOCAL_PRINTER_SERVER_DATA, we will save the
  // print request to server
  static Future<void> _printingFileFromLocalPrinterServerData(ReportHistory reportHistory,
      String printerName) async {

    // generate printing request and save in the server.
    // we will have another local plugin to get the request and print
    // from local printer
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.put(
        Global.currentServer.url + "/resource/printing-requests/by-report-history",
        queryParameters: {"warehouseId": Global.currentWarehouse.id,
          "reportHistoryId": reportHistory.id,
          "printerName": printerName,
          "copies":  "1"}
    );

    printLongLogMessage("get response from _printingFileFromLocalPrinterServerData ${response.toString()}");

    // printLongLogMessage("response from receipt: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());


    if (responseString["result"] as int != 0) {
      printLongLogMessage("_printingFileFromLocalPrinterServerData / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


  }

  // print the file from printer that connect direct to the server
  static Future<void> _printingFileFromServerPrinterServerData(ReportHistory reportHistory,
      String printerName) async {

    printLongLogMessage("Start to print file ${reportHistory.fileName} from server's printer ${printerName}");

    Map<String, dynamic> queryParameters = new Map<String, dynamic>();
    queryParameters["warehouseId"] = Global.currentWarehouse.id;
    queryParameters["printerName"] = printerName;
    queryParameters["copies"] = "1";


    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        Global.currentServer.url + "/resource/report-histories/print/${Global.lastLoginCompanyId}/${Global.currentWarehouse.id}/${reportHistory.type.name}/${reportHistory.fileName}",
        queryParameters: queryParameters
    );

    printLongLogMessage("get response from _printingFileFromServerPrinterServerData ${response.toString()}");

    // printLongLogMessage("response from receipt: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("_printingFileFromServerPrinterServerData / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

  }




}




