// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_count_batch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CycleCountBatch _$CycleCountBatchFromJson(Map<String, dynamic> json) {
  return CycleCountBatch()
    ..id = json['id'] as int
    ..batchId = json['batchId']
    ..warehouseId = json['warehouseId']
    ..requestLocationCount = json['requestLocationCount']
    ..openLocationCount = json['openLocationCount']
    ..finishedLocationCount = json['finishedLocationCount']
    ..cancelledLocationCount = json['cancelledLocationCount']
    ..openAuditLocationCount = json['openAuditLocationCount']
    ..finishedAuditLocationCount = json['finishedAuditLocationCount'] ;
}

Map<String, dynamic> _$CycleCountBatchToJson(CycleCountBatch instance) => <String, dynamic>{
      'id': instance.id,
      'batchId': instance.batchId,
      'warehouseId': instance.warehouseId,
      'requestLocationCount': instance.requestLocationCount,
      'openLocationCount': instance.openLocationCount,
      'finishedLocationCount': instance.finishedLocationCount,
      'cancelledLocationCount': instance.cancelledLocationCount,
      'openAuditLocationCount': instance.openAuditLocationCount,
      'finishedAuditLocationCount': instance.finishedAuditLocationCount,
    };
