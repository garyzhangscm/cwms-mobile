// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_count_batch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CycleCountBatch _$CycleCountBatchFromJson(Map<String, dynamic> json) {
  return CycleCountBatch()
    ..id = json['id'] as int
    ..batchId = json['batchId'] as String
    ..warehouseId = json['warehouseId'] as int
    ..requestLocationCount = json['requestLocationCount'] as int
    ..openLocationCount = json['openLocationCount'] as int
    ..finishedLocationCount = json['finishedLocationCount'] as int
    ..cancelledLocationCount = json['cancelledLocationCount'] as int
    ..openAuditLocationCount = json['openAuditLocationCount'] as int
    ..finishedAuditLocationCount = json['finishedAuditLocationCount'] as int;
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
