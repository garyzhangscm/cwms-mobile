// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pick_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PickResult _$PickResultFromJson(Map<String, dynamic> json) {
  return PickResult()
    ..result = json['result'] as bool
    ..confirmedQuantity = json['confirmedQuantity'] as int;
}

Map<String, dynamic> _$PickResultToJson(PickResult instance) => <String, dynamic>{
  'result': instance.result,
  'confirmedQuantity': instance.confirmedQuantity,
};
