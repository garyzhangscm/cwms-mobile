// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiptLine _$ReceiptLineFromJson(Map<String, dynamic> json) {
  return ReceiptLine()
    ..id = json['id'] as int
    ..number = json['number'] as String
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..expectedQuantity = json['expectedQuantity'] as int
    ..receivedQuantity = json['receivedQuantity'] as int
    ..overReceivingQuantity = json['overReceivingQuantity'] as int
    ..overReceivingPercent = json['overReceivingPercent'] as double;
}

Map<String, dynamic> _$ReceiptLineToJson(ReceiptLine instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'item': instance.item,
  'expectedQuantity': instance.expectedQuantity,
  'receivedQuantity': instance.receivedQuantity,
  'overReceivingQuantity': instance.overReceivingQuantity,
  'overReceivingPercent': instance.overReceivingPercent,
};
