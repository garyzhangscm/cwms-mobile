// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carrier.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Carrier _$CarrierFromJson(Map<String, dynamic> json) {
  return Carrier()
    ..id = json['id'] as int
    ..name = json['name']
    ..description = json['description']
    ..contactorFirstname = json['contactorFirstname']
    ..contactorLastname = json['contactorLastname']
    ..addressCountry = json['addressCountry']
    ..addressState = json['addressState']
    ..addressCounty = json['addressCounty']
    ..addressCity = json['addressCity']
    ..addressDistrict = json['addressDistrict']
    ..addressLine1 = json['addressLine1']
    ..addressLine2 = json['addressLine2']  ;
}

Map<String, dynamic> _$CarrierToJson(Carrier instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'contactorFirstname': instance.contactorFirstname,
  'contactorLastname': instance.contactorLastname,
  'addressCountry': instance.addressCountry,
  'addressState': instance.addressState,
  'addressCounty': instance.addressCounty,
  'addressCity': instance.addressCity,
  'addressDistrict': instance.addressDistrict,
  'addressLine1': instance.addressLine1,
  'addressLine2': instance.addressLine2,
};
