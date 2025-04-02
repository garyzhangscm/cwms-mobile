
import 'dart:convert';
import 'dart:io' show Directory, File, Platform;

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/shared/models/printing_strategy.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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



  static Future<String> downloadFile(ReportHistory reportHistory) async {
//https://staging.claytechsuite.com/api/resource/report-histories/preview/4/6/LPN_LABEL/LPN_LABEL_1743551794620_0109.lbl?token=eyJhbGciOiJIUzI1NiJ9.eyJjb21wYW55SWQiOi0xLCJzdWIiOiJHWkhBTkciLCJpYXQiOjE3NDM1NTE0MzUsImV4cCI6MTc0MzU4NzQzNX0.l4xWVEA5dQSwhGUtVqAGEqFDQYsrMl784Y0N-rkUkJQ&companyId=4

    String url = "resource/report-histories/preview/${Global.lastLoginCompanyId}/${Global.currentWarehouse.id}/LPN_LABEL/${reportHistory.fileName}";
    url  = "$url?token=${Global.currentUser.token}";
    url  = "$url&companyId=${Global.lastLoginCompanyId}";

    Dio httpClient = CWMSHttpClient.getDio();

    final status = await Permission.storage.request();
    if (status.isGranted) {
      Directory directory;
      if (Platform.isAndroid) {
        // dirloc = "/sdcard/download/NHB/";
        directory = await getTemporaryDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      String tempFilePath = "${directory.path}/${reportHistory.fileName}";

      printLongLogMessage(
          'Save report file to temporary folder: ${tempFilePath}');
      try {

        await httpClient.download(
            url, tempFilePath,
            onReceiveProgress: (receivedBytes, totalBytes) {
              printLongLogMessage("received ${receivedBytes} of $totalBytes");
            });


        /// For Android call the flutter_file_dialog package, which will give
          /// the option to save the now downloaded file by Dio (to temp
          /// application cache) to wherever the user wants including Downloads!
        ///
        // if (Platform.isAndroid) {
        //    final params = SaveFileDialogParams(
        //        sourceFilePath: tempFilePath);
        //    final filePath =
        //        await FlutterFileDialog.saveFile(params: params);

        //    print('Download path: $filePath');



        //  return filePath;
        // }




          return tempFilePath;
      } catch (e) {
        printLongLogMessage('catch catch catch');
        printLongLogMessage(e);
        return "";
      }
    }
    else {

      return "";
    }
  }


  static Future<void> sendFileToPrinter(String filePath) async {

    await Printing.layoutPdf( onLayout: (PdfPageFormat format) async => new File(filePath).readAsBytesSync());
  }
}




