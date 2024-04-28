// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_configuration.dart';

InventoryConfiguration _$InventoryConfigurationFromJson(Map<String, dynamic> json) {
  return InventoryConfiguration()
    ..id = json['id'] as int
    ..companyId = json['companyId']  == null? null : json['companyId'] as int
    ..warehouseId = json['warehouseId']  == null? null : json['warehouseId'] as int
    ..lpnValidationRule = json['lpnValidationRule']   == null ? null : json['lpnValidationRule'] as String
    ..inventoryAttribute1DisplayName = json['inventoryAttribute1DisplayName']  == null ? null : json['inventoryAttribute1DisplayName'] as String
    ..inventoryAttribute1Enabled = json['inventoryAttribute1Enabled']  == null ? false : json['inventoryAttribute1Enabled'] as bool
    ..inventoryAttribute2DisplayName = json['inventoryAttribute2DisplayName']  == null ? null : json['inventoryAttribute2DisplayName'] as String
    ..inventoryAttribute2Enabled = json['inventoryAttribute2Enabled']  == null ? false : json['inventoryAttribute2Enabled'] as bool
    ..inventoryAttribute3DisplayName = json['inventoryAttribute3DisplayName']  == null ? null : json['inventoryAttribute3DisplayName'] as String
    ..inventoryAttribute3Enabled = json['inventoryAttribute3Enabled']  == null ? false : json['inventoryAttribute3Enabled'] as bool
    ..inventoryAttribute4DisplayName = json['inventoryAttribute4DisplayName']  == null ? null : json['inventoryAttribute4DisplayName'] as String
    ..inventoryAttribute4Enabled = json['inventoryAttribute4Enabled']  == null ? false : json['inventoryAttribute4Enabled'] as bool
    ..inventoryAttribute5DisplayName = json['inventoryAttribute5DisplayName']  == null ? null : json['inventoryAttribute5DisplayName'] as String
    ..inventoryAttribute5Enabled = json['inventoryAttribute5Enabled']  == null ? false : json['inventoryAttribute5Enabled'] as bool
    ;
}

Map<String, dynamic> _$InventoryConfigurationToJson(InventoryConfiguration instance) => <String, dynamic>{
      'id': instance.id,
      'companyId': instance.companyId,
      'warehouseId': instance.warehouseId,
      'lpnValidationRule': instance.lpnValidationRule,
      'inventoryAttribute1DisplayName': instance.inventoryAttribute1DisplayName,
      'inventoryAttribute1Enabled': instance.inventoryAttribute1Enabled,
  'inventoryAttribute2DisplayName': instance.inventoryAttribute2DisplayName,
  'inventoryAttribute2Enabled': instance.inventoryAttribute2Enabled,
  'inventoryAttribute3DisplayName': instance.inventoryAttribute3DisplayName,
  'inventoryAttribute3Enabled': instance.inventoryAttribute3Enabled,
  'inventoryAttribute4DisplayName': instance.inventoryAttribute4DisplayName,
  'inventoryAttribute4Enabled': instance.inventoryAttribute4Enabled,
  'inventoryAttribute5DisplayName': instance.inventoryAttribute5DisplayName,
  'inventoryAttribute5Enabled': instance.inventoryAttribute5Enabled,

};
