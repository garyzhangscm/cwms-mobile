// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportHistory _$ReportHistoryFromJson(Map<String, dynamic> json) {
  return ReportHistory()
    ..id = json['id'] == null ? null : json['id']  as int
    ..warehouseId = json['warehouseId'] == null ? null : json['warehouseId']  as int
    ..printedDate = json['printedDate'] == null ? null : DateTime.parse(json['printedDate'] as String)
    ..printedUsername = json['printedUsername'] == null ? null : json['printedUsername'] as String
    ..description = json['description'] == null ? null : json['description'] as String
    ..type = json['type'] == null ? null : reportTypeFromString(json['type'] as String)
    ..fileName = json['fileName'] == null ? null : json['fileName'] as String
    ..reportOrientation = json['reportOrientation'] == null ? null : reportOrientationFromString(json['reportOrientation'] as String)
  ;
}

Map<String, dynamic> _$ReportHistoryToJson(ReportHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'warehouseId': instance.warehouseId,
      'printedDate': instance.printedDate,
      'printedUsername': instance.printedUsername,
      'description': instance.description,
      'type': instance.type,
      'fileName': instance.fileName,
      'reportOrientation': instance.reportOrientation
    };
