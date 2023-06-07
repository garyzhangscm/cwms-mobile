
import 'dart:convert';

import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/models/rf.dart';
import 'package:dio/dio.dart';

import '../../exception/WebAPICallException.dart';

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

    // printLongLogMessage("response from valdiateRFCode: $responseString");

    bool isValid = responseString["data"];

    return isValid;

  }


  static Future<RF> getRFByCode(String rfCode) async {

    // we will need to use the standard dio instead because
    // 1. we will validate the RF code before we log in so we probably don't have the
    //   auth token yet
    // 2. we don't have to have the auth token. all the */validate/** endpoint won't
    //    probably requires auth info
    Response response = await Dio().get(
        Global.currentServer.url + "resource/rfs",
        queryParameters: {
          "warehouseId": Global.currentWarehouse.id,
          "rfCode": rfCode}
    );

    Map<String, dynamic> responseString = json.decode(response.toString());


    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


    List<RF> rfs
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : RF.fromJson(e as Map<String, dynamic>))
        ?.toList();

    if (rfs == null || rfs.isEmpty) {

      throw new WebAPICallException("can't find RF by code $rfCode");
    }
    return rfs[0];

  }
}




