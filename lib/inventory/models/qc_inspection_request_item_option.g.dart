// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qc_inspection_request_item_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QCInspectionRequestItemOption _$QCInspectionRequestItemOptionFromJson(Map<String, dynamic> json) {
  return QCInspectionRequestItemOption()
    ..id = json['id'] as int
    ..qcRuleItem = json['qcRuleItem'] == null
        ? null
        : QCRuleItem.fromJson(json['qcRuleItem'] as Map<String, dynamic>)
    ..qcInspectionResult = json['qcInspectionResult'] == null
        ? null : EnumToString.fromString(QCInspectionResult.values, json['qcInspectionResult'] as String);
}

Map<String, dynamic> _$QCInspectionRequestItemOptionToJson(QCInspectionRequestItemOption instance) => <String, dynamic>{
      'id': instance.id,
      'qcRuleItem': instance.qcRuleItem,
      'qcInspectionResult': EnumToString.convertToString(instance.qcInspectionResult),
    };
