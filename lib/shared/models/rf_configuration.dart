

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';

import 'cwms_application_information.dart';

// server.g.dart 将在我们运行生成命令后自动生成
part 'rf_configuration.g.dart';

///这个标注是告诉生成器，这个类是需要生成Model类的
@JsonSerializable()

class RFConfiguration {
  RFConfiguration() {
    workOrderValidatePartialLPNPick = false;
    pickToProductionLineInStage = true;
    receiveToStage = false;
    listPickBatchPicking = true;
    autoDepositForLpnWithSameDestination = false;

  }

  bool workOrderValidatePartialLPNPick;

  bool outboundOrderValidatePartialLPNPick;
  bool pickToProductionLineInStage;
  bool receiveToStage;
  bool listPickBatchPicking;
  String printerName;

  bool autoDepositForLpnWithSameDestination;


  //不同的类使用不同的mixin即可
  factory RFConfiguration.fromJson(Map<String, dynamic> json) => _$RFConfigurationFromJson(json);
  Map<String, dynamic> toJson() => _$RFConfigurationToJson(this);


}
