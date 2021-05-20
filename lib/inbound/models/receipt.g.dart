// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Receipt _$ReceiptFromJson(Map<String, dynamic> json) {
  return Receipt()
    ..id = json['id'] as int
    ..number = json['number'] as String
    ..client = json['client'] == null
        ? null
        : Client.fromJson(json['client'] as Map<String, dynamic>)
    ..supplier = json['supplier'] == null
        ? null
        : Supplier.fromJson(json['supplier'] as Map<String, dynamic>)
    ..receiptLines = (json['receiptLines'] as List)
        ?.map(
            (e) => e == null ? null : ReceiptLine.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..allowUnexpectedItem = json['allowUnexpectedItem'] as bool
    ..receiptStatus = receiptStatusFromString(json['receiptStatus'] as String);
}

Map<String, dynamic> _$ReceiptToJson(Receipt instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'client': instance.client,
  'supplier': instance.supplier,
  'receiptLines': instance.receiptLines,
  'allowUnexpectedItem': instance.allowUnexpectedItem,
  'receiptStatus': instance.receiptStatus,
};
