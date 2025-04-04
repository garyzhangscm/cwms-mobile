// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qc_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QCRule _$QCRuleFromJson(Map<String, dynamic> json) {
  return QCRule()
    ..id = json['id'] as int
    ..warehouseId = json['warehouseId'] as int
    ..name = json['name'] as String
    ..description = json['description'] as String
    ..qcRuleItems = (json['qcRuleItems'] as List)
        .map(
            (e) => QCRuleItem.fromJson(e as Map<String, dynamic>))
        .toList();
}

Map<String, dynamic> _$QCRuleToJson(QCRule instance) => <String, dynamic>{
      'id': instance.id,
      'warehouseId': instance.warehouseId,
      'name': instance.name,
      'description': instance.description,
  'qcRuleItems': instance.qcRuleItems,
};
