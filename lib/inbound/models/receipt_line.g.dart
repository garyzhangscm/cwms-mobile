// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceiptLine _$ReceiptLineFromJson(Map<String, dynamic> json) {
  return ReceiptLine()
    ..id = json['id'] as int
    ..number = json['number']
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..expectedQuantity = json['expectedQuantity']
    ..arrivedQuantity = json['arrivedQuantity']
    ..receivedQuantity = json['receivedQuantity']
    ..itemPackageTypeId = json['itemPackageTypeId']  == null ?  null : json['itemPackageTypeId']  as int
    ..overReceivingQuantity = json['overReceivingQuantity']
    ..overReceivingPercent = json['overReceivingPercent']  ;
}

Map<String, dynamic> _$ReceiptLineToJson(ReceiptLine instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'item': instance.item,
  'expectedQuantity': instance.expectedQuantity,
  'arrivedQuantity': instance.arrivedQuantity,
  'receivedQuantity': instance.receivedQuantity,
  'itemPackageTypeId': instance.itemPackageTypeId,
  'overReceivingQuantity': instance.overReceivingQuantity,
  'overReceivingPercent': instance.overReceivingPercent,
};
