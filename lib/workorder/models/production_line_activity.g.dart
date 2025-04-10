// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_line_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************


ProductionLineActivity _$ProductionLineActivityFromJson(Map<String, dynamic> json) {
  return ProductionLineActivity()
    ..id = json['id'] as int
    ..workOrder = json['workOrder'] == null
        ? null
        : WorkOrder.fromJson(json['workOrder'] as Map<String, dynamic>)
    ..productionLine = json['productionLine'] == null
        ? null
        : ProductionLine.fromJson(json['productionLine'] as Map<String, dynamic>)
    ..warehouseId = json['warehouseId']
    ..username = json['username']
    ..user = json['user'] == null
        ? null
        : User.fromJson(json['user'] as Map<String, dynamic>)
    ..type =  EnumToString.fromString(ProductionLineActivityType.values, json['type'] as String)
    ..workingTeamMemberCount = json['workingTeamMemberCount']
    ..transactionTime = json['transactionTime'] == null
        ? null
        : DateTime.parse(json['transactionTime'] as String);
}

Map<String, dynamic> _$ProductionLineActivityToJson(ProductionLineActivity instance) => <String, dynamic>{
  'id': instance.id,
  'workOrder': instance.workOrder,
  'productionLine': instance.productionLine,
  'warehouseId': instance.warehouseId,
  'username': instance.username,
  'user': instance.user,
  'type': instance.type,
  'workingTeamMemberCount': instance.workingTeamMemberCount,
  'transactionTime': instance.transactionTime,
};
