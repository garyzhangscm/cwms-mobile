// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qc_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QCRule _$QCRuleFromJson(Map<String, dynamic> json) {
  return QCRule()
    ..id = json['id'] as int
    ..warehouseId = json['warehouseId']
    ..name = json['name']
    ..description = json['description']
    ..qcRuleItems = json['qcRuleItems'] == null ?
        [] :
        (json['qcRuleItems'] as List)
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
