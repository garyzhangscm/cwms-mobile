// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rf_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RFConfiguration _$RFConfigurationFromJson(Map<String, dynamic> json) {
  return RFConfiguration()
    ..validatePartialLPNPick = json['validatePartialLPNPick'] == null ? false : json['validatePartialLPNPick'] as bool
    ..pickToProductionLineInStage = json['pickToProductionLineInStage'] == null ? false : json['pickToProductionLineInStage'] as bool
    ..receiveToStage = json['receiveToStage'] == null ? false : json['receiveToStage'] as bool
  ;
}

Map<String, dynamic> _$RFConfigurationToJson(RFConfiguration instance) =>
    <String, dynamic>{
      'validatePartialLPNPick': instance.validatePartialLPNPick,
      'pickToProductionLineInStage': instance.pickToProductionLineInStage,
      'receiveToStage': instance.receiveToStage
    };
