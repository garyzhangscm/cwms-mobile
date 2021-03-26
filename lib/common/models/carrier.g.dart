// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'carrier.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Carrier _$CarrierFromJson(Map<String, dynamic> json) {
  return Carrier()
    ..id = json['id'] as int
    ..name = json['name'] as String
    ..description = json['description'] as String
    ..contactorFirstname = json['contactorFirstname'] as String
    ..contactorLastname = json['contactorLastname'] as String
    ..addressCountry = json['addressCountry'] as String
    ..addressState = json['addressState'] as String
    ..addressCounty = json['addressCounty'] as String
    ..addressCity = json['addressCity'] as String
    ..addressDistrict = json['addressDistrict'] as String
    ..addressLine1 = json['addressLine1'] as String
    ..addressLine2 = json['addressLine2'] as String;
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
