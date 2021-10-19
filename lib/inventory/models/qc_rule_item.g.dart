// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qc_rule_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QCRuleItem _$QCRuleItemFromJson(Map<String, dynamic> json) {
  return QCRuleItem()
    ..id = json['id'] as int
    ..checkPoint = json['checkPoint'] as String
    ..qcRuleItemType = json['qcRuleItemType'] == null
        ? null : EnumToString.fromString(QCRuleItemType.values, json['qcRuleItemType'] as String)
    ..expectedValue = json['expectedValue'] as String
    ..qcRuleItemComparator = json['qcRuleItemComparator'] == null
        ? null : EnumToString.fromString(QCRuleItemComparator.values, json['qcRuleItemComparator'] as String);
}

Map<String, dynamic> _$QCRuleItemToJson(QCRuleItem instance) => <String, dynamic>{
      'id': instance.id,
      'checkPoint': instance.checkPoint,
      'qcRuleItemType': EnumToString.convertToString(instance.qcRuleItemType),
    'expectedValue': instance.expectedValue,
    'qcRuleItemComparator': EnumToString.convertToString(instance.qcRuleItemComparator),
    };
