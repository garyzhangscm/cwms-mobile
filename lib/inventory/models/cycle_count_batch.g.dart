// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_count_batch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Menu _$MenuFromJson(Map<String, dynamic> json) {
  return Menu()
    ..name = json['name'] as String
    ..link = json['link'] as String
    ..text = json['text'] as String;
}

Map<String, dynamic> _$MenuToJson(Menu instance) => <String, dynamic>{
      'name': instance.name,
      'link': instance.link,
      'text': instance.text,
    };
