// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) {
  return Order()
    ..id = json['id'] as int
    ..number = json['number']
    ..shipToCustomer = json['shipToCustomer'] == null
        ? null
        : Customer.fromJson(json['shipToCustomer'] as Map<String, dynamic>)
    ..billToCustomer = json['billToCustomer'] == null
        ? null
        : Customer.fromJson(json['billToCustomer'] as Map<String, dynamic>)
    ..shipToContactorFirstname = json['shipToContactorFirstname']
    ..shipToContactorLastname = json['shipToContactorLastname']
    ..shipToAddressCountry = json['shipToAddressCountry']
    ..shipToAddressState = json['shipToAddressState']
    ..shipToAddressCounty = json['shipToAddressCounty']
    ..shipToAddressCity = json['shipToAddressCity']
    ..shipToAddressDistrict = json['shipToAddressDistrict']
    ..shipToAddressLine1 = json['shipToAddressLine1']
    ..shipToAddressLine2 = json['shipToAddressLine2']
    ..shipToAddressPostcode = json['shipToAddressPostcode']
    ..billToContactorFirstname = json['billToContactorFirstname']
    ..billToContactorLastname = json['billToContactorLastname']
    ..billToAddressCountry = json['billToAddressCountry']
    ..billToAddressState = json['billToAddressState']
    ..billToAddressCounty = json['billToAddressCounty']
    ..billToAddressCity = json['billToAddressCity']
    ..allowForManualPick = json['allowForManualPick'] == null ? false : json['allowForManualPick'] as bool
    ..billToAddressDistrict = json['billToAddressDistrict']
    ..billToAddressLine1 = json['billToAddressLine1']
    ..billToAddressLine2 = json['billToAddressLine2']
    ..billToAddressPostcode = json['billToAddressPostcode']
    ..carrier = json['carrier'] == null
        ? null
        : Carrier.fromJson(json['carrier'] as Map<String, dynamic>)
    ..carrierServiceLevel = json['carrierServiceLevel'] == null
        ? null
        : CarrierServiceLevel.fromJson(json['carrierServiceLevel'] as Map<String, dynamic>)
    ..orderLines = json['orderLines']  == null ?
        [] :
        (json['orderLines'] as List)
        .map(
            (e) => OrderLine.fromJson(e as Map<String, dynamic>))
        .toList()
    ..totalLineCount = json['totalLineCount']
    ..totalItemCount = json['totalItemCount']
    ..totalExpectedQuantity = json['totalExpectedQuantity']
    ..totalOpenQuantity = json['totalOpenQuantity']
    ..totalInprocessQuantity = json['totalInprocessQuantity']
    ..totalPendingAllocationQuantity = json['totalPendingAllocationQuantity']
    ..totalOpenPickQuantity = json['totalOpenPickQuantity']
    ..totalPickedQuantity = json['totalPickedQuantity']
    ..totalShippedQuantity = json['totalShippedQuantity'] ;
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
