
import 'dart:convert';

import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/outbound/models/pick.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:cwms_mobile/workorder/models/work_order.dart';
import 'package:dio/dio.dart';

import '../models/pick_mode.dart';

class PickService {
  static Future<Pick> getPicksByNumber(String number) async {
    Dio httpClient = CWMSHttpClient.getDio();
    printLongLogMessage("start to find pick by number $number");


    Response response = await httpClient.get(
        "outbound/picks",
        queryParameters: {
          "number": number, "warehouseId": Global.currentWarehouse.id}
    );

    Map<String, dynamic> responseString = json.decode(response.toString());

    List<Pick> picks
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : Pick.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // we should only have one pick that match with the number
    if (picks.isEmpty) {
      return null;
    }

    return picks[0];
  }

  static Future<List<Pick>> getPicksByOrder(int orderId) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "outbound/picks",
        queryParameters: {"orderId": orderId, "warehouseId": Global.currentWarehouse.id}
    );

    // print("response from Pick by Order: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    List<Pick> picks
    = (responseString["data"] as List)?.map((e) =>
      e == null ? null : Pick.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // Sort the picks according to the current location. We
    // will assign the closed pick to the user
    sortPicks(picks, Global.getLastActivityLocation(), Global.isMovingForward());

    return picks;
  }

  static Future<List<Pick>> getPicksByWorkOrder(WorkOrder workOrder) async {

    Dio httpClient = CWMSHttpClient.getDio();

    String workOrderLineIds = "";
    workOrder.workOrderLines.forEach((workOrderLine) {
      workOrderLineIds += workOrderLine.id.toString() + ",";
    });

    Response response = await httpClient.get(
        "outbound/picks",
        queryParameters: {"workOrderLineIds": workOrderLineIds, "warehouseId": Global.currentWarehouse.id}
    );

    // print("response from Pick by work order: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    List<Pick> picks
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : Pick.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // Sort the picks according to the current location. We
    // will assign the closed pick to the user
    sortPicks(picks, Global.getLastActivityLocation(), Global.isMovingForward());

    return picks;
  }


  static Future<List<Pick>> getPicksByWave(int waveId) async {
    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "outbound/picks",
        queryParameters: {"waveId": waveId, "warehouseId": Global.currentWarehouse.id}
    );

    // print("response from Pick by Order: $response");
    Map<String, dynamic> responseString = json.decode(response.toString());

    List<Pick> picks
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : Pick.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // Sort the picks according to the current location. We
    // will assign the closed pick to the user
    sortPicks(picks, Global.getLastActivityLocation(), Global.isMovingForward());

    return picks;
  }

  static void sortPicks(List<Pick> picks, WarehouseLocation currentLocation,
      bool isMovingForward) {
    if (currentLocation == null) {
      // if we don't know where the user is, then we will sort
      // the picks either forward, or backward
      if (isMovingForward) {
        picks.sort((pickA, pickB)   {
          if (pickA.skipCount > pickB.skipCount) {
            return 1;
          }
          else if (pickA.skipCount < pickB.skipCount) {
            return -1;
          }

          if (pickB.sourceLocation.pickSequence == null) {
            return -1;
          }
          else if (pickA.sourceLocation.pickSequence == null) {
            return 1;
          }
          else {
            return pickA.sourceLocation.pickSequence.compareTo(
                pickB.sourceLocation.pickSequence
            );
          }
        });
      }
      else {
        picks.sort((pickA, pickB) {

          if (pickA.skipCount > pickB.skipCount) {
            return 1;
          }
          else if (pickA.skipCount < pickB.skipCount) {
            return -1;
          }

          if (pickA.sourceLocation.pickSequence == null) {
            return -1;
          }
          else if (pickB.sourceLocation.pickSequence == null) {
            return 1;
          }
          else {
            return pickB.sourceLocation.pickSequence.compareTo(
                pickA.sourceLocation.pickSequence
            );
          }
        });
      }
    }
    else {
      // OK, we know where the user is. Let's get the best picks for the user
      // based on the proximity and direction
      // if both locations are in the same direction, then we will always return
      // the closed one.
      // otherwise, return the one in the right direction first
        picks.sort((pickA, pickB) {

          if (pickA.skipCount > pickB.skipCount) {
            return 1;
          }
          else if (pickA.skipCount < pickB.skipCount) {
            return -1;
          }

          int pickASourceLocationPickSequence = pickA.sourceLocation.pickSequence == null ?
              0: pickA.sourceLocation.pickSequence;
          int pickBSourceLocationPickSequence = pickB.sourceLocation.pickSequence == null ?
              0: pickB.sourceLocation.pickSequence;
          int currentLocationPickSequence = currentLocation.pickSequence == null ?
              0: currentLocation.pickSequence;

           if (pickASourceLocationPickSequence == currentLocationPickSequence) {
             return -1;
           }
           else if (pickB.sourceLocation.pickSequence == currentLocationPickSequence) {
             return 1;
           }
           else if ((pickASourceLocationPickSequence - currentLocationPickSequence) *
               (pickBSourceLocationPickSequence - currentLocationPickSequence) > 0) {
             return (pickASourceLocationPickSequence - currentLocationPickSequence).abs().compareTo(
                 (pickBSourceLocationPickSequence - currentLocationPickSequence).abs());
           }
           else {
             if (isMovingForward) {
               // moving forward, return the one that is in the forward direction first
               return pickASourceLocationPickSequence.compareTo(
                   currentLocationPickSequence
               );
             }
             else {
               // moving backward, return the one that is in the forward direction first
               return pickBSourceLocationPickSequence.compareTo(
                   currentLocationPickSequence
               );
             }

           }
        });
      }
  }

  static Future<void> confirmWholePick(Pick pick)  async{
    return confirmPick(pick, (pick.quantity - pick.pickedQuantity));

  }
  // Confirm pick, with picking quantity
  static Future<void> confirmPick(Pick pick, int confirmQuantity,
  {String lpn = "", String nextLocationName = "", String destinationLpn = "",
      bool retainLPNForLPNPick = true}) async{

    printLongLogMessage("start to confirm pick ${pick.number}, confirmQuantity: ${confirmQuantity}, lpn: ${lpn}");

    // only continue when the confirmed quantity is bigger than 0
    if (confirmQuantity <= 0) {
      return;
    }
    if (confirmQuantity >  (pick.quantity - pick.pickedQuantity)) {
      // throw error as we can't over pick

    }

    Dio httpClient = CWMSHttpClient.getDio();

    Map<String, dynamic> queryParameters = new Map<String, dynamic>();

    queryParameters["warehouseId"] = Global.currentWarehouse.id;
    queryParameters["quantity"] = confirmQuantity;
    queryParameters["nextLocationName"] = nextLocationName.isEmpty ? Global.getLastLoginRFCode() : nextLocationName;
    if (lpn.isNotEmpty) {
      queryParameters["lpn"] = lpn;

    }
    // we will pick into a new destination only if
    // 1. if the pick is a whole LPN pick but the user choose to pick into a new LPN(retainLPNForLPNPick = false)
    // 2. or the pick is not a whole LPN pick
    bool pickToNewLPN = !pick.wholeLPNPick || !retainLPNForLPNPick;
    if (pickToNewLPN && destinationLpn.isNotEmpty) {
      printLongLogMessage("the pick is a whole LPN pick? ${pick.wholeLPNPick}, user choose to retain LPN? ${retainLPNForLPNPick}");
      printLongLogMessage("we will pick into a new LPN ${destinationLpn}");
      queryParameters["destinationLpn"] = destinationLpn;

    }

    // pick to RF
    // if the user specify the next location, then pick to the next location
    // otherwise  pick to the RF
    printLongLogMessage("start to pick to ${nextLocationName.isEmpty ? Global.getLastLoginRFCode() : nextLocationName}");
    Response response = await httpClient.post(
        "outbound/picks/${pick.id}/confirm",
        queryParameters: queryParameters
    );

    // print("response from confirm pick: $response");

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("confirmPick / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }


  }

  // check if the 2 picks pick inventory
  // 1. from same location
  // 2. for the same item
  // 3. with same inventory attirbute
  // 3.1 inventory status
  // 3.2 color / product size / style / etc.
  static bool pickInventoryWithSameAttribute(Pick pickA, Pick pickB) {
    if (pickA.sourceLocationId != pickB.sourceLocationId) {
      return false;
    }
    if (pickA.itemId != pickB.itemId) {
      return false;
    }
    if (pickA.inventoryStatusId != pickB.inventoryStatusId) {
      return false;
    }
    if (pickA.color != null && pickA.color.isNotEmpty &&
        pickB.color != null && pickB.color.isNotEmpty &&
        pickA.color != pickB.color) {
      return false;
    }
    if (pickA.productSize != null && pickA.productSize.isNotEmpty &&
        pickB.productSize != null && pickB.productSize.isNotEmpty &&
        pickA.productSize != pickB.productSize) {
      return false;
    }
    if (pickA.style != null && pickA.style.isNotEmpty &&
        pickB.style != null && pickB.style.isNotEmpty &&
        pickA.style != pickB.style) {
      return false;
    }

    if (pickA.inventoryAttribute1 != null && pickA.inventoryAttribute1.isNotEmpty &&
        pickB.inventoryAttribute1 != null && pickB.inventoryAttribute1.isNotEmpty &&
        pickA.inventoryAttribute1 != pickB.inventoryAttribute1) {
      return false;
    }

    if (pickA.inventoryAttribute2 != null && pickA.inventoryAttribute2.isNotEmpty &&
        pickB.inventoryAttribute2 != null && pickB.inventoryAttribute2.isNotEmpty &&
        pickA.inventoryAttribute2 != pickB.inventoryAttribute2) {
      return false;
    }

    if (pickA.inventoryAttribute3 != null && pickA.inventoryAttribute3.isNotEmpty &&
        pickB.inventoryAttribute3 != null && pickB.inventoryAttribute3.isNotEmpty &&
        pickA.inventoryAttribute3 != pickB.inventoryAttribute3) {
      return false;
    }

    if (pickA.inventoryAttribute4 != null && pickA.inventoryAttribute4.isNotEmpty &&
        pickB.inventoryAttribute4 != null && pickB.inventoryAttribute4.isNotEmpty &&
        pickA.inventoryAttribute4 != pickB.inventoryAttribute4) {
      return false;
    }

    if (pickA.inventoryAttribute5 != null && pickA.inventoryAttribute5.isNotEmpty &&
        pickB.inventoryAttribute5 != null && pickB.inventoryAttribute5.isNotEmpty &&
        pickA.inventoryAttribute5 != pickB.inventoryAttribute5) {
      return false;
    }

    if (pickA.allocateByReceiptNumber != null && pickA.allocateByReceiptNumber.isNotEmpty &&
        pickB.allocateByReceiptNumber != null && pickB.allocateByReceiptNumber.isNotEmpty &&
        pickA.allocateByReceiptNumber != pickB.allocateByReceiptNumber) {
      return false;
    }
    return true;
  }


  static Future<Pick> acknowledgePick(int id) async{

    printLongLogMessage("start to acknowledge pick  by id $id");


    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "outbound/pick/${id}/acknowledge",
        queryParameters: {
          "warehouseId": Global.currentWarehouse.id,
          "rfCode": Global.lastLoginRFCode,
        }
    );

    // print("response from confirm pick: $response");

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("acknowledgePick / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return Pick.fromJson(responseString["data"] as Map<String, dynamic>) ;

  }
  static Future<Pick> unacknowledgePick(int id) async{

    printLongLogMessage("start to unacknowledge pick  by id $id");


    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "outbound/pick/${id}/unacknowledge",
        queryParameters: {
          "warehouseId": Global.currentWarehouse.id
        }
    );

    // print("response from confirm pick: $response");

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("unacknowledgePick / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return Pick.fromJson(responseString["data"] as Map<String, dynamic>) ;

  }


  // check the pick can be acknowledged by current user
  static Future<bool> isPickAcknowledgable(int id) async{

    printLongLogMessage("start to check if  pick   $id can be acknowleged by current user");


    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.post(
        "outbound/pick/${id}/acknowledgeable-by-current-user",
        queryParameters: {
          "warehouseId": Global.currentWarehouse.id,
          "rfCode": Global.lastLoginRFCode,
        }
    );

    Map<String, dynamic> responseString = json.decode(response.toString());

    printLongLogMessage("response from isPickAcknowledgable: $responseString");

    if (responseString["result"] as int != 0) {
      printLongLogMessage("isPickAcknowledgable / Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return responseString["data"];




  }


}




