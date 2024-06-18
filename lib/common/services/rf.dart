
import 'dart:convert';

import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/models/rf.dart';
import 'package:dio/dio.dart';

import '../../exception/WebAPICallException.dart';
import '../../shared/http_client.dart';

class RFService {

  static Future<bool> valdiateRFCode(int warehouseId, String rfCode) async {

    // we will need to use the standard dio instead because
    // 1. we will validate the RF code before we log in so we probably don't have the
    //   auth token yet
    // 2. we don't have to have the auth token. all the */validate/** endpoint won't
    //    probably requires auth info
    Response response = await Dio().get(
        Global.currentServer.url + "resource/validate/rf",
        queryParameters: {
          "warehouseId": warehouseId,
          "rfCode": rfCode}
    );

    Map<String, dynamic> responseString = json.decode(response.toString());

    printLongLogMessage("response from valdiateRFCode: $responseString");

    if (responseString["result"] as int != 0) {
      printLongLogMessage("isPickAcknowledgable / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    bool isValid = responseString["data"];

    return isValid;

  }


  static Future<RF> getRFByCode(String rfCode) async {
    return getRFByCodeAndWarehouseId(Global.currentWarehouse.id, rfCode);
  }
  static Future<RF> getRFByCodeAndWarehouseId(int warehouseId, String rfCode) async {

    Dio httpClient = CWMSHttpClient.getDio();

    // we will need to use the standard dio instead because
    // 1. we will validate the RF code before we log in so we probably don't have the
    //   auth token yet
    // 2. we don't have to have the auth token. all the */validate/** endpoint won't
    //    probably requires auth info
    Response response = await httpClient.get(
        Global.currentServer.url + "resource/rfs",
        queryParameters: {
          "warehouseId": warehouseId,
          "rfCode": rfCode}
    );

    Map<String, dynamic> responseString = json.decode(response.toString());


    if (responseString["result"] as int != 0) {
      printLongLogMessage("getRFByCode / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    print("getRFByCodeAndWarehouseId returns: ${responseString["data"]}");

    List<RF> rfs
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : RF.fromJson(e as Map<String, dynamic>))
        ?.toList();

    if (rfs == null || rfs.isEmpty) {

      throw new WebAPICallException("can't find RF by code $rfCode");
    }
    return rfs[0];

  }

  static Future<RF> changeCurrentRFLocation(int locationId) async {
    return changeRFLocation(Global.currentWarehouse.id,
        Global.getLastLoginRF().id, locationId);
  }
  static Future<RF> changeRFLocation(int warehouseId, int id, int locationId) async {

    Dio httpClient = CWMSHttpClient.getDio();

    // we will need to use the standard dio instead because
    // 1. we will validate the RF code before we log in so we probably don't have the
    //   auth token yet
    // 2. we don't have to have the auth token. all the */validate/** endpoint won't
    //    probably requires auth info
    Response response = await httpClient.post(
        Global.currentServer.url + "resource/rfs/${id}/change-location",
        queryParameters: {
          "warehouseId": warehouseId,
          "locationId": locationId,
        }
    );

    Map<String, dynamic> responseString = json.decode(response.toString());

    print("response from changeCurrentRFLocation: ");

    printLongLogMessage(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("fail to change the location for current RF: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    Map<String, dynamic> responseData = responseString["data"] as Map<String, dynamic>;
    if (responseData == null || responseData.isEmpty) {
      throw new WebAPICallException("fail to change the location for current RF");
    }

    // refresh the RF with the new location
    RF rf = RF.fromJson(responseData);
    Global.setLastLoginRF(rf);
    return rf;



  }
}




