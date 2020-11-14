// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_count_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CycleCountRequest _$CycleCountRequestFromJson(Map<String, dynamic> json) {
  return CycleCountRequest()
    ..id = json['id'] as int
    ..batchId = json['batchId'] as String
    ..location = json['location'] == null
        ? null
        : WarehouseLocation.fromJson(json['location'] as Map<String, dynamic>);
}

Map<String, dynamic> _$CycleCountRequestToJson(CycleCountRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'batchId': instance.batchId,
      'location': instance.location,
    };
