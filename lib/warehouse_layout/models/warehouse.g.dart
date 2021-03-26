// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warehouse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Warehouse _$WarehouseFromJson(Map<String, dynamic> json) {
  return Warehouse()
    ..id = json['id'] as int
    ..name = json['name'] as String
    ..size = double.parse(json['size'].toString())
    ..companyId = json['companyId'] as int;
}

Map<String, dynamic> _$WarehouseToJson(Warehouse instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'size': instance.size,
      'companyId': instance.companyId,
    };
