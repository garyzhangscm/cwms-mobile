// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OperationType _$OperationTypeFromJson(Map<String, dynamic> json) {
  return OperationType()
    ..id = json['id'] as int
    ..name = json['name']
    ..description = json['description']
    ..defaultPriority = json['defaultPriority']  ;
}

Map<String, dynamic> _$OperationTypeToJson(OperationType instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'defaultPriority': instance.defaultPriority,
};
