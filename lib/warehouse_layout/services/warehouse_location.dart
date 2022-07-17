
import 'dart:convert';



import 'package:cwms_mobile/exception/WebAPICallException.dart';
import 'package:cwms_mobile/shared/functions.dart';
import 'package:cwms_mobile/shared/global.dart';
import 'package:cwms_mobile/shared/http_client.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse.dart';
import 'package:cwms_mobile/warehouse_layout/models/warehouse_location.dart';
import 'package:dio/dio.dart';

class WarehouseLocationService {

  static Future<WarehouseLocation> getWarehouseLocationById(int id) async {


    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/layout/locations/$id",
    );

    print("response from getWarehouseLocationById:");

    printLongLogMessage(response.toString());

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    return WarehouseLocation.fromJson(responseString["data"] as Map<String, dynamic>);

  }
  static Future<WarehouseLocation> getWarehouseLocationByName(String locationName) async {


    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/layout/locations",
        queryParameters: {'warehouseId': Global.currentWarehouse.id,
          'name': locationName}
    );

    print("response from warehouse location:");

    printLongLogMessage(response.toString());

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    List<WarehouseLocation> locations
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : WarehouseLocation.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // we should only have one location returned since we qualify by
    // name and warehouse id
    if (locations.length != 1) {
      throw new WebAPICallException("can't find location by name ${locationName}");
    }
    else {
      return locations[0];
    }
  }


  static Future<WarehouseLocation> getWarehouseLocationByCode(String locationCode) async {


    Dio httpClient = CWMSHttpClient.getDio();

    Response response = await httpClient.get(
        "/layout/locations",
        queryParameters: {'warehouseId': Global.currentWarehouse.id,
          'code': locationCode}
    );

    print("response from warehouse location:");

    printLongLogMessage(response.toString());

    Map<String, dynamic> responseString = json.decode(response.toString());

    if (responseString["result"] as int != 0) {
      printLongLogMessage("Start to raise error with message: ${responseString["message"]}");
      throw new WebAPICallException(responseString["result"].toString() + ":" + responseString["message"]);
    }

    List<WarehouseLocation> locations
    = (responseString["data"] as List)?.map((e) =>
    e == null ? null : WarehouseLocation.fromJson(e as Map<String, dynamic>))
        ?.toList();

    // we should only have one location returned since we qualify by
    // name and warehouse id
    if (locations.length != 1) {
      throw new WebAPICallException("can't find location by code ${locationCode}");
    }
    else {
      return locations[0];
    }
  }

  static WarehouseLocation getBestLocationForNextPick(
      WarehouseLocation currentLocation,
      WarehouseLocation firstLocation,
      WarehouseLocation secondLocation) {
    if (_getBestLocationForNextActivity(
            currentLocation.pickSequence == null ? 0 : currentLocation.pickSequence,
            firstLocation.pickSequence == null ? 0 : firstLocation.pickSequence,
            secondLocation.pickSequence == null ? 0 : secondLocation.pickSequence) > 0) {
      return secondLocation;
    }
    else {
      return firstLocation;
    }
  }

  static WarehouseLocation getBestLocationForNextCount(
      WarehouseLocation currentLocation,
      WarehouseLocation firstLocation,
      WarehouseLocation secondLocation) {
    if (_getBestLocationForNextActivity(
        currentLocation.countSequence == null ? 0 : currentLocation.countSequence,
        firstLocation.countSequence == null ? 0 : firstLocation.countSequence,
        secondLocation.countSequence == null ? 0 : secondLocation.countSequence) > 0) {
      return secondLocation;
    }
    else {
      return firstLocation;
    }
  }
  static WarehouseLocation getBestLocationForNextPutaway(
      WarehouseLocation currentLocation,
      WarehouseLocation firstLocation,
      WarehouseLocation secondLocation) {
    if (_getBestLocationForNextActivity(
        currentLocation.putawaySequence == null ? 0 : currentLocation.putawaySequence,
        firstLocation.putawaySequence == null ? 0 : firstLocation.putawaySequence,
        secondLocation.putawaySequence == null ? 0 : secondLocation.putawaySequence) > 0) {
      return secondLocation;
    }
    else {
      return firstLocation;
    }
  }

  // return positive if second location first
  // return negative if first location first
  static int _getBestLocationForNextActivity(
      int currentLocationSequence,
      int firstLocationSequence,
      int secondLocationSequence) {

    print("_getBestLocationForNextActivity: ${currentLocationSequence} / ${firstLocationSequence} / ${secondLocationSequence}");
    int firstDistance = firstLocationSequence - currentLocationSequence;
    int secondDistance = secondLocationSequence - currentLocationSequence;
    // check if we are working forward or backward
    if (Global.isMovingForward()) {
      // if we are working forward but there's nothing left in front
      if (firstDistance < 0 && secondDistance < 0) {
        // get the location that's close to the current location
        return secondDistance - firstDistance;
      }
      else if (firstDistance > 0 && secondDistance > 0) {
        return firstDistance - secondDistance;
      }
      else {
        return secondDistance;
      }
    }
    else {

      // if we are working forward but there's nothing left at the back
      if (firstDistance > 0 && secondDistance > 0) {
        // get the location that's close to the current location
        return firstDistance - secondDistance;
      }
      else if (firstDistance < 0 && secondDistance < 0) {
        return secondDistance - firstDistance;
      }
      else {
        return firstDistance;
      }

    }
  }
}