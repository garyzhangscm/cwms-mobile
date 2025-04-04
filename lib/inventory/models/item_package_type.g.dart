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
    ..displayItemUnitOfMeasure = json['displayItemUnitOfMeasure'] == null
        ? null
        : ItemUnitOfMeasure.fromJson(json['displayItemUnitOfMeasure'] as Map<String, dynamic>)
    ..defaultInboundReceivingUOM = json['defaultInboundReceivingUOM'] == null
        ? null
        : ItemUnitOfMeasure.fromJson(json['defaultInboundReceivingUOM'] as Map<String, dynamic>)
    ..defaultWorkOrderReceivingUOM = json['defaultWorkOrderReceivingUOM'] == null
        ? null
        : ItemUnitOfMeasure.fromJson(json['defaultWorkOrderReceivingUOM'] as Map<String, dynamic>)
    ..trackingLpnUOM = json['trackingLpnUOM'] == null
        ? null
        : ItemUnitOfMeasure.fromJson(json['trackingLpnUOM'] as Map<String, dynamic>)
    ..itemUnitOfMeasures = (json['itemUnitOfMeasures'] as List)
        .map(
            (e) =>  ItemUnitOfMeasure.fromJson(e as Map<String, dynamic>))
        .toList()
    ..warehouseId = json['warehouseId'] as int
    ..defaultFlag = json['defaultFlag'] == null ? null : json['defaultFlag'] as bool;
}

Map<String, dynamic> _$ItemPackageTypeToJson(ItemPackageType instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'clientId': instance.clientId,
      'supplierId': instance.supplierId,
      'stockItemUnitOfMeasure': instance.stockItemUnitOfMeasure,
      'displayItemUnitOfMeasure': instance.displayItemUnitOfMeasure,
      'defaultInboundReceivingUOM': instance.defaultInboundReceivingUOM,
      'defaultWorkOrderReceivingUOM': instance.defaultWorkOrderReceivingUOM,
      'trackingLpnUOM': instance.trackingLpnUOM,
      'itemUnitOfMeasures': instance.itemUnitOfMeasures,
      'warehouse': instance.warehouse,
      'warehouseId': instance.warehouseId,
      'defaultFlag': instance.defaultFlag,
    };
