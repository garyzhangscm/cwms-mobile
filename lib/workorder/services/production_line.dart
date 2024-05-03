
import 'dart:convert';

import 'package:cwms_mobile/auth/models/user.dart';
import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/outbound/models/order.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/workorder/models/production_line.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:cwms_mobile/workorder/models/work_order_labor.dart';
import 'package:cwms_mobile/workorder/models/work_order_produce_transaction.dart';
import 'package:dio/dio.dart';

class ProductionLineService {
  // Get all cycle count requests by batch id
  static Future<ProductionLine> getProductionLineByNumber(String productionLineName,
      {bool loadDetails = true, bool loadWorkOrderDetails = true}) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "workorder/production-lines",
        queryParameters: {"name": productionLineName,
          "warehouseId": Global.currentWarehouse.id,
        'loadDetails' : loadDetails,
        'loadWorkOrderDetails': loadWorkOrderDetails}
    );

    // printLongLogMessage("response from getProductionLineByNumber: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("getProductionLineByNumber / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }
    List<ProductionLine> productionLines
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : ProductionLine.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // Sort the picks according to the current location. We
    // will assign the closed pick to the user
    if (productionLines.length > 0) {
      return productionLines.first;
    }
    else {
      return null;
    }

  }


  static Future<List<ProductionLine>> getAllAssignedProductionLines({loadDetails=false}) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "workorder/production-line/assigned",
        queryParameters: {
          "warehouseId": Global.currentWarehouse.id,
        "loadDetails": loadDetails}
    );

    // printLongLogMessage("response from getAllAssignedProductionLines: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("getAllAssignedProductionLines / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }
    List<ProductionLine> productionLines
      = (responseString["data"] as List)?.map((e) =>
      e == null ? null : ProductionLine.fromJson(e as Map<String, dynamic>))
          ?.toList();
    printLongLogMessage("We get ${productionLines.length} assigned production lines");

    return productionLines;

  }

  static Future<WorkOrderLabor> checkInUser(int productionLineId,
      String username) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "workorder/labor/check_in_user",
        queryParameters: {
          "productionLineId": productionLineId,
          "username": username,
          "currentUsername": Global.currentUsername,
          "warehouseId": Global.currentWarehouse.id}
    );

    // printLongLogMessage("response from checkInUser: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("checkInUser / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return WorkOrderLabor.fromJson(responseString["data"] as Map<String, dynamic>);

  }


  static Future<WorkOrderLabor> checkOutUser(int productionLineId,
      String username) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "workorder/labor/check_out_user",
        queryParameters: {
          "productionLineId": productionLineId,
          "username": username,
          "currentUsername": Global.currentUsername,
          "warehouseId": Global.currentWarehouse.id}
    );

    // printLongLogMessage("response from checkOutUser: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("checkOutUser / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return WorkOrderLabor.fromJson(responseString["data"] as Map<String, dynamic>);

  }


  static Future<List<ProductionLine>> findAllCheckedInProductionLines(String username) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "workorder/labor/checked_in_production_lines",
        queryParameters: {
          "username": username,
          "warehouseId": Global.currentWarehouse.id}
    );

    // printLongLogMessage("response from findAllCheckedInProductionLines: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("findAllCheckedInProductionLines / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


    List<ProductionLine> productionLines
      = (responseString["data"] as List)?.map((e) =>
      e == null ? null : ProductionLine.fromJson(e as Map<String, dynamic>))
          ?.toList();
    printLongLogMessage("We get ${productionLines.length}  production lines that the user check in");

    return productionLines;


  }

  static Future<List<User>> findAllCheckedInUsers(ProductionLine productionLine) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "workorder/labor/checked_in_users",
        queryParameters: {
          "productionLineId": productionLine.id,
          "warehouseId": Global.currentWarehouse.id}
    );

    // printLongLogMessage("response from findAllCheckedInUsers: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("findAllCheckedInUsers / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


    List<User> users
        = (responseString["data"] as List)?.map((e) =>
        e == null ? null : User.fromJson(e as Map<String, dynamic>))
            ?.toList();
    printLongLogMessage("We get ${users.length}  users that checked in ${productionLine.name}");

    return users;


  }
}




