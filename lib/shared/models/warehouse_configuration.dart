

import 'package:cwms_mobile/shared/models/printing_strategy.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

import 'cwms_application_information.dart';

// server.g.dart 将在我们运行生成命令后自动生成
part 'warehouse_configuration.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class WarehouseConfiguration {
  WarehouseConfiguration();


  bool? threePartyLogisticsFlag;
  bool? listPickEnabledFlag;

  PrintingStrategy? printingStrategy;


  bool? newLPNPrintLabelAtReceivingFlag;
  bool? newLPNPrintLabelAtProducingFlag;
  bool? newLPNPrintLabelAtAdjustmentFlag;



  //不同的类使用不同的mixin即可
  factory WarehouseConfiguration.fromJson(Map<String, dynamic> json) => _$WarehouseConfigurationFromJson(json);
  Map<String, dynamic> toJson() => _$WarehouseConfigurationToJson(this);


}
