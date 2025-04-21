// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pick_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PickResult _$PickResultFromJson(Map<String, dynamic> json) {
  return PickResult()
    ..pickId = json['pickId']
    ..result = json['result']
    ..confirmedQuantity = json['confirmedQuantity']  ;
}

Map<String, dynamic> _$PickResultToJson(PickResult instance) => <String, dynamic>{
  'result': instance.result,
  'pickId': instance.pickId,
  'confirmedQuantity': instance.confirmedQuantity,
};
