
import 'dart:convert';

import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:dio/dio.dart';

class PickService {
  // Get all cycle count requests by batch id
  static Future<List<Pick>> getPicksByOrder(String orderNumber) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "outbound/picks",
        queryParameters: {"orderNumber": orderNumber, "warehouseId": Global.currentWarehouse.id}
    );

    print("response from Pick by Order: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());
    List<dynamic> responseData = responseString["data"];

    List<Pick> picks
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : Pick.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // Sort the picks according to the current location. We
    // will assign the closed pick to the user
    sortPicks(picks, Global.lastActivityLocation, Global.isMovingForward());

    return picks;
  }

  static void sortPicks(List<Pick> picks, WarehouseLocation currentLocation,
      bool isMovingForward) {
    if (currentLocation == null) {
      // if we don't know where the user is, then we will sort
      // the picks either forward, or backward
      if (isMovingForward) {
        picks.sort((pickA, pickB) =>
            pickA.sourceLocation.pickSequence.compareTo(
            pickB.sourceLocation.pickSequence
        ) );
      }
      else {
        picks.sort((pickA, pickB) =>
            pickB.sourceLocation.pickSequence.compareTo(
                pickA.sourceLocation.pickSequence
            ) );
      }
    }
    else {
      // OK, we know where the user is. Let's get the best picks for the user
      // based on the proximity and direction
      // if both locations are in the same direction, then we will always return
      // the closed one.
      // otherwise, return the one in the right direction first
        picks.sort((pickA, pickB) {
           if (pickA.sourceLocation.pickSequence == currentLocation.pickSequence) {
             return 1;
           }
           else if (pickB.sourceLocation.pickSequence == currentLocation.pickSequence) {
             return -1;
           }
           else if ((pickA.sourceLocation.pickSequence - currentLocation.pickSequence) *
               (pickB.sourceLocation.pickSequence - currentLocation.pickSequence) > 0) {
             return (pickA.sourceLocation.pickSequence - currentLocation.pickSequence).abs().compareTo(
                 (pickB.sourceLocation.pickSequence - currentLocation.pickSequence).abs());
           }
           else {
             if (isMovingForward) {
               // moving forward, return the one that is in the forward direction first
               return pickA.sourceLocation.pickSequence.compareTo(
                 currentLocation.pickSequence
               );
             }
             else {
               // moving backward, return the one that is in the forward direction first
               return pickB.sourceLocation.pickSequence.compareTo(
                   currentLocation.pickSequence
               );
             }

           }
        });
      }

  }

}




