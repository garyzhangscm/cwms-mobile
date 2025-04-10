// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'warehouse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Warehouse _$WarehouseFromJson(Map<String, dynamic> json) {
  return Warehouse()
    ..id = json['id'] as int
    ..name = json['name']
    ..size = json['size'] == null ? 0 : double.parse(json['size'].toString())
    ..companyId = json['companyId'] ;
}

Map<String, dynamic> _$WarehouseToJson(Warehouse instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'size': instance.size,
      'companyId': instance.companyId,
    };
