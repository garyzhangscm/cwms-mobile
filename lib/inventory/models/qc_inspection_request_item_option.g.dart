// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qc_inspection_request_item_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QCInspectionRequestItemOption _$QCInspectionRequestItemOptionFromJson(Map<String, dynamic> json) {
  return QCInspectionRequestItemOption()
    ..id = json['id'] as int
    ..booleanValue = json['booleanValue'] == null
        ? null
        : json['booleanValue']
    ..stringValue = json['stringValue'] == null
        ? ""
        : json['stringValue']
    ..doubleValue = json['doubleValue'] == null
        ? null
        : json['doubleValue']
    ..qcRuleItem = json['qcRuleItem'] == null
        ? null
        : QCRuleItem.fromJson(json['qcRuleItem'] as Map<String, dynamic>)
    ..qcInspectionResult = json['qcInspectionResult'] == null
        ? null : EnumToString.fromString(QCInspectionResult.values, json['qcInspectionResult'] as String);
}

Map<String, dynamic> _$QCInspectionRequestItemOptionToJson(QCInspectionRequestItemOption instance) => <String, dynamic>{
      'id': instance.id,
      'booleanValue': instance.booleanValue,
      'stringValue': instance.stringValue,
      'doubleValue': instance.doubleValue,
      'qcRuleItem': instance.qcRuleItem,
      'qcInspectionResult': EnumToString.convertToString(instance.qcInspectionResult),
    };
