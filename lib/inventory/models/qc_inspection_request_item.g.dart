// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qc_inspection_request_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QCInspectionRequestItem _$QCInspectionRequestItemFromJson(Map<String, dynamic> json) {
  return QCInspectionRequestItem()
    ..id = json['id'] as int
    ..qcRule = json['qcRule'] == null
        ? null
        : QCRule.fromJson(json['qcRule'] as Map<String, dynamic>)
    ..qcInspectionResult = json['qcInspectionResult'] == null
        ? null : EnumToString.fromString(QCInspectionResult.values, json['qcInspectionResult'] as String)
    ..qcInspectionRequestItemOptions = (json['qcInspectionRequestItemOptions'] as List)
        .map(
            (e) => QCInspectionRequestItemOption.fromJson(e as Map<String, dynamic>))
        .toList();;
}

Map<String, dynamic> _$QCInspectionRequestItemToJson(QCInspectionRequestItem instance) => <String, dynamic>{
      'id': instance.id,
      'qcRule': instance.qcRule,
      'qcInspectionResult': EnumToString.convertToString(instance.qcInspectionResult),
      'qcInspectionRequestItemOptions': instance.qcInspectionRequestItemOptions,
    };
