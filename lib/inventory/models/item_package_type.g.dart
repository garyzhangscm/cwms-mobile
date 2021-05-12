// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_package_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemPackageType _$ItemPackageTypeFromJson(Map<String, dynamic> json) {
  return ItemPackageType()
    ..id = json['id'] as int
    ..name = json['name'] as String
    ..description = json['description'] as String
    ..clientId = json['clientId'] as int
    ..supplierId = json['supplierId'] as int
    ..stockItemUnitOfMeasure = json['stockItemUnitOfMeasure'] == null
        ? null
        : ItemUnitOfMeasure.fromJson(json['stockItemUnitOfMeasure'] as Map<String, dynamic>)
    ..itemUnitOfMeasures = (json['itemUnitOfMeasures'] as List)
        ?.map(
            (e) => e == null ? null : ItemUnitOfMeasure.fromJson(e as Map<String, dynamic>))
        ?.toList()
    ..warehouseId = json['warehouseId'] as int;
}

Map<String, dynamic> _$ItemPackageTypeToJson(ItemPackageType instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'clientId': instance.clientId,
      'supplierId': instance.supplierId,
      'stockItemUnitOfMeasure': instance.stockItemUnitOfMeasure,
      'itemUnitOfMeasures': instance.itemUnitOfMeasures,
      'warehouse': instance.warehouse,
      'warehouseId': instance.warehouseId,
    };
