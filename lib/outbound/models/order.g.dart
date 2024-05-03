// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) {
  return Order()
    ..id = json['id'] as int
    ..number = json['number'] as String
    ..shipToCustomer = json['shipToCustomer'] == null
        ? null
        : Customer.fromJson(json['shipToCustomer'] as Map<String, dynamic>)
    ..billToCustomer = json['billToCustomer'] == null
        ? null
        : Customer.fromJson(json['billToCustomer'] as Map<String, dynamic>)
    ..shipToContactorFirstname = json['shipToContactorFirstname'] as String
    ..shipToContactorLastname = json['shipToContactorLastname'] as String
    ..shipToAddressCountry = json['shipToAddressCountry'] as String
    ..shipToAddressState = json['shipToAddressState'] as String
    ..shipToAddressCounty = json['shipToAddressCounty'] as String
    ..shipToAddressCity = json['shipToAddressCity'] as String
    ..shipToAddressDistrict = json['shipToAddressDistrict'] as String
    ..shipToAddressLine1 = json['shipToAddressLine1'] as String
    ..shipToAddressLine2 = json['shipToAddressLine2'] as String
    ..shipToAddressPostcode = json['shipToAddressPostcode'] as String
    ..billToContactorFirstname = json['billToContactorFirstname'] as String
    ..billToContactorLastname = json['billToContactorLastname'] as String
    ..billToAddressCountry = json['billToAddressCountry'] as String
    ..billToAddressState = json['billToAddressState'] as String
    ..billToAddressCounty = json['billToAddressCounty'] as String
    ..billToAddressCity = json['billToAddressCity'] as String
    ..allowForManualPick = json['allowForManualPick'] == null ? false : json['allowForManualPick'] as bool
    ..billToAddressDistrict = json['billToAddressDistrict'] as String
    ..billToAddressLine1 = json['billToAddressLine1'] as String
    ..billToAddressLine2 = json['billToAddressLine2'] as String
    ..billToAddressPostcode = json['billToAddressPostcode'] as String
    ..carrier = json['carrier'] == null
        ? null
        : Carrier.fromJson(json['carrier'] as Map<String, dynamic>)
    ..carrierServiceLevel = json['carrierServiceLevel'] == null
        ? null
        : CarrierServiceLevel.fromJson(json['carrierServiceLevel'] as Map<String, dynamic>)
    ..orderLines = (json['orderLines'] as List)
        ?.map(
            (e) => e == null ? null : OrderLine.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..totalLineCount = json['totalLineCount'] as int
    ..totalItemCount = json['totalItemCount'] as int
    ..totalExpectedQuantity = json['totalExpectedQuantity'] as int
    ..totalOpenQuantity = json['totalOpenQuantity'] as int
    ..totalInprocessQuantity = json['totalInprocessQuantity'] as int
    ..totalPendingAllocationQuantity = json['totalPendingAllocationQuantity'] as int
    ..totalOpenPickQuantity = json['totalOpenPickQuantity'] as int
    ..totalPickedQuantity = json['totalPickedQuantity'] as int
    ..totalShippedQuantity = json['totalShippedQuantity'] as int;
}

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'shipToCustomer': instance.shipToCustomer,
  'billToCustomer': instance.billToCustomer,
  'shipToContactorFirstname': instance.shipToContactorFirstname,
  'shipToContactorLastname': instance.shipToContactorLastname,
  'shipToAddressCountry': instance.shipToAddressCountry,
  'shipToAddressState': instance.shipToAddressState,
  'shipToAddressCounty': instance.shipToAddressCounty,
  'shipToAddressCity': instance.shipToAddressCity,
  'shipToAddressDistrict': instance.shipToAddressDistrict,
  'shipToAddressLine1': instance.shipToAddressLine1,
  'shipToAddressLine2': instance.shipToAddressLine2,
  'shipToAddressPostcode': instance.shipToAddressPostcode,
  'billToContactorFirstname': instance.billToContactorFirstname,
  'billToContactorLastname': instance.billToContactorLastname,
  'billToAddressCountry': instance.billToAddressCountry,
  'billToAddressState': instance.billToAddressState,
  'billToAddressCounty': instance.billToAddressCounty,
  'billToAddressCity': instance.billToAddressCity,
  'billToAddressDistrict': instance.billToAddressDistrict,
  'billToAddressLine1': instance.billToAddressLine1,
  'billToAddressLine2': instance.billToAddressLine2,
  'billToAddressPostcode': instance.billToAddressPostcode,
  'carrier': instance.carrier,
  'allowForManualPick': instance.allowForManualPick,
  'carrierServiceLevel': instance.carrierServiceLevel,
  'orderLines': instance.orderLines,
  'totalLineCount': instance.totalLineCount,
  'totalItemCount': instance.totalItemCount,
  'totalExpectedQuantity': instance.totalExpectedQuantity,
  'totalOpenQuantity': instance.totalOpenQuantity,
  'totalInprocessQuantity': instance.totalInprocessQuantity,
  'totalPendingAllocationQuantity': instance.totalPendingAllocationQuantity,
  'totalOpenPickQuantity': instance.totalOpenPickQuantity,
  'totalPickedQuantity': instance.totalPickedQuantity,
  'totalShippedQuantity': instance.totalShippedQuantity,
};
