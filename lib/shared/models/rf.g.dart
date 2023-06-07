// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rf.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RF _$RFFromJson(Map<String, dynamic> json) {
  return RF()
    ..warehouseId = json['warehouseId'] == null ? false : json['warehouseId']  as int
    ..rfCode = json['rfCode'] == null ? false : json['rfCode'] as String
    ..currentLocationId = json['currentLocationId'] == null ? false : json['currentLocationId'] as int
    ..printerName = json['printerName'] == null ? false : json['printerName'] as String
  ;
}

Map<String, dynamic> _$RFToJson(RF instance) =>
    <String, dynamic>{
      'warehouseId': instance.warehouseId,
      'rfCode': instance.rfCode,
      'currentLocationId': instance.currentLocationId,
      'printerName': instance.printerName
    };
