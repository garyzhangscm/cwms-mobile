// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order_kpi_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkOrderKPITransaction _$WorkOrderKPITransactionFromJson(Map<String, dynamic> json) {
  return WorkOrderKPITransaction()
    ..id = json['id'] as int
    ..username = json['username']
    ..workingTeamName = json['workingTeamName']
    ..kpiMeasurement =  EnumToString.fromString(KPIMeasurement.values, json['kpiMeasurement'] as String)
    ..type =  EnumToString.fromString(WorkOrderKPITransactionType.values, json['type'] as String)
    ..amount = json['amount']  ;
}

Map<String, dynamic> _$WorkOrderKPITransactionToJson(WorkOrderKPITransaction instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'workingTeamName': instance.workingTeamName,
  'kpiMeasurement': instance.kpiMeasurement,
  'type': instance.type,
  'amount': instance.amount,
};
