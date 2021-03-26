// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderLine _$OrderLineFromJson(Map<String, dynamic> json) {
  return OrderLine()
    ..id = json['id'] as int
    ..number = json['number'] as String
    ..item = json['item'] == null
        ? null
        : Item.fromJson(json['item'] as Map<String, dynamic>)
    ..expectedQuantity = json['expectedQuantity'] as int
    ..openQuantity = json['openQuantity'] as int
    ..inprocessQuantity = json['inprocessQuantity'] as int
    ..shippedQuantity = json['shippedQuantity'] as int
    ..productionPlanInprocessQuantity = json['productionPlanInprocessQuantity'] as int
    ..productionPlanProducedQuantity = json['productionPlanProducedQuantity'] as int
    ..carrier = json['carrier'] == null
        ? null
        : Carrier.fromJson(json['carrier'] as Map<String, dynamic>)
    ..carrierServiceLevel = json['carrierServiceLevel'] == null
        ? null
        : CarrierServiceLevel.fromJson(json['carrierServiceLevel'] as Map<String, dynamic>)
    ..inventoryStatus = json['inventoryStatus'] == null
        ? null
        : InventoryStatus.fromJson(json['inventoryStatus'] as Map<String, dynamic>);
}

Map<String, dynamic> _$OrderLineToJson(OrderLine instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'item': instance.item,
  'expectedQuantity': instance.expectedQuantity,
  'openQuantity': instance.openQuantity,
  'inprocessQuantity': instance.inprocessQuantity,
  'shippedQuantity': instance.shippedQuantity,
  'productionPlanInprocessQuantity': instance.productionPlanInprocessQuantity,
  'productionPlanProducedQuantity': instance.productionPlanProducedQuantity,
  'carrier': instance.carrier,
  'carrierServiceLevel': instance.carrierServiceLevel,
  'inventoryStatus': instance.inventoryStatus,
};
