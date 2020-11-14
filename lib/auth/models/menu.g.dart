// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Menu _$MenuFromJson(Map<String, dynamic> json) {
  return Menu()
    ..name = json['name'] as String
    ..link = json['link'] as String
    ..icon = json['icon'] as String
    ..text = json['text'] as String;
}

Map<String, dynamic> _$MenuToJson(Menu instance) => <String, dynamic>{
      'name': instance.name,
      'link': instance.link,
      'icon': instance.icon,
      'text': instance.text,
    };
