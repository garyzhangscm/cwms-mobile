// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuGroup _$MenuGroupFromJson(Map<String, dynamic> json) {
  return MenuGroup()
    ..name = json['name']
    ..text = json['text']
    ..i18n = json['i18n']
    ..menuSubGroups = json['children'] == null ?
        [] :
        (json['children'] as List)
        .map((e) => MenuSubGroup.fromJson(e as Map<String, dynamic>))
        .toList();
}

Map<String, dynamic> _$MenuGroupToJson(MenuGroup instance) => <String, dynamic>{
      'name': instance.name,
      'text': instance.text,
      'i18n': instance.i18n,
      'menuSubGroups': instance.menuSubGroups,
    };
