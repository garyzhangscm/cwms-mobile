// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rf.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RF _$RFFromJson(Map<String, dynamic> json) {
  return RF()
    ..warehouseId = json['warehouseId'] == null ? null : json['warehouseId']  as int
    ..id = json['id'] == null ? null : json['id']  as int
    ..rfCode = json['rfCode'] == null ? "" : json['rfCode'] as String
    ..currentLocationId = json['currentLocationId'] == null ? null : json['currentLocationId'] as int
    ..currentLocationName = json['currentLocationName'] == null ? "" : json['currentLocationName'] as String
    ..printerName = json['printerName'] == null ? "" :  json['printerName'] as String
  ;
}

Map<String, dynamic> _$RFToJson(RF instance) =>
    <String, dynamic>{
      'warehouseId': instance.warehouseId,
      'id': instance.id,
      'rfCode': instance.rfCode,
      'currentLocationId': instance.currentLocationId,
      'currentLocationName': instance.currentLocationName,
      'printerName': instance.printerName
    };
