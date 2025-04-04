// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pick_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PickList _$PickListFromJson(Map<String, dynamic> json) {
  return PickList()
    ..id = json['id'] as int
    ..number = json['number'] as String
    ..picks = (json['picks'] as List)
        .map(
            (e) => Pick.fromJson(e as Map<String, dynamic>))
        .toList();
}

Map<String, dynamic> _$PickListToJson(PickList instance) => <String, dynamic>{
  'id': instance.id,
  'number': instance.number,
  'picks': instance.picks,
};
