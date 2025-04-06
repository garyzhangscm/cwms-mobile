// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warehouse_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WarehouseConfiguration _$WarehouseConfigurationFromJson(Map<String, dynamic> json) {
  return WarehouseConfiguration()
    ..threePartyLogisticsFlag = json['threePartyLogisticsFlag'] == null ? false : json['threePartyLogisticsFlag'] as bool
    ..listPickEnabledFlag = json['listPickEnabledFlag'] == null ? false : json['listPickEnabledFlag'] as bool
    ..newLPNPrintLabelAtReceivingFlag = json['newLPNPrintLabelAtReceivingFlag'] == null ? false : json['newLPNPrintLabelAtReceivingFlag'] as bool
    ..newLPNPrintLabelAtProducingFlag = json['newLPNPrintLabelAtProducingFlag'] == null ? false : json['newLPNPrintLabelAtProducingFlag'] as bool
    ..newLPNPrintLabelAtAdjustmentFlag = json['newLPNPrintLabelAtAdjustmentFlag'] == null ? false : json['newLPNPrintLabelAtAdjustmentFlag'] as bool
    ..printingStrategy = (json['printingStrategy'] == null ? false : printingStrategyFromString(json['printingStrategy'] as String)) as PrintingStrategy?;
  ;
}

Map<String, dynamic> _$WarehouseConfigurationToJson(WarehouseConfiguration instance) =>
    <String, dynamic>{
      'threePartyLogisticsFlag': instance.threePartyLogisticsFlag,
      'listPickEnabledFlag': instance.listPickEnabledFlag,
      'newLPNPrintLabelAtReceivingFlag': instance.newLPNPrintLabelAtReceivingFlag,
      'newLPNPrintLabelAtProducingFlag': instance.newLPNPrintLabelAtProducingFlag,
      'newLPNPrintLabelAtAdjustmentFlag': instance.newLPNPrintLabelAtAdjustmentFlag,
      'printingStrategy': instance.printingStrategy
    };
