// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryStatus _$InventoryStatusFromJson(Map<String, dynamic> json) {
  return InventoryStatus()
    ..id = json['id'] as int
    ..name = json['name']
    ..description = json['description']
    ..availableStatusFlag = json['availableStatusFlag'] == null ? false : json['availableStatusFlag'] as bool
    ..reasonRequiredWhenReceiving = json['reasonRequiredWhenReceiving'] == null ? false : json['reasonRequiredWhenReceiving'] as bool
    ..reasonRequiredWhenProducing = json['reasonRequiredWhenProducing'] == null ? false : json['reasonRequiredWhenProducing'] as bool
    ..reasonRequiredWhenAdjusting = json['reasonRequiredWhenAdjusting'] == null ? false : json['reasonRequiredWhenAdjusting'] as bool
    ..reasonOptionalWhenReceiving = json['reasonOptionalWhenReceiving'] == null ? false : json['reasonOptionalWhenReceiving'] as bool
    ..reasonOptionalWhenProducing = json['reasonOptionalWhenProducing'] == null ? false : json['reasonOptionalWhenProducing'] as bool
    ..reasonOptionalWhenAdjusting = json['reasonOptionalWhenAdjusting'] == null ? false : json['reasonOptionalWhenAdjusting'] as bool
    ..warehouseId = json['warehouseId'];
}

Map<String, dynamic> _$InventoryStatusToJson(InventoryStatus instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'warehouseId': instance.warehouseId,
  'reasonRequiredWhenReceiving': instance.reasonRequiredWhenReceiving,
  'reasonRequiredWhenProducing': instance.reasonRequiredWhenProducing,
  'reasonRequiredWhenAdjusting': instance.reasonRequiredWhenAdjusting,
  'reasonOptionalWhenReceiving': instance.reasonOptionalWhenReceiving,
  'reasonOptionalWhenProducing': instance.reasonOptionalWhenProducing,
  'reasonOptionalWhenAdjusting': instance.reasonOptionalWhenAdjusting,
};
