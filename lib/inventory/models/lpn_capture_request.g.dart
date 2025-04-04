// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lpn_capture_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LpnCaptureRequest _$LpnCaptureRequestFromJson(Map<String, dynamic> json) {
  return LpnCaptureRequest()
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..itemPackageType = json['itemPackageType'] == null
        ? null
        : ItemPackageType.fromJson(json['itemPackageType'] as Map<String, dynamic>)
    ..lpnUnitOfMeasure = json['lpnUnitOfMeasure'] == null
        ? null
        : ItemUnitOfMeasure.fromJson(json['lpnUnitOfMeasure'] as Map<String, dynamic>)
    ..requestedLPNQuantity = json['requestedLPNQuantity'] as int
    ..capturedLpn = (json['capturedLpn'] as List)
        .map(
            (e) =>  (e as String))
        .toSet()
    ..result = json['result'] as bool;
}

Map<String, dynamic> _$LpnCaptureRequestToJson(LpnCaptureRequest instance) => <String, dynamic>{
      'item': instance.item,
      'itemPackageType': instance.itemPackageType,
      'lpnUnitOfMeasure': instance.lpnUnitOfMeasure,
      'requestedLPNQuantity': instance.requestedLPNQuantity,
      'capturedLpn': instance.capturedLpn,
          'result': instance.result,
    };
