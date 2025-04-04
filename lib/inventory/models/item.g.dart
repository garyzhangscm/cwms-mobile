// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Item _$ItemFromJson(Map<String, dynamic> json) {
  return Item()
    ..id = json['id'] as int
    ..name = json['name'] as String
    ..description = json['description'] as String
    ..warehouseId = json['warehouseId'] as int
    ..clientId = json['clientId'] as int
    ..trackingColorFlag = json['trackingColorFlag'] == null ? false : json['trackingColorFlag'] as bool
    ..defaultColor = json['defaultColor'] == null ? "" : json['defaultColor'] as String
    ..trackingProductSizeFlag = json['trackingProductSizeFlag'] == null ? false : json['trackingProductSizeFlag'] as bool
    ..defaultProductSize = json['defaultProductSize'] == null ? "" : json['defaultProductSize'] as String
    ..trackingStyleFlag = json['trackingStyleFlag'] == null ? false : json['trackingStyleFlag'] as bool
    ..defaultStyle = json['defaultStyle'] == null ? "" : json['defaultStyle'] as String
    ..trackingInventoryAttribute1Flag = json['trackingInventoryAttribute1Flag'] == null ? false : json['trackingInventoryAttribute1Flag'] as bool
    ..defaultInventoryAttribute1 = json['defaultInventoryAttribute1'] == null ? "" : json['defaultInventoryAttribute1'] as String
    ..trackingInventoryAttribute2Flag = json['trackingInventoryAttribute2Flag'] == null ? false : json['trackingInventoryAttribute2Flag'] as bool
    ..defaultInventoryAttribute2 = json['defaultInventoryAttribute2'] == null ? "" : json['defaultInventoryAttribute2'] as String
    ..trackingInventoryAttribute3Flag = json['trackingInventoryAttribute3Flag'] == null ? false : json['trackingInventoryAttribute3Flag'] as bool
    ..defaultInventoryAttribute3 = json['defaultInventoryAttribute3'] == null ? "" : json['defaultInventoryAttribute3'] as String
    ..trackingInventoryAttribute4Flag = json['trackingInventoryAttribute4Flag'] == null ? false : json['trackingInventoryAttribute4Flag'] as bool
    ..defaultInventoryAttribute4 = json['defaultInventoryAttribute4'] == null ? "" : json['defaultInventoryAttribute4'] as String
    ..trackingInventoryAttribute5Flag = json['trackingInventoryAttribute5Flag'] == null ? false : json['trackingInventoryAttribute5Flag'] as bool
    ..defaultInventoryAttribute5 = json['defaultInventoryAttribute5'] == null ? "" : json['defaultInventoryAttribute5'] as String
    ..itemFamily = json['itemFamily'] == null
        ? null
        : ItemFamily.fromJson(json['itemFamily'] as Map<String, dynamic>)
    ..defaultItemPackageType = json['defaultItemPackageType'] == null
      ? null
      : ItemPackageType.fromJson(json['defaultItemPackageType'] as Map<String, dynamic>)
    ..itemPackageTypes = (json['itemPackageTypes'] as List)
        .map(
          (e) => ItemPackageType.fromJson(e as Map<String, dynamic>))
              .toList()
    ..kitItemFlag = json['kitItemFlag'] == null
        ? false : json['kitItemFlag'] as bool
    ..billOfMaterialId = json['billOfMaterialId'] == null
        ? null : json['billOfMaterialId'] as int
    ..billOfMaterial = json['billOfMaterial'] == null
        ? null
        : BillOfMaterial.fromJson(json['billOfMaterial'] as Map<String, dynamic>)
    ..kitInnerItems = (json['kitInnerItems'] as List)
        .map(
            (e) =>  Item.fromJson(e as Map<String, dynamic>))
        .toList();
    /**
    ..client = json['client'] == null
        ? null
        : Client.fromJson(json['client'] as Map<String, dynamic>)

        **/
}

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'warehouseId': instance.warehouseId,
      'clientId': instance.clientId,
      'client': instance.client,
    'defaultItemPackageType': instance.defaultItemPackageType,
    'itemFamily': instance.itemFamily,
      'itemPackageTypes': instance.itemPackageTypes,
  'trackingColorFlag': instance.trackingColorFlag,
  'defaultColor': instance.defaultColor,
  'trackingProductSizeFlag': instance.trackingProductSizeFlag,
  'defaultProductSize': instance.defaultProductSize,
  'trackingStyleFlag': instance.trackingStyleFlag,
  'defaultStyle': instance.defaultStyle,
  'trackingInventoryAttribute1Flag': instance.trackingInventoryAttribute1Flag,
  'defaultInventoryAttribute1': instance.defaultInventoryAttribute1,
  'trackingInventoryAttribute2Flag': instance.trackingInventoryAttribute2Flag,
  'defaultInventoryAttribute2': instance.defaultInventoryAttribute2,
  'trackingInventoryAttribute3Flag': instance.trackingInventoryAttribute3Flag,
  'defaultInventoryAttribute3': instance.defaultInventoryAttribute3,
  'trackingInventoryAttribute4Flag': instance.trackingInventoryAttribute4Flag,
  'defaultInventoryAttribute4': instance.defaultInventoryAttribute4,
  'trackingInventoryAttribute5Flag': instance.trackingInventoryAttribute5Flag,
  'defaultInventoryAttribute5': instance.defaultInventoryAttribute5,
  'kitItemFlag': instance.kitItemFlag,
  'billOfMaterialId': instance.billOfMaterialId,
  'kitInnerItems': instance.kitInnerItems,
  'billOfMaterial': instance.billOfMaterial,
};
